# Sharpie

A macOS menu-bar app that turns lazy prompts into the prompt you should have written. Hit a hotkey, type a quick line, get a sharper prompt copied to your clipboard, paste it into Claude Code / Cursor / ChatGPT.

**Status: in development.** v0.1 is a local prototype — Anthropic only, hard-coded system prompt, single window.

The system prompt that does the rewriting lives in [`prompts/sharpen.md`](prompts/sharpen.md). It is the most important file in this repo. Improvements to it are the highest-value contribution. PRs welcome once v0.2 lands.

For the full product spec, the autonomy contract, and what we are deliberately not building, read [`CLAUDE.md`](CLAUDE.md).

## Run it (v0.1)

Requires macOS 14+ and Xcode 15+ (for Swift 6 toolchain).

```sh
# put your Anthropic key in the Keychain (recommended) — open the app once
# and use "Set Anthropic API Key…" in the menu, OR just export it for dev:
export ANTHROPIC_API_KEY=sk-ant-...

make run     # foreground, ⌃C to quit
# or
make app && open build/Sharpie.app
```

The hotkey is `⌘/`. Hit it from anywhere, type a lazy prompt, press Enter. The sharpened prompt streams in and lands on your clipboard.

- `Esc` dismisses the window.
- `⌘Z` brings your original input back.
- `Shift+Return` inserts a newline; `Return` submits.

v0.1 is unsigned. macOS Gatekeeper will warn the first time — right-click the app and choose Open.

## License

MIT. See [`LICENSE`](LICENSE).
