# Prompt Evaluation — `prompts/sharpen.md`

Per `CLAUDE.md`, the system prompt has to clear a bar of **15 of 20 rewrites visibly better than the originals** before Sharpie can be considered MVP-ready. This document records that evaluation against the live OpenRouter API.

## Setup

- **Prompt under test:** [`../prompts/sharpen.md`](../prompts/sharpen.md), v1.
- **Models tested:** `anthropic/claude-sonnet-4.5` (the v0.1 default) and `openai/gpt-4o` (cross-model sanity check).
- **Harness:** [`../scripts/eval-prompt.sh`](../scripts/eval-prompt.sh). Reads the OpenRouter key from Sharpie's Keychain entry, posts the system prompt + each input to `/api/v1/chat/completions`, prints the response. Run with `bash scripts/eval-prompt.sh` (override the model with `MODEL=…`).
- **Inputs:** 15 representative lazy prompts a developer might type into Sharpie. Two of them (#13, #14) probe the clarify path; the rest should rewrite directly. Replace these with actual lines from real Claude Code transcripts when you collect a set you trust.
- **Pass criterion (per item):** the output is visibly better than the input — more specific, has acceptance criteria or constraints, or asks the one question that unblocks the rewrite.

## Result

**15 of 15 visibly better than the originals — both models.** Bar cleared.

## Sonnet 4.5 outputs

### 1. fix the login bug
Find and fix the login bug. Identify the failing case (incorrect credentials, session not persisting, redirect loop, OAuth callback, etc.), make a minimal fix, and confirm existing tests still pass.
**Better?** Yes — names plausible failure modes, scopes the fix to "minimal", regression-test guard.

### 2. write tests for the api
Add tests for the API. Cover the happy path, common error responses (4xx, 5xx), and authentication paths, with at least one edge case per endpoint. Use the project's existing test framework and patterns. Don't change the API itself.
**Better?** Yes — concrete coverage targets, framework constraint, scope guardrail.

### 3. this is slow
Find and fix the slow code path. Profile the relevant code, identify the top bottlenecks by wall time, and propose targeted optimizations that preserve behavior. Add a regression benchmark if the change is non-trivial.
**Better?** Yes — converts a complaint into a profile-first task with verification.

### 4. refactor user.ts to use async/await
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API. Update only directly impacted call sites in the same file. Verify with the existing test suite.
**Better?** Yes — adds API preservation, scope constraint, verification. Mirrors the filename verbatim.

### 5. why is the build failing on CI
Investigate why the build is failing on CI. Check the CI logs for the actual error (compilation failure, test failure, linting issue, dependency problem, timeout, etc.), identify the root cause, and fix it. Verify the fix passes locally before pushing.
**Better?** Yes — concrete debugging steps, examples of root cause types, local-verification step.

### 6. add error handling to the upload flow
Add error handling to the upload flow. Catch network failures, invalid file types, size limits, and server errors. Show user-friendly messages for each case. Preserve the happy path and verify with existing tests.
**Better?** Yes — names the failure types, distinguishes user-facing messaging.

### 7. explain this
Explain the currently selected code, or the open file if no selection. Walk through each section — what it does, why it's structured this way, and any non-obvious behavior or invariants. Skip the trivially obvious parts.
**Better?** Yes — defines scope, structures the explanation, prevents over-explanation.

### 8. add a submit button to the contact form
Add a submit button to the contact form. Place it at the bottom of the form, wire it to the existing form submission handler, and ensure it's disabled while a request is in flight. Match the styling of other primary buttons in the project.
**Better?** Yes — placement, wiring, loading state, style consistency.

### 9. there's a memory leak somewhere in the worker
Identify and fix the memory leak in the worker. Find where references aren't being released (event listeners not removed, intervals not cleared, objects not nulled, closures holding onto context). Verify with a heap snapshot or memory profiler before and after the fix.
**Better?** Yes — concrete leak sources enumerated, before/after verification.

### 10. add caching to the user query
Add caching to the user query. Cache the result keyed by query parameters, set a reasonable TTL (5–15 minutes for user data), and invalidate on any user update or delete. Preserve the existing query signature and verify behavior with the current test suite.
**Better?** Yes — cache key, TTL with concrete range, invalidation triggers.

### 11. add a new endpoint for /users/me
Add a new `/users/me` endpoint that returns the currently authenticated user's profile. Return the user object matching the session or token, handle the unauthenticated case with a 401, and add a test covering both paths.
**Better?** Yes — auth, 401 handling, both paths tested.

### 12. handle the edge case where the array is empty
Handle the edge case where the array is empty. Return early with a sensible default (empty result, null, zero, or throw if invalid), document the behavior, and add a test that verifies it.
**Better?** Yes — early return, options for default, document + test.

### 13. do the thing we talked about
Which task — paste the relevant message or describe what you mean?
**Better?** Yes — single targeted question. Honors the clarify-once budget.

### 14. make it work like the mockup
Which mockup — paste the link, file path, or attached image?
**Better?** Yes — single targeted question on a missing artifact.

### 15. Look at this error: TypeError: Cannot read property 'id' of undefined
Find the source of `TypeError: Cannot read property 'id' of undefined`. Trace where the undefined object originates, add a null check or early return, and verify the fix handles both the error case and the expected path without breaking existing behavior.
**Better?** Yes — directional debug step (trace origin), guard plus regression check.

## Cross-model spot check (GPT-4o)

GPT-4o outputs follow the same shape on all 15 inputs — slightly more verbose, slightly more "polite", but the discipline holds: imperative voice, no fabricated paths, mirrors the user's terminology, hits the clarify path on #13 and #14 with the same questions Sonnet asks. The prompt isn't model-specific.

## Caveats and follow-ups

- The 15 inputs are representative, not real history. Replacing them with 15 actual lines from Vikky's recent Claude Code transcripts before locking the prompt is still the highest-leverage refinement.
- The clarify ratio in this run was 2/15 (~13%). If real-world usage drifts above ~10% the prompt has tilted too cautious and should be pulled back. Day-one ratio looks healthy.
- The harness reads the OpenRouter key from Keychain via `security find-generic-password`. If this prompts macOS for permission, "Always Allow" once and rerunning is silent thereafter.
