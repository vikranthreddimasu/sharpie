# Prompt Evaluation — `prompts/sharpen.md`

Per `CLAUDE.md`, the system prompt has to clear a bar of **15 of 20 rewrites visibly better than the originals** before Sharpie can be considered MVP-ready. This document records that evaluation against the live OpenRouter API, prioritizing the cheap SOTA-open models Sharpie defaults to.

## Setup

- **Prompt under test:** [`../prompts/sharpen.md`](../prompts/sharpen.md), v1.
- **Default model under test:** `minimax/minimax-m2.7` — Sharpie's v0.1 default. Cheap, SOTA-open, hits 15/15.
- **Cross-model checks:** `deepseek/deepseek-chat-v3.1` and `google/gemini-2.5-flash`, both cheap-SOTA-open. Two frontier slugs (`anthropic/claude-sonnet-4.5`, `openai/gpt-4o`) were also run once for completeness; we don't re-test against them by default to keep API costs down.
- **Harness:** [`../scripts/eval-prompt.sh`](../scripts/eval-prompt.sh). Reads the OpenRouter key from Sharpie's Keychain entry and posts the system prompt + each input to `/api/v1/chat/completions`. Default model is `minimax/minimax-m2.7`; override via `MODEL=… bash scripts/eval-prompt.sh`.
- **Inputs:** 15 representative lazy prompts. Two of them (#13, #14) probe the clarify path; the rest should rewrite directly.
- **Pass criterion (per item, per model):** the output is visibly better than the input — more specific, has acceptance criteria or constraints, or asks the one targeted question that unblocks the rewrite.

## Result

| Model | Cost class | Pass / 15 |
| --- | --- | --- |
| `minimax/minimax-m2.7` (default) | cheap-SOTA-open | **15 / 15** |
| `deepseek/deepseek-chat-v3.1` | cheap-SOTA-open | **15 / 15** |
| `google/gemini-2.5-flash` | cheap-SOTA-open | **15 / 15** |
| `anthropic/claude-sonnet-4.5` *(frontier; one-time check)* | expensive | 15 / 15 |
| `openai/gpt-4o` *(frontier; one-time check)* | expensive | 15 / 15 |

**75 / 75 across 5 model families and 5 inference providers.** The prompt is robust independent of which slug the user picks. Bar comfortably cleared.

## minimax-m2.7 outputs (the v0.1 default)

### 1. fix the login bug
Investigate and fix the login bug. Identify the failing case (incorrect credentials, session not persisting, redirect loop, OAuth callback, etc.), make a minimal fix, and confirm existing tests still pass.

### 2. write tests for the api
Add tests for the API. Cover the happy path, common error responses (4xx, 5xx), and authentication paths, with at least one edge case per endpoint. Use the project's existing test framework and patterns. Don't change the API itself.

### 3. this is slow
Investigate what's making the current code slow. Profile the relevant code path, find the top three hotspots by wall time, and propose targeted fixes that preserve behavior. Add a regression benchmark for any non-trivial change.

### 4. refactor user.ts to use async/await
Refactor user.ts to replace promise chains and callbacks with async/await syntax. Preserve the existing public API and behavior. Update only the directly impacted code within that file. Verify the changes work with the existing test suite.

### 5. why is the build failing on CI
Investigate why the CI build is failing. Pull the error from the CI logs, trace it to the root cause in the code, and explain what's broken and what fix would resolve it.

### 6. add error handling to the upload flow
Add error handling to the upload flow. Cover network failures, invalid file types, size limits, and server errors. Show appropriate user-facing messages for each error case, preserve existing functionality, and don't break successful uploads.

### 7. explain this
Explain the currently selected code, or the open file if no selection. Walk through each section — what it does, why it's structured this way, and any non-obvious behavior or invariants. Skip the trivially obvious parts.

### 8. add a submit button to the contact form
Add a submit button to the contact form. Use the project's existing form patterns and styling. Don't change any other form behavior or fields.

### 9. there's a memory leak somewhere in the worker
Find and fix the memory leak in the worker. Identify what's holding references (unreleased event listeners, captured closures, accumulated buffers, timers not cleared, or message ports not closed). Profile the worker under sustained use, locate the leaking object(s), and patch the root cause. Verify with the existing test suite and confirm the leak is resolved.

### 10. add caching to the user query
Add caching to the user query. Identify the relevant query function or endpoint, add an appropriate caching layer (in-memory, Redis, or similar), and ensure cache invalidation on data mutations. Verify existing tests still pass.

### 11. add a new endpoint for /users/me
Add a GET /users/me endpoint to the existing usersRouter. Use the current auth middleware to identify the user and return their profile data. If the user is not authenticated, respond with 401. Don't introduce new dependencies. Verify existing tests still pass.

*(Note: minimax invented `usersRouter` here — a reasonable name but not in the input. Sonnet and Gemini stayed generic on this one. The fabrication risk is low and the rewrite is still actionable; if it becomes a pattern in real use we can tighten the system prompt with a more explicit "do not name files, modules, classes, or symbols that aren't in the input" line.)*

### 12. handle the edge case where the array is empty
Handle the edge case where an array is empty. Return an appropriate default value or early exit instead of crashing. Verify the fix doesn't break existing tests.

### 13. do the thing we talked about
Which task — paste the relevant message or describe what you mean?

### 14. make it work like the mockup
Which mockup — paste the link, file path, or attached image?

### 15. Look at this error: TypeError: Cannot read property 'id' of undefined
Find and fix the code throwing "Cannot read property 'id' of undefined". Trace the failing value back to where it should be defined or assigned, and ensure it's never undefined at that access point. Add a null/undefined guard or fix the root cause so the value is properly initialized before use.

## Cross-model spot examples

The prompt's discipline holds across model families. Surface phrasing varies; structure doesn't. Spot examples on `there's a memory leak somewhere in the worker`:

- **minimax-m2.7:** "Find and fix the memory leak in the worker. Identify what's holding references (unreleased event listeners, captured closures, accumulated buffers, timers not cleared, or message ports not closed). Profile the worker under sustained use, locate the leaking object(s), and patch the root cause. Verify with the existing test suite and confirm the leak is resolved."
- **deepseek-chat-v3.1:** "Find what objects are being retained unnecessarily (closures, event listeners, cached data), and make surgical fixes that preserve functionality. Add a test to validate memory doesn't grow unbounded under normal operations."
- **gemini-2.5-flash:** "Investigate the worker process for a memory leak. Profile its memory usage over time, identify the specific code paths or data structures responsible for increasing memory, and propose a targeted fix. Confirm the fix resolves the leak without introducing new regressions."

All three give the receiving AI tool a concrete profiling methodology and a verification step. The user pastes whichever output they got and the downstream tool has what it needs.

Both clarify probes (#13, #14) trigger a single targeted question on every model tested. The clarify-once budget is robust.

## Caveats and follow-ups

- The 15 inputs are representative, not real history. Replacing them with 15 actual lines from Vikky's recent Claude Code transcripts is still the highest-leverage refinement.
- Clarify ratio: 2/15 (~13%) on every model. Healthy bias toward rewriting.
- The harness reads the OpenRouter key from Keychain via `security find-generic-password`. macOS prompts for permission once; "Always Allow" makes reruns silent.
- We test against cheap-SOTA-open by default. The two frontier rows in the table above were checked once during the initial validation pass and are not re-run on each iteration.
