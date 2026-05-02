# Sharpie

A macOS menu-bar app that turns lazy prompts into the prompt you should have written — using the AI tools you already have authenticated on your machine.

This document is the source of truth for Claude Code building Sharpie. Read it fully before touching anything. The autonomy contract at the bottom defines what to decide on your own, what to ask about, and what's off-limits.

> **This is the v3 PRD.** Supersedes v1 (BYOA + API keys + Ollama) and v2 (which still allowed clarifying questions). v3 is **rewrite-only** — Sharpie produces exactly one rewritten prompt per invocation and never asks questions back. The clarify path was removed because it broke the hotkey-driven flow: users want one keystroke from input to clipboard, not a back-and-forth. The current sharpen.md lives at `Sources/Sharpie/Resources/sharpen.md` (the canonical real file); `prompts/sharpen.md` is a symlink to it for repo-root visibility.

---

## The story

You're in Claude Code, ChatGPT, or Cursor. You start typing "fix the login bug" and you already know the model is going to ask three follow-up questions or hallucinate context that doesn't exist. You have two choices: stop, think, write a real prompt — or send the lazy one and waste a turn.

Sharpie is the third option. Hit a hotkey. Type your lazy input. Hit Enter. Sharpie rewrites it into a sharper prompt — always, never a question back — and lands the result on your clipboard. You paste it back into whatever tool you were using. Total time: under 10 seconds.

The product is for developers and ML engineers who already use Claude Code, ChatGPT, Cursor, Codex, and Gemini multiple times a day. Defaults are tuned for technical work.

---

## The reframe (why v2 exists)

The original PRD asked the user to paste an Anthropic or OpenRouter API key into the app on first run. That's a five-step funnel before the user has felt any value. Most installs die there.

The v2 reframe: **Sharpie shells out to AI CLIs the user already has installed and authenticated.** If you have Claude Code working in your terminal, Sharpie uses Claude Code. If you have Gemini CLI installed, it uses that. No key paste. No keychain. No first-run wall. The user already pays for their AI tool — Sharpie just borrows that authentication.

Concretely:

| Backend | Detection | Invocation | Auth source |
|---|---|---|---|
| Claude Code | `claude` on `$PATH` | `claude -p --system-prompt "<sys>" --output-format text --no-session-persistence --disable-slash-commands "<user>"` | User's existing Claude Pro/Max OAuth (or `ANTHROPIC_API_KEY` if set in their shell) |
| Codex CLI | `codex` on `$PATH` | `codex exec --skip-git-repo-check "<combined sys+user>"` (best-effort; flag syntax verified at runtime) | User's existing ChatGPT login |
| Gemini CLI | `gemini` on `$PATH` | `gemini -p "<combined sys+user>" -o text` | User's existing Google AI Studio / Gemini Pro auth |

Sharpie itself makes **zero outbound network calls**. All HTTP traffic happens inside the user's already-trusted CLI tool, through their already-authenticated session.

---

## The experience

**First run.** Download the app, drag to Applications, launch. Sharpie scans `$PATH` for `claude`, `codex`, `gemini`. If at least one is found, it picks the first available (preference order: Claude Code → Codex → Gemini) and you're done — the app lives in the menu bar from now on. The hotkey is `⌘/` by default.

If none of those CLIs are installed or authenticated, Sharpie shows a one-screen onboarding pointing the user at install instructions for each. Sharpie does **not** offer to set up API keys directly.

**The core loop.** Hit the hotkey from anywhere. A small window appears, focused, cursor in the input. Type or paste a lazy prompt. Hit Enter.

**The rewrite path.** Sharpie sends `<system prompt>` + `<your input>` to the active backend's CLI as a subprocess. When the response comes back, it lands in the output area and is auto-copied to clipboard. Hit Enter again to dismiss. The sharpened prompt is on your clipboard, ready to paste.

**The clarify path.** If the input is genuinely ambiguous, the system prompt instructs the backend to return a single short interrogative sentence (≤240 chars, no interior periods/exclamations). Sharpie detects that shape and shows it inline above the input. The user answers in one line. Sharpie sends a second invocation with the original + the question + the answer. Result lands on clipboard.

**The escape hatch.** `⌘Z` reverts to the original input — re-edit, re-run. `Esc` dismisses the window entirely. Original is never lost.

**The failure case.** If the subprocess exits non-zero, or stdout is empty, or auth has expired, Sharpie surfaces a specific error: "Claude Code returned an error. Run `claude` once in your terminal to re-auth." The original input stays in the field. No spinner-of-doom.

---

## What we're building (v1 scope)

