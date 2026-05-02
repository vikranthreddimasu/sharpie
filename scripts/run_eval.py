#!/usr/bin/env python3
"""
Sharpie eval runner.

Mirrors Sharpie's actual code path exactly: the same `claude` flag set as
`ClaudeCodeBackend.swift`, the same fresh-temp-cwd hygiene as
`SubprocessRunner.swift`, the same default model as `BackendID.defaultModel`,
and the same clarify-question heuristic as `SharpenViewModel
.looksLikeClarifyingQuestion`. A test failing here is a test that would
fail in the actual app.

Usage:
    python3 scripts/run_eval.py [--model sonnet]
                                [--suite Tests/sharpie-eval-suite.json]
                                [--prompt prompts/sharpen.md]
                                [--out Tests/eval-report.md]
                                [--only T1.1,T4.4]
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SUITE = REPO_ROOT / "Tests" / "sharpie-eval-suite.json"
DEFAULT_PROMPT = REPO_ROOT / "prompts" / "sharpen.md"
DEFAULT_REPORT = REPO_ROOT / "Tests" / "eval-report.md"

# Imperative verbs sharpen.md says rewrites should start with. We detect
# more loosely than the prompt prescribes — anything starting with one of
# these (or a close synonym) counts as an imperative opening. Liberal —
# false negatives here would punish good rewrites for word choice, which
# is not what the eval is for.
IMPERATIVE_VERBS = {
    # Core actions
    "investigate", "fix", "implement", "refactor", "add", "remove",
    "audit", "profile", "debug", "explain", "review", "document", "test",
    "migrate", "benchmark", "harden", "rewrite", "build", "create",
    "write",
    # Discovery / analysis
    "identify", "diagnose", "trace", "find", "track", "isolate",
    "reproduce", "scan", "analyze", "examine", "inspect", "detect",
    "characterize", "instrument", "log", "measure", "compare",
    "locate", "spot", "discover", "surface", "study", "note",
    "annotate", "decompose", "walk", "look", "evaluate",
    # Restructure
    "extract", "consolidate", "standardize", "replace", "convert",
    "split", "merge", "deduplicate", "reorganize", "rename",
    "reconcile", "unify", "normalize", "flatten",
    # Continuation / next-step (used heavily for cryptic inputs)
    "pick", "continue", "resume", "proceed", "advance", "carry",
    "follow",
    # Verification
    "verify", "ensure", "confirm", "check", "validate", "assert",
    # General
    "make", "list", "summarize", "describe", "clarify", "outline",
    "design", "plan", "draft", "specify", "define", "prepare",
    "set", "configure", "set up", "wire", "wire up", "hook",
    "hook up", "mount", "register",
    # Removal / cleanup
    "drop", "delete", "kill", "strip", "clean", "prune", "clear",
    # Networking / state
    "fetch", "load", "store", "save", "persist", "restore", "import",
    "export", "publish", "ship",
    # Performance
    "optimize", "tune", "speed", "throttle", "cache",
    # Generic verbs that often legitimately open a sharp prompt
    "show", "display", "render", "output", "produce", "generate",
    "emit", "report",
    "apply", "use",
    "stop", "pause", "start", "initialize",
}


@dataclass
class TestCase:
    id: str
    tier: str
    input: str
    expect: str  # "rewrite" | "clarify" | "either"
    must_contain: list[str] = field(default_factory=list)
    must_contain_all: list[str] = field(default_factory=list)
    must_not_contain: list[str] = field(default_factory=list)
    must_contain_imperative: bool = False
    must_contain_imperative_or_question: bool = False
    max_chars: int | None = None


@dataclass
class TestResult:
    case: TestCase
    output: str
    stderr: str
    exit_code: int
    latency_s: float
    classification: str  # "rewrite" | "clarify" | "empty" | "error"
    failures: list[str] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not self.failures and self.classification != "error"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Run the Sharpie eval suite.")
    p.add_argument("--model", default="sonnet",
                   help="Model to pass via --model. Default mirrors Sharpie's "
                        "BackendID.defaultModel for Claude Code.")
    p.add_argument("--suite", default=str(DEFAULT_SUITE), type=Path)
    p.add_argument("--prompt", default=str(DEFAULT_PROMPT), type=Path)
    p.add_argument("--out", default=str(DEFAULT_REPORT), type=Path)
    p.add_argument("--only", default=None,
                   help="Comma-separated list of test IDs to run "
                        "(e.g. T1.1,T4.4). All others are skipped.")
    p.add_argument("--claude", default=None,
                   help="Path to the claude binary. Defaults to "
                        "`which claude`.")
    return p.parse_args()


def find_claude(explicit: str | None) -> str:
    if explicit:
        return explicit
    which = shutil.which("claude")
    if which:
        return which
    # Fall back to the install location BackendDetector.swift checks.
    home_local = Path.home() / ".local" / "bin" / "claude"
    if home_local.is_file() and os.access(home_local, os.X_OK):
        return str(home_local)
    print("error: `claude` not found on PATH or at ~/.local/bin/claude.",
          file=sys.stderr)
    sys.exit(2)


def load_suite(path: Path) -> list[TestCase]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    cases: list[TestCase] = []
    for entry in raw.get("tests", []):
        cases.append(TestCase(
            id=entry["id"],
            tier=entry["tier"],
            input=entry["input"],
            expect=entry["expect"],
            must_contain=entry.get("must_contain") or
                         ([entry["must_contain"]] if isinstance(entry.get("must_contain"), str) else []),
            must_contain_all=entry.get("must_contain_all", []),
            must_not_contain=entry.get("must_not_contain", []),
            must_contain_imperative=entry.get("must_contain_imperative", False),
            must_contain_imperative_or_question=entry.get(
                "must_contain_imperative_or_question", False),
            max_chars=entry.get("max_chars"),
        ))
    # Coerce single-string must_contain into a list cleanly.
    for c in cases:
        if isinstance(c.must_contain, str):
            c.must_contain = [c.must_contain]
    return cases


def looks_like_clarify(text: str) -> bool:
    """Identical to SharpenViewModel.looksLikeClarifyingQuestion in Swift.

    A clarify is a single short interrogative sentence — ends with `?`,
    no longer than 240 chars, with no interior period/exclamation/question
    that would suggest multiple sentences.
    """
    t = text.strip()
    if not t.endswith("?"):
        return False
    if len(t) > 240:
        return False
    body = t[:-1]
    return all(ch not in body for ch in ".!?")


def starts_with_imperative(text: str) -> bool:
    first = text.strip().split()
    if not first:
        return False
    first_word = first[0].rstrip(",.:;").lower()
    return first_word in IMPERATIVE_VERBS


def classify(text: str) -> str:
    t = text.strip()
    if not t:
        return "empty"
    if looks_like_clarify(t):
        return "clarify"
    return "rewrite"


def run_one(claude: str, system_prompt: str, model: str,
            test_input: str) -> tuple[str, str, int, float]:
    """Mirrors ClaudeCodeBackend.streamCompletion + SubprocessRunner.

    Args used (verified against Claude Code 2.1.126 + Sharpie source).
    Note: the app uses stream-json + --include-partial-messages so it can
    render tokens as they arrive. The eval doesn't need the streaming
    UX, so it falls back to plain text output for simpler parsing — but
    every other flag matches production. Crucially `--effort low` is
    here because it materially affects model behavior (skips interleaved
    thinking) and we want eval results to reflect production.
    """
    args = [
        claude,
        "-p",
        "--system-prompt", system_prompt,
        "--output-format", "text",
        "--effort", "low",
        "--no-session-persistence",
        "--disable-slash-commands",
        "--model", model,
        test_input,
    ]
    # Hermetic cwd — same as SubprocessRunner.swift. Prevents the user's
    # project CLAUDE.md / .claude/settings.json from leaking into eval runs.
    cwd = Path(tempfile.gettempdir()) / f"sharpie-eval-{uuid.uuid4()}"
    cwd.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    try:
        proc = subprocess.run(
            args,
            cwd=str(cwd),
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=120,
        )
        elapsed = time.monotonic() - started
        return (proc.stdout, proc.stderr, proc.returncode, elapsed)
    except subprocess.TimeoutExpired as e:
        elapsed = time.monotonic() - started
        return ((e.stdout or "") if isinstance(e.stdout, str) else "",
                (e.stderr or "") if isinstance(e.stderr, str) else "",
                124, elapsed)
    finally:
        try:
            shutil.rmtree(cwd, ignore_errors=True)
        except OSError:
            pass


def evaluate(case: TestCase, output: str) -> tuple[str, list[str]]:
    failures: list[str] = []
    classification = classify(output)

    # Sharpie is rewrite-only as of v3 of sharpen.md. Any output that's a
    # bare clarifying question is a contract violation regardless of the
    # test's `expect` field — the system prompt forbids questions.
    if classification == "empty":
        failures.append("output was empty")
    elif classification == "clarify":
        failures.append(
            "output is a clarifying question — sharpen.md forbids questions, "
            "every output must be a rewrite"
        )
    elif case.expect == "rewrite" and classification != "rewrite":
        failures.append(f"expected rewrite, got {classification}")

    # Substring assertions are case-insensitive on the input text — the
    # rewrite usually mirrors the developer's exact noun, but small case
    # differences shouldn't trip the gate.
    lo = output.lower()
    for needle in case.must_contain:
        if needle.lower() not in lo:
            failures.append(f"missing required term: {needle!r}")
    for needle in case.must_contain_all:
        if needle.lower() not in lo:
            failures.append(f"missing required term: {needle!r}")
    for needle in case.must_not_contain:
        if needle.lower() in lo:
            failures.append(f"contains forbidden term: {needle!r}")

    if case.must_contain_imperative and classification == "rewrite":
        if not starts_with_imperative(output):
            failures.append("rewrite did not start with an imperative verb")

    if case.must_contain_imperative_or_question:
        if classification not in ("rewrite", "clarify"):
            failures.append("output is neither imperative rewrite nor question")
        elif classification == "rewrite" and not starts_with_imperative(output):
            failures.append("rewrite did not start with an imperative verb")

    if case.max_chars is not None and len(output.strip()) > case.max_chars:
        failures.append(
            f"output too long: {len(output.strip())} chars > {case.max_chars}"
        )

    return classification, failures


def write_report(results: list[TestResult], path: Path, *, model: str,
                 prompt_path: Path) -> None:
    by_tier: dict[str, list[TestResult]] = {}
    for r in results:
        by_tier.setdefault(r.case.tier, []).append(r)

    total = len(results)
    passed = sum(1 for r in results if r.passed)
    failed = total - passed
    avg_latency = sum(r.latency_s for r in results) / total if total else 0.0

    lines: list[str] = []
    lines.append("# Sharpie eval report")
    lines.append("")
    lines.append(f"- Model: `{model}` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)")
    lines.append(f"- System prompt: `{prompt_path.relative_to(REPO_ROOT)}` (mtime {time.strftime('%Y-%m-%d %H:%M', time.localtime(prompt_path.stat().st_mtime))})")
    lines.append(f"- Tests: {total}  ·  passed: {passed}  ·  failed: {failed}")
    lines.append(f"- Average latency: {avg_latency:.1f}s")
    lines.append("")
    lines.append("Pass = expected behavior matched (rewrite vs clarify) AND all assertions held.")
    lines.append("")

    # Tier summary
    lines.append("## Tier summary")
    lines.append("")
    lines.append("| Tier | Pass | Fail |")
    lines.append("|---|---:|---:|")
    for tier, group in by_tier.items():
        p = sum(1 for r in group if r.passed)
        f = len(group) - p
        lines.append(f"| {tier} | {p} | {f} |")
    lines.append("")

    # Failures up top — the actionable section
    failures = [r for r in results if not r.passed]
    if failures:
        lines.append("## Failures (the things that need fixing)")
        lines.append("")
        for r in failures:
            lines.append(f"### {r.case.id} — {r.case.tier}")
            lines.append("")
            lines.append(f"**Input:**")
            lines.append("```")
            lines.append(r.case.input)
            lines.append("```")
            lines.append("")
            lines.append(f"**Output (`{r.classification}`, {r.latency_s:.1f}s):**")
            lines.append("```")
            lines.append(r.output.strip() or "(empty)")
            lines.append("```")
            lines.append("")
            lines.append(f"**Expected:** `{r.case.expect}`  ")
            lines.append(f"**Failures:**")
            for f in r.failures:
                lines.append(f"- {f}")
            if r.stderr.strip():
                lines.append("")
                lines.append("<details><summary>stderr</summary>")
                lines.append("")
                lines.append("```")
                lines.append(r.stderr.strip()[:2000])
                lines.append("```")
                lines.append("</details>")
            lines.append("")

    # All results (collapsible)
    lines.append("## All results")
    lines.append("")
    for tier, group in by_tier.items():
        lines.append(f"### {tier}")
        lines.append("")
        for r in group:
            mark = "✅" if r.passed else "❌"
            lines.append(f"#### {mark} {r.case.id} — `expect: {r.case.expect}` · {r.latency_s:.1f}s")
            lines.append("")
            lines.append(f"**Input:** `{r.case.input.replace(chr(10), ' / ')}`")
            lines.append("")
            lines.append(f"**Output (`{r.classification}`):**")
            lines.append("")
            lines.append("```")
            lines.append(r.output.strip() or "(empty)")
            lines.append("```")
            if r.failures:
                lines.append("")
                lines.append("Failures:")
                for f in r.failures:
                    lines.append(f"- {f}")
            lines.append("")

    path.write_text("\n".join(lines), encoding="utf-8")
    try:
        rel = path.relative_to(REPO_ROOT)
    except ValueError:
        rel = path
    print(f"\nReport written to {rel}", file=sys.stderr)


def main() -> int:
    args = parse_args()
    cases = load_suite(args.suite)
    if args.only:
        wanted = {x.strip() for x in args.only.split(",") if x.strip()}
        cases = [c for c in cases if c.id in wanted]
        if not cases:
            print(f"error: --only filter matched nothing", file=sys.stderr)
            return 2

    claude = find_claude(args.claude)
    system_prompt = args.prompt.read_text(encoding="utf-8")

    print(f"Running {len(cases)} tests with model={args.model}", file=sys.stderr)
    print(f"  prompt: {args.prompt.relative_to(REPO_ROOT)}", file=sys.stderr)
    print(f"  claude: {claude}", file=sys.stderr)
    print("", file=sys.stderr)

    results: list[TestResult] = []
    for i, case in enumerate(cases, 1):
        print(f"[{i:>2}/{len(cases)}] {case.id} ({case.tier})... ",
              end="", flush=True, file=sys.stderr)
        stdout, stderr, code, elapsed = run_one(
            claude, system_prompt, args.model, case.input
        )
        if code != 0:
            classification = "error"
            failures = [f"claude exited {code}"]
        else:
            classification, failures = evaluate(case, stdout)
        results.append(TestResult(
            case=case,
            output=stdout,
            stderr=stderr,
            exit_code=code,
            latency_s=elapsed,
            classification=classification,
            failures=failures,
        ))
        mark = "✓" if results[-1].passed else "✗"
        print(f"{mark}  {elapsed:>5.1f}s  ({classification})", file=sys.stderr)

    write_report(results, args.out, model=args.model, prompt_path=args.prompt)
    passed = sum(1 for r in results if r.passed)
    print(f"\n{passed}/{len(results)} passed", file=sys.stderr)
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
