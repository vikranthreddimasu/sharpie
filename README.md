# Sharpie

A macOS menu-bar app that turns lazy prompts into the prompt you should have written. Hit `⌘/`, type a quick line, the rewrite streams in and lands on your clipboard, paste it into Claude Code / Cursor / ChatGPT.

**Status: v0.1 — local prototype.** Single window, hard-coded system prompt, BYOA. Two providers wired in: OpenRouter (default — pick any of 368 models from the live list) and Anthropic.

The system prompt that does the rewriting lives in [`prompts/sharpen.md`](prompts/sharpen.md). It is the most important file in this repo. Improvements to it are the highest-value contribution.

For the full product spec, the autonomy contract, and what we're deliberately not building, read [`CLAUDE.md`](CLAUDE.md).

## Run it

Requires macOS 14+ and Xcode 16+ (Swift 6 toolchain).

```sh
make app && open build/Sharpie.app
```

On first launch, click the pencil-tip icon in the menu bar → **Settings…** and paste your API key:

- **OpenRouter** (default) — get a key at [openrouter.ai/keys](https://openrouter.ai/keys). The model picker fetches the live catalog from `/api/v1/models`. The default is `minimax/minimax-m2.7` — cheap SOTA-open performance that hits 15/15 on Sharpie's prompt eval; pick any of the 368+ models if you want.
- **Anthropic** — switch the provider segmented control. Get a key at [console.anthropic.com](https://console.anthropic.com). Uses Claude Sonnet.

Keys are stored in macOS Keychain. Once a key is saved, the SecureField is replaced with a "Stored in Keychain · Replace…" indicator — the stored key never re-loads into the UI.

Then `⌘/` from anywhere → type a lazy prompt → `Return`. The rewrite streams in, auto-copies on completion, paste anywhere.

| key | does what |
| --- | --- |
| `⌘/` | open the window from anywhere |
| `Return` | submit (or dismiss when the rewrite is on screen) |
| `Shift+Return` | newline in the input |
| `Esc` | dismiss |
| `⌘Z` | revert to your original input (after a rewrite) |
| `⌘A` / `⌘C` / `⌘V` / `⌘X` | standard text editing in the input |

## Develop

```sh
make build       # debug build
make run         # foreground, ⌃C to quit
make app         # assemble Sharpie.app at build/Sharpie.app
make clean
```

For prompt iteration:

```sh
bash scripts/eval-prompt.sh                        # 15 lazy inputs, default model
MODEL=openai/gpt-4o bash scripts/eval-prompt.sh    # any OpenRouter slug
```

Reads the OpenRouter key from your Sharpie Keychain entry. If macOS prompts for permission, "Always Allow" once and reruns are silent.

v0.1 is unsigned. macOS Gatekeeper will warn the first time — right-click the app and choose Open.

## License

MIT. See [`LICENSE`](LICENSE).
