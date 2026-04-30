# Sharpie

A macOS menu-bar app that turns lazy prompts into the prompt you should have written. Hit `⌘/`, type a quick line, the rewrite streams in and lands on your clipboard, paste it into Claude Code, Cursor, ChatGPT, Codex, or Perplexity.

> **Status: v0.1 — local prototype.** Single window, hard-coded system prompt, BYOA. The build is unsigned; macOS Gatekeeper will warn the first time. Code signing, Homebrew tap, and a demo GIF land in v1.0.

## Why

You're in Claude Code, ChatGPT, or Cursor. You start typing "fix the login bug" and you already know the model is going to ask three follow-up questions or, worse, hallucinate a context that doesn't exist. Sharpie is the third option: hit a hotkey, type your lazy input, paste the sharpened prompt back. Total time: under fifteen seconds.

## The system prompt is the product

Sharpie's behavior lives in **[`prompts/sharpen.md`](prompts/sharpen.md)** — that file is more important than any code in this repo. The Swift app is the delivery vehicle; the prompt is what makes it useful. PRs against `prompts/sharpen.md` are the highest-leverage contribution you can make.

The current prompt has been validated against 5 model families on the live OpenRouter API: 75 / 75 visibly-better rewrites. See [`Tests/prompt-eval.md`](Tests/prompt-eval.md) for the full evaluation.

## Run it

Requires macOS 14+ and Xcode 16+ (Swift 6 toolchain). Apple Silicon recommended.

```sh
git clone https://github.com/vikranthreddimasu/sharpie.git
cd sharpie
make app
open build/Sharpie.app
```

On first launch, Sharpie opens Settings automatically — paste an API key for either provider and you're done.

| Provider | Default | Get a key |
| --- | --- | --- |
| **OpenRouter** (default) | `minimax/minimax-m2.7` — cheap SOTA-open | [openrouter.ai/keys](https://openrouter.ai/keys) |
| **Anthropic** | Claude Sonnet | [console.anthropic.com](https://console.anthropic.com) |

The model picker fetches OpenRouter's full catalog (368+ models, 56+ providers) live each time Settings opens. Search by slug or name; the v0.1 default stays cheap-SOTA-open by design.

### Keys

| key | does what |
| --- | --- |
| `⌘/` *(configurable)* | open Sharpie from anywhere |
| `↩` | submit (or dismiss when the rewrite is on screen) |
| `⇧↩` | newline in the input |
| `⎋` | dismiss |
| `⌘Z` | revert to your original input *(after a rewrite)* |
| `⌘A` / `⌘C` / `⌘V` / `⌘X` | standard text editing in the input |
| `⌘,` | open Settings *(when the menu is showing)* |

## Privacy and security

- **Keys live only in macOS Keychain.** Never written to disk in plaintext, never logged, never sent anywhere except the provider you pick.
- **Once a key is stored, it does not re-load into the UI.** Settings shows `🔒 Stored in Keychain · Replace…`. The Reveal toggle can only show a key you just typed — not a key you typed last week.
- **Reveal auto-hides after 5 seconds.**
- **Outbound traffic is restricted to the configured provider's API.** The model directory pulls from `openrouter.ai/api/v1/models` (no auth required); rewrites POST to either `openrouter.ai/api/v1/chat/completions` or `api.anthropic.com/v1/messages` depending on the active provider.
- **No telemetry, no analytics, no crash reporter, no update checker.** Zero phone-home. Updates ship via Homebrew once that lands in v1.0.

## Contribute

The most valuable PR you can open is one that improves [`prompts/sharpen.md`](prompts/sharpen.md). To iterate locally:

```sh
# 1. Save an OpenRouter key in Sharpie → Settings…
# 2. Run the eval against a cheap default
bash scripts/eval-prompt.sh

# 3. Or pin a specific model
MODEL=qwen/qwen3.6-max-preview bash scripts/eval-prompt.sh
```

The harness reads your stored key from Sharpie's Keychain entry (one-time macOS approval). Output goes to stdout — eyeball each rewrite, edit `prompts/sharpen.md`, rerun. The bar is **15 of 20** rewrites visibly better than the originals; record any regression case in `Tests/prompt-eval.md`.

## What we're deliberately not building

Sharpie is a sharp little tool, not a platform. From [`CLAUDE.md`](CLAUDE.md):

- No history, no favorites, no saved prompts. Every invocation is fresh.
- No floating pill, no always-visible UI. Hotkey + window is the interaction.
- No auto-detection of input fields, no injection into other apps. Clipboard is the bridge.
- No second mode. One excellent system prompt beats two mediocre ones.
- No accounts, no signup, no cloud sync.
- No telemetry of any kind.

For the full product spec and the autonomy contract, read [`CLAUDE.md`](CLAUDE.md).

## Architecture

- **Swift 6 / SwiftUI / AppKit, no Electron, no React, no third-party dependencies.** Native menu-bar app via `NSApp.setActivationPolicy(.accessory)` plus `LSUIElement=true` in the bundled Info.plist.
- **Global hotkey via Carbon `RegisterEventHotKey`** — works without Accessibility permission and consumes the keystroke (no leakage to whatever app is focused).
- **`LLMProvider` protocol** with two conformers (`OpenRouterProvider`, `AnthropicProvider`). Adding a third — Ollama, Bedrock, whatever — is one new file.
- **SSE streaming** for both providers; tokens render into the output area as they arrive.
- **System prompt bundled via SwiftPM resources**, symlinked from `prompts/sharpen.md` so contributors edit one canonical file.

```
sharpie/
├── Package.swift            — SwiftPM (no .xcodeproj noise)
├── Makefile                 — make build / run / app / clean
├── prompts/sharpen.md       — the one file that matters most
├── Sources/Sharpie/         — Swift sources
├── Tests/prompt-eval.md     — the eval that gates the prompt
├── scripts/
│   ├── eval-prompt.sh       — prompt evaluation harness
│   ├── build-app.sh         — wrap release binary as Sharpie.app
│   └── generate-icon.swift  — programmatic AppIcon.icns
└── assets/AppIcon.icns      — generated app icon
```

## License

MIT. See [`LICENSE`](LICENSE).