- macOS menu-bar app, Swift + SwiftUI, macOS 14+
- Global hotkey (default `⌘/`), opens centered borderless window
- Single text input on top, output area below, status line at bottom
- **One mode, one system prompt** — `prompts/sharpen.md`, loaded at startup, copied into the bundle
- **AIToolBackend protocol** with three subprocess conformers: `ClaudeCodeBackend`, `CodexBackend`, `GeminiBackend`
- **BackendDetector** that scans `$PATH` at startup and picks the first available
- **Settings**: backend picker (only shows detected CLIs), hotkey recorder, history toggle, launch-at-login toggle
- **Clarification budget = 1**, enforced by the system prompt
- Auto-copy on completion with a visible "Copied" toast
- History off by default (changed from v1 PRD's default-on — fewer privacy surface in v1)
- `Esc` dismiss, `⌘Z` revert, `↩` submit, `⇧↩` newline

---

## What we're NOT building (deferred)

These were in the v1 PRD or my systems-thinking restructure. Each one has its place in some future version. Not now.

- ❌ Direct API integration (Anthropic SDK, OpenRouter, Ollama) — replaced by subprocess backends
- ❌ API key management, Keychain code
- ❌ Hosted free tier
- ❌ Open-source contribution flow / leaderboard / governance
- ❌ Eval corpus and CI eval-runner
- ❌ Browser extension
- ❌ Repair mode (post-hoc fixing of bad answers)
- ❌ Ambient mode (invisible interception)
- ❌ Per-destination prompt optimization (engine output the same regardless of backend)
- ❌ Streaming output — backends use `--output-format text`, full response arrives at once. Spinner during the ~2–3s subprocess overhead is acceptable.
- ❌ Linux / Windows / mobile
- ❌ Homebrew tap, signed binary — ship as a `.app` bundle from the build script; signing/notarization is a v1.x packaging task
- ❌ Telemetry, analytics, update checker, crash reporter
- ❌ Accounts, signup, cloud sync
- ❌ Mode picker, second mode, settings beyond what's listed above

---

## Architecture

```
Sharpie/
  prompts/
    sharpen.md                          # the one system prompt — most important file in the repo
  Sources/Sharpie/
    SharpieApp.swift                    # SwiftUI App entry
    AppDelegate.swift                   # menu bar item + hotkey lifecycle
    AppPreferences.swift                # UserDefaults wrapper
    KeyCombo.swift                      # hotkey serialization
    Errors.swift                        # SharpieError cases (subprocess failures, no CLI found, etc.)
    WindowController.swift              # the floating prompt window
    Backend/
      AIToolBackend.swift               # protocol: streamCompletion(systemPrompt:userInput:) -> AsyncThrowingStream<String, Error>
      BackendID.swift                   # enum: claudeCode | codex | gemini
      BackendDetector.swift             # scans $PATH; returns available backends
      SubprocessRunner.swift            # shared Process + Pipe helper
      ClaudeCodeBackend.swift
      CodexBackend.swift
      GeminiBackend.swift
    Services/
      ClipboardService.swift
      HotkeyService.swift
      LaunchAtLoginService.swift
      SystemPromptLoader.swift          # loads prompts/sharpen.md from bundle
      HistoryStore.swift
    State/
      SharpenViewModel.swift            # the core loop, talks only to AIToolBackend
    Views/
      SharpenView.swift                 # the prompt window
      SettingsView.swift                # backend picker + hotkey + history toggle
      HistoryView.swift
      HotkeyRecorder.swift
      MarkdownText.swift
      ToastView.swift
      VisualEffectView.swift
      SharpieTextView.swift
    Resources/
      sharpen.md -> ../../../prompts/sharpen.md
```

Files removed in v2: `Providers/AnthropicProvider.swift`, `OpenRouterProvider.swift`, `OllamaProvider.swift`, `OllamaCatalog.swift`, `ProviderFactory.swift`, `Services/KeychainService.swift`, `OllamaDaemonStarter.swift`, `OllamaInstallation.swift`, `OllamaModels.swift`, `OllamaPullService.swift`, `OpenRouterModels.swift`, `Views/ModelPicker.swift`, `OllamaCatalogView.swift`.

---

## Backend invocation specifics

All three backends conform to the same protocol:

```swift
protocol AIToolBackend: Sendable {
    var id: BackendID { get }
    var displayName: String { get }
    func streamCompletion(systemPrompt: String, userInput: String) -> AsyncThrowingStream<String, Error>
}
```

In v1, "stream" emits a single chunk with the full response (full text comes back at once from `--output-format text`). The protocol shape is preserved so we can add real streaming via `stream-json` later without touching the ViewModel.

### Claude Code

```bash
claude -p \
  --system-prompt "<sharpen.md>" \
  --output-format text \
  --no-session-persistence \
  --disable-slash-commands \
  "<user input>"
```

- Run with `cwd = NSTemporaryDirectory()/sharpie-<uuid>` (created empty per invocation, deleted after) so Claude Code doesn't auto-discover the user's project `CLAUDE.md` or `.claude/settings.json`.
- `--no-session-persistence` keeps Sharpie invocations out of the user's `~/.claude` session list.
- `--disable-slash-commands` skips skill loading for speed.
- Auth: uses whatever `claude auth` is currently logged in as. We do nothing.

### Gemini CLI

```bash
gemini -p "<sharpen.md>\n\n---\n\nUser input:\n<user input>" -o text
```

- Gemini has no separate system-prompt flag, so we concatenate.
- Same `cwd` discipline as Claude.
- Auth: whatever `gemini auth` (or Google AI Studio) is configured.

### Codex CLI

```bash
codex exec --skip-git-repo-check "<sharpen.md>\n\n---\n\nUser input:\n<user input>"
```

- Best-effort invocation — Codex isn't installed on the dev machine. Flag syntax may need adjustment after first run on a machine that has it. Document any corrections in the file's header comment.
- The detector skips Codex if `codex` isn't on `$PATH`, so users without it never see this.

---

## How we'll know it worked

- Vikky uses Sharpie daily for two weeks without uninstalling
- Hotkey-to-clipboard latency under 4 seconds end-to-end (subprocess overhead ~2s + LLM time)
- Three friends who already have Claude Code installed try it; at least one keeps using it for a week unprompted
- First-run friction is zero — drag to Applications, hit hotkey, type, get sharpened prompt

If Vikky stops using it, the product is wrong. If the rewrite quality doesn't justify the round-trip, the system prompt needs work, not the engineering.

---

## Lessons from past regressions (don't relearn these)

These are bugs that bit hard once. The fixes are in the codebase; this section documents the *reason* so they don't sneak back.

- **The system prompt resource must be a real file in `Sources/Sharpie/Resources/`, not a symlink to `prompts/`.** SwiftPM's `.copy()` preserves symlinks into the resource bundle, where the relative path no longer resolves — `Bundle.module.url(forResource:)` returns nil and the app silently falls back to `SystemPromptLoader.builtinFallback`. With a stale fallback, weaker models (Haiku) ignore the rewrite-only contract and ask clarifying questions. The canonical sharpen.md lives at `Sources/Sharpie/Resources/sharpen.md`; `prompts/sharpen.md` is a symlink for visibility.
- **The `builtinFallback` must mirror the canonical contract.** It's the silent failure mode if the bundle is broken. If the fallback says "ask one clarifying question" but the canonical says "never ask," you have a behavior cliff that varies by install.
- **System prompts must lead with the role, not the policy.** The original prompt opened with "you are a prompt engineer between the developer and the AI doing the work" — Haiku read this as context, not a role assertion, and produced direct task responses. Lead with `## Your role` + a Wrong/Right contrast pair. Weaker models need the role hammered in; stronger models tolerate softer framing.
- **Subprocess invocations need a timeout.** A hung `claude` process freezes the prompt window. 60s default lives in `SubprocessRunner.defaultTimeoutSeconds`, surfaced as `SharpieError.backendTimedOut`.
- **`SetupView` must share the parent's `BackendDetector` instance**, not create a private one. A local detector finds new CLIs but doesn't update `viewModel.status`, leaving the user stuck on the setup screen even though their install worked.

---

## Notes for Claude Code (the dev, not the backend)

- Stack: Swift 6.0+, SwiftUI, macOS 14+. SwiftPM executable target — no Xcode project file in the repo.
- Subprocess: use `Foundation.Process` with `Pipe` for stdin/stdout/stderr. Set `cwd` to a fresh temp dir per invocation. Read stdout to completion; surface stderr in error messages.
- Hotkey: existing implementation uses Carbon `RegisterEventHotKey` (see `HotkeyService.swift`). Don't change it.
- Window: borderless, rounded, draggable by the title area, `Esc` dismissible, centered on active screen on hotkey activation. Existing implementation works.
- The system prompt (`prompts/sharpen.md`) is the most important file in the repo. Treat it like source code: review, version, test against real lazy inputs.
- No analytics, no crash reporter, no update checker. Updates ship via re-downloading the app bundle until v1.x packaging.

---

## Autonomy contract for Claude Code

Vikky is handing this off. He does not want to be pinged for every micro-decision.

**Decide on your own. Do not ask.**
- All implementation choices: file structure, class names, async/await vs Combine, SwiftUI components, error message wording, animations.
- The exact wording of UI labels, error messages, the empty state, the "Copied" toast.
- How to structure tests, what to test, how much to test.
- The visual design of the window within the constraints already specified. Pick reasonable spacing and typography. No hex codes to ask about.
- Git commit messages, branch names, PR descriptions.

**Decide and document in the PR.** Don't ask first.
- Any tradeoff between two reasonable approaches — pick one, write why in the PR body.
- Anything covered by "lean toward X" in this document — just do X.

**Stop and ask Vikky only for these.**
- Decisions that contradict something explicit in this document.
- Anything that costs money (signing certificate, paid services).
- Publishing or pushing irreversibly to the outside world before v1.0 — the first HN post, the first tweet, the first Homebrew tap. Launch decisions, not engineering ones.

**Never do these without Vikky's explicit go-ahead, even if asked.**
- Add telemetry, analytics, or any phone-home behavior.
- Add direct API integrations (Anthropic SDK, OpenAI SDK, OpenRouter, Ollama). v2 is subprocess-only.
- Add Keychain or any local secret storage. Sharpie does not handle secrets.
- Add a mode picker, a second mode, or settings beyond what's in "What we're building."
- Modify this document. Propose changes in a PR comment.

The principle: **build the v2 thing in this document, well. Don't expand it. Don't second-guess it.**
