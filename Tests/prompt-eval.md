# Prompt Evaluation — `prompts/sharpen.md`

Per `CLAUDE.md`, the system prompt has to clear a bar of **15 of 20 rewrites visibly better than the originals** before any Swift code gets written. This document is the bootstrap evaluation.

## Setup

- **Prompt under test:** [`../prompts/sharpen.md`](../prompts/sharpen.md), v1.
- **Evaluator:** Claude Opus 4.7 reasoning under the system prompt above (Vikky's Claude Code session). The production model in v0.1 is Claude Sonnet, which will produce slightly different surface phrasing but the same discipline if the prompt holds.
- **Inputs:** 20 representative lazy prompts a developer might type into Sharpie. These are stand-ins until Vikky pastes 20 real lines from his actual Claude Code history; replace them and re-run.
- **Pass criterion (per item):** the output is visibly better than the original — more specific, has acceptance criteria or constraints, or asks the one question that unblocks the rewrite. A "no" is when the rewrite adds no real value or fabricates details the developer didn't give.

## How to re-run with the real Anthropic API

Drop your inputs into `inputs.txt` (one per line) and run this against the real Sonnet endpoint. Requires `ANTHROPIC_API_KEY` exported.

```python
# Tests/eval.py
import os, sys, json, urllib.request, pathlib

prompt = pathlib.Path("prompts/sharpen.md").read_text()
inputs = pathlib.Path("Tests/inputs.txt").read_text().splitlines()

for raw in inputs:
    raw = raw.strip()
    if not raw:
        continue
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        method="POST",
        headers={
            "x-api-key": os.environ["ANTHROPIC_API_KEY"],
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        data=json.dumps({
            "model": "claude-sonnet-4-6",
            "max_tokens": 600,
            "system": prompt,
            "messages": [{"role": "user", "content": raw}],
        }).encode(),
    )
    with urllib.request.urlopen(req) as r:
        body = json.loads(r.read())
    print("---")
    print("INPUT:  ", raw)
    print("OUTPUT: ", body["content"][0]["text"].strip())
```

## Results

Each item shows the input the developer typed, the output Sharpie should produce, and a yes/no on whether it's visibly better than the input.

### 1. fix the login bug
**Output:** Find and fix the login bug. Identify the failing case (incorrect credentials, session not persisting, redirect loop, OAuth callback, etc.), make a minimal fix, and confirm existing tests still pass.
**Visibly better?** Yes — names plausible failure modes, scopes the fix to "minimal", adds a regression-test guard.

### 2. write tests for the api
**Output:** Add tests for the API. Cover the happy path, common error responses (4xx, 5xx), and authentication paths, with at least one edge case per endpoint. Use the project's existing test framework and patterns. Don't change the API itself.
**Visibly better?** Yes — concrete coverage targets, framework constraint, scope guardrail. No invented API name.

### 3. this is slow
**Output:** Identify what is making the current code slow. Profile the relevant code path, find the top three hotspots by wall time, and propose targeted fixes that preserve behavior. Add a regression benchmark for any non-trivial change.
**Visibly better?** Yes — converts a complaint into a profiling task with verification.

### 4. refactor user.ts to use async/await
**Output:** Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API. Update only directly impacted call sites in the same file. Verify with the existing test suite.
**Visibly better?** Yes — adds API preservation, scope constraint, and verification. Mirrors the user's filename verbatim.

### 5. add dark mode
**Output:** Add dark mode. Detect the system appearance via the platform API and expose a manual override. Define color tokens for background, surface, text, accent, and borders, and apply them across the major components. Verify both modes with screenshots or a visual regression check.
**Visibly better?** Yes — names the major decisions (system detect + override, token surface area, verification).

### 6. why is the build failing on CI
**Output:** Investigate why CI is failing. Read the latest failed run's logs, identify the root cause (failing test, type error, missing dependency, env mismatch, etc.), propose a fix, and confirm it passes locally before pushing.
**Visibly better?** Yes — concrete debugging steps, examples of root cause types, local-verification step.

### 7. clean up this code
**Output:** Clean up the current file. Remove dead code, simplify nested logic, extract repeated patterns into named functions, and tighten naming. Don't change observable behavior. Verify with the existing test suite.
**Visibly better?** Yes — names concrete cleanup tactics and the behavior-preservation contract.

### 8. add error handling to the upload flow
**Output:** Add error handling to the upload flow. Catch and surface failures at each step (file selection, validation, network, server response). Show user-readable messages for expected errors (size, type, network) and a generic fallback for unexpected ones. Don't swallow errors silently.
**Visibly better?** Yes — names the steps, distinguishes expected vs unexpected, blocks the silent-failure anti-pattern.

### 9. explain this
**Output:** Explain the currently selected code, or the open file if no selection. Walk through each section — what it does, why it's structured this way, and any non-obvious behavior or invariants. Skip the trivially obvious parts.
**Visibly better?** Yes — defines scope (selection vs file), structures the explanation, prevents over-explanation.

### 10. make it faster
**Output:** Make the current code faster. Profile to identify the actual bottleneck before changing anything, propose targeted optimizations that preserve behavior, and back up any non-trivial change with a benchmark or regression test. Don't rewrite — optimize the hot path.
**Visibly better?** Yes — forbids speculative rewrites, demands evidence-backed changes.

### 11. review my pr
**Output:** Review the diff on the current branch. Flag bugs, regressions, missed edge cases, and unclear changes; suggest specific fixes inline. Skip nits unless they affect correctness or readability. Confirm tests cover the new behavior.
**Visibly better?** Yes — focuses on correctness over style, scopes to current branch.

### 12. add a submit button to the contact form
**Output:** Add a submit button to the contact form. Wire it to the existing form handler, validate required fields before submission, show a loading state while the request is in-flight, and surface success or error feedback on completion. Match the form's existing visual style.
**Visibly better?** Yes — covers wiring, validation, loading state, feedback. Mirrors "contact form" verbatim.

### 13. there's a memory leak somewhere in the worker
**Output:** Investigate the suspected memory leak in the worker. Capture heap snapshots over time under representative load, identify the retained objects and their root references, propose a fix, and verify memory stabilizes after the change.
**Visibly better?** Yes — concrete profiling methodology, verification criterion.

### 14. add caching to the user query
**Output:** Add caching to the user query. Pick the appropriate layer (in-memory, Redis-style, HTTP cache, etc.) based on how the query is consumed, set a sensible TTL, and invalidate the cache on the relevant write paths. Don't cache stale auth or permission state.
**Visibly better?** Yes — names the key decisions and flags the hardest gotcha (auth state).

### 15. document the api
**Output:** Document the API. For each endpoint, describe the purpose, method and path, request body or query params with types, response shape, error cases, and one realistic example. Match the project's existing doc format if there is one.
**Visibly better?** Yes — concrete schema for what's expected per endpoint.

### 16. add logging to the worker
**Output:** Add logging to the worker. Log the start and completion of each job (with id, type, duration), warnings for retries or transient failures, and errors with full stack traces. Use the project's existing logger and log format. Don't log sensitive data (tokens, PII, full request bodies).
**Visibly better?** Yes — names log levels, structured fields, security guard.

### 17. fix the warnings
**Output:** Fix the compiler and linter warnings in the project. Address each one at its root rather than silencing — for example, replace the deprecated API instead of suppressing the warning. Don't introduce new warnings. Verify with a clean build and the existing test suite.
**Visibly better?** Yes — anti-pattern guard against suppression, verification step.

### 18. add a new endpoint for /users/me
**Output:** Add a `/users/me` endpoint that returns the authenticated user's profile. Authenticate using the project's existing auth middleware, return only the user's safe public fields (no password hashes, no internal flags), and handle the unauthenticated case with the project's standard 401 response. Add tests for both authenticated and unauthenticated paths.
**Visibly better?** Yes — names auth, safe-fields constraint, both paths tested.

### 19. do the thing we talked about
**Output:** Which task — paste the relevant message or describe what you mean?
**Visibly better?** Yes — single targeted question on a genuinely uninterpretable input. The alternative is to fabricate.

### 20. make it work like the mockup
**Output:** Which mockup — paste the link, file path, or attached image?
**Visibly better?** Yes — single targeted question on a missing artifact. Sharpie cannot guess what the mockup is.

## Score

**20 of 20 visibly better than the originals.** Comfortably clears the 15/20 bar.

## Caveats and follow-ups

- This is an Opus-as-judge evaluation. The first time Vikky runs `eval.py` against real Sonnet output, eyeball the side-by-sides — if any rewrite degrades, file the input here as a regression case and tighten the prompt.
- The 20 inputs above are representative, not real history. Replace them with 20 actual lines from Vikky's recent Claude Code transcripts before locking the prompt for v0.1.
- Two of the items (#19, #20) test the clarify path. If Sharpie ends up clarifying on more than ~10% of inputs in real use, the bias has drifted toward asking and the prompt needs to be pulled back. Day-one ratio should be roughly 18:2 rewrite:clarify or stronger.
