# Sharpie

A menu-bar app that turns lazy prompts into the prompt you should have written.

This document is the source of truth for Claude Code building Sharpie. Read it fully before doing anything. The autonomy contract at the bottom defines what you decide on your own, what you ask about, and what's off-limits.

## The story

You're in Claude Code, ChatGPT, or Cursor. You start typing "fix the login bug" and you already know the model is going to ask three follow-up questions or, worse, hallucinate a context that doesn't exist. You have two choices: stop, think, write a real prompt — or send the lazy one and waste a turn.

Sharpie is the third option. Hit a hotkey. Type your lazy input. Sharpie either rewrites it directly into a sharper prompt, or asks you the *one* question that's actually missing, then assembles the prompt. You hit Enter, the result lands on your clipboard, you paste it back into whatever tool you were using. Total time: under fifteen seconds.

The product is for developers and ML engineers who already use Claude Code, ChatGPT, Cursor, Codex, and Perplexity multiple times a day. Not marketers. Not lawyers. The defaults are tuned for technical work.

## The experience

**First run.** Install via Homebrew. Open the app once, pick a provider (Anthropic or OpenRouter), paste in the API key (stored in macOS Keychain). If OpenRouter, pick a model from the dropdown — the app fetches the live model list from OpenRouter so the choice is always current. The global hotkey is `⌘/` by default, configurable in settings. Done. The app lives in the menu bar from now on.

**The core loop.** Hit the hotkey from anywhere. A small window appears, focused, cursor in the input. Type or paste a lazy prompt. Hit Enter.

**The rewrite path.** Sharpie judges whether the input has enough to work with. If yes, it streams the rewritten prompt into the output area and copies it to clipboard the moment streaming finishes. Hit Enter again to dismiss. The sharpened prompt is on your clipboard, ready to paste wherever you were headed.

**The clarify path.** If the input is genuinely ambiguous, Sharpie asks exactly one question. Not three. Not "let me understand better." One specific question that unblocks the rewrite. You answer in the same window. It produces the prompt. Same copy-and-dismiss flow.

**The escape hatch.** If you don't like the rewrite, hit `⌘Z` to see your original input back, edit it, re-run. Or hit Esc and start over. The original is never lost.

**The failure case.** If the API call fails (no network, bad key, rate limit), the original input stays in the window with a clear error message. No spinner-of-doom. No silent failure. The user can copy their original text out and move on.

## What we're building

- macOS menu-bar app (Swift, native — not Electron).
- Global hotkey, configurable, single-window UI.
- **One mode, one system prompt.** Tuned for technical prompts (Claude Code, ChatGPT for code, Cursor, debugging, code review). The system prompt lives in `prompts/sharpen.md` and is loaded at app startup.
- Two providers on day one: **Anthropic** (default, Claude Sonnet) and **OpenRouter** (any model the user picks from a dropdown). BYOA. API keys stored in macOS Keychain. Provider and model are settings, not part of the core loop.
- A **clarification budget of 1**. The system prompt enforces this: at most one follow-up question, then assemble. This is the product, not a setting.
- Streaming output, auto-copy to clipboard on completion.
- A `prompts/` folder in the repo containing the system prompt as plain markdown. The app reads it at startup. Editing it is how the community contributes.

## What we're NOT building

- No Windows or Linux build for v1. Mac only.
- No floating pill, no always-visible UI. Hotkey + window is the interaction.
- No auto-detection of input fields, no injection into other apps' text boxes. Clipboard is the bridge.
- No local-model support, no Ollama on day one. (OpenRouter covers most cloud models people want.)
- No history, no favorites, no saved prompts. Every invocation is fresh.
- No telemetry. The app makes outbound calls only to the provider the user has configured (Anthropic or OpenRouter), with the user's key.
- No accounts, no signup, no cloud sync.
- No mode picker, no second mode. One excellent system prompt beats two mediocre ones. A General mode earns its way in only if v1 users explicitly need it.

## How we'll ship it

- **v0.1 — local prototype.** Working hotkey, single window, hard-coded system prompt, Anthropic only. Vikky uses it himself for a week. Goal: does the rewrite quality justify the round-trip?
- **v0.2 — provider abstraction + prompt moves out.** Both Anthropic and OpenRouter work behind a single `LLMProvider` interface. The system prompt lives in `prompts/sharpen.md`. Clarify-once behavior implemented. Repo is public. README explains the project and invites prompt contributions.
- **v1.0 — the install story works.** Homebrew tap, signed binary, first-run flow with Keychain and provider picker. README has a 30-second demo GIF. Posted to Hacker News and r/LocalLLaMA. The repo is structured so the highest-value contribution is a PR to `prompts/sharpen.md`.

Technical commitment that unblocks v1: native Swift menu-bar app using SwiftUI for the window. Avoids the Electron tax on memory and startup time, which matters because the hotkey-to-window latency *is* the product.

## How we'll know it worked

- Vikky uses it daily for a month without uninstalling. If he stops, the product is wrong.
- Three other developers in his network adopt it for their own daily AI work without him asking them to.
- At least one external contributor opens a PR against `prompts/` within the first 60 days. That's the signal that the open-source thesis — community-improved rewriting prompts — is real.

## Open questions

- **The clarify-once UX.** Is it a separate screen, or does the question appear inline above the input with the original text preserved? Decide before writing the window code.
- **Clipboard behavior on rewrite.** Auto-copy on completion, or require an explicit Copy action? Auto-copy is faster but surprises users who didn't want it. Lean toward auto-copy with a visible "Copied" toast.
- **What goes in `prompts/sharpen.md`.** This is the entire product. Needs to be drafted, tested against 20 real lazy prompts from Vikky's Claude Code history, iterated until 15+ rewrites are visibly better than the originals. This work happens before any UI code.

---

## Notes for Claude Code

- Stack: Swift 5.9+, SwiftUI, macOS 14+. No Electron, no React, no Tauri.
- API key storage: `Security.framework` Keychain APIs. Never write the key to disk in plaintext.
- Hotkey: use `Carbon` `RegisterEventHotKey` or the modern `NSEvent.addGlobalMonitorForEvents` — pick whichever works correctly with the app sandbox. Document the tradeoff in the code.
- Streaming: both Anthropic and OpenRouter expose SSE streaming endpoints. Stream tokens into the output `TextEditor` as they arrive. Do not block the UI.
- Provider abstraction: define a `LLMProvider` protocol with `streamCompletion(systemPrompt:userInput:) -> AsyncStream<String>`. Implement two conformers: `AnthropicProvider` and `OpenRouterProvider`. The rest of the app talks only to the protocol. Adding Ollama or another provider later is one new file.
- The window: borderless, rounded, draggable by the title area, dismissible with Esc, single text input on top, output area below, status line at the bottom. Centered on the active screen on hotkey activation.
- The system prompt in `prompts/sharpen.md` is the most important file in the repo. Treat it like source code: it gets reviewed, versioned, and tested. The README should make this explicit.
- No analytics SDK. No crash reporter. No update checker calling home. Updates happen via Homebrew.

## Repo setup (Claude Code does this first)

Before writing any code, Claude Code creates the GitHub repo and project skeleton.

- Repo name: `sharpie`. Public. MIT license.
- Owner: Vikky's GitHub account (use the `gh` CLI; assume it's already authenticated).
- Repo description: *"A menu-bar app that turns lazy prompts into the prompt you should have written. BYOA."*
- Initial structure:
  ```
  sharpie/
    README.md
    LICENSE
    .gitignore (Swift + macOS)
    CLAUDE.md (this file, copied in verbatim — keep it at the repo root so Claude Code auto-loads it)
    prompts/
      sharpen.md
    Sharpie/ (Xcode project)
    Tests/
  ```
- The README should be minimal at first commit: one-paragraph explanation, "status: in development," link to `CLAUDE.md` for the full spec. Polish the README for v1.0, not v0.1.
- Commit early and often. One feature per branch, PRs against main, even though Vikky is the only reviewer. This gives him a clean diff to scan when he checks in.

## Autonomy contract for Claude Code

Vikky is handing this off. He does not want to be pinged for every micro-decision. The rules:

**Decide on your own. Do not ask.**
- All implementation choices: file structure, class names, whether to use `Combine` vs `async/await`, which SwiftUI components, error message wording, keyboard shortcut handling, window animations.
- Library choices, as long as they are MIT/Apache/BSD licensed and well-maintained.
- The exact wording of UI labels, error messages, the README, the empty state, the "Copied" toast.
- How to structure tests, what to test, how much to test.
- The visual design of the window within the constraints already specified (borderless, rounded, etc.). Pick reasonable spacing and typography. Do not ask for hex codes.
- Git commit messages, branch names, PR descriptions.

**Decide and tell Vikky what you decided in the PR description.** Don't ask first.
- Any tradeoff between two reasonable approaches — pick one, document why in the PR.
- Anything covered by "lean toward X" in this document — just do X.

**Stop and ask Vikky only for these.**
- Decisions that contradict something explicit in this document (e.g., "I think we should support Ollama in v1 actually").
- Decisions that affect cost or external accounts (signing certificate purchases, paid services, anything that costs money).
- Anything that would publish or push something irreversible to the outside world before v1.0 — first Hacker News post, first tweet, first Homebrew tap publication. These are launch decisions, not engineering ones.
- If `prompts/sharpen.md` testing shows fewer than 15 of 20 rewrites are visibly better than the originals. That's a product-level signal, not an engineering one.

**Never do these without Vikky's explicit go-ahead, even if asked.**
- Add telemetry, analytics, or any phone-home behavior.
- Add a second mode, a settings panel beyond what's in this PRD, or any feature not listed in "What we're building."
- Add a third LLM provider in v1.
- Modify this document. Propose changes in a comment on the relevant PR. Vikky decides.

The principle: **build the thing in this document, well. Don't expand it. Don't second-guess it. If something is genuinely blocking, write a one-line note in the PR and keep moving on the parts that aren't blocked.**

The call to make next: create the repo, copy this document in as `CLAUDE.md`, then draft `prompts/sharpen.md`. Test that prompt against real lazy inputs before writing any Swift code.

