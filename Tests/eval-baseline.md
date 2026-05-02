# Sharpie eval report

- Model: `sonnet` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-01 18:20)
- Tests: 34  ·  passed: 26  ·  failed: 8
- Average latency: 8.5s

Pass = expected behavior matched (rewrite vs clarify) AND all assertions held.

## Tier summary

| Tier | Pass | Fail |
|---|---:|---:|
| Lazy classics | 5 | 0 |
| Super-short | 4 | 0 |
| Genuinely cryptic | 3 | 0 |
| Hallucination traps | 3 | 2 |
| Profane / ugly | 1 | 2 |
| Multi-task lazy | 2 | 1 |
| Already-good | 2 | 0 |
| Code/text dumps | 3 | 0 |
| Weird inputs | 1 | 2 |
| Sophisticated | 2 | 1 |

## Failures (the things that need fixing)

### T4.3 — Hallucination traps

**Input:**
```
the api is broken
```

**Output (`clarify`, 5.0s):**
```
Which API — yours or a third-party one you're calling?
```

**Expected:** `rewrite`  
**Failures:**
- expected rewrite, got clarify

### T4.5 — Hallucination traps

**Input:**
```
this React thing isn't working
```

**Output (`clarify`, 5.2s):**
```
Which React thing — what's the behavior you're seeing or expecting?
```

**Expected:** `rewrite`  
**Failures:**
- expected rewrite, got clarify

### T5.1 — Profane / ugly

**Input:**
```
ugh this fucking thing again, fix it
```

**Output (`rewrite`, 14.4s):**
```
Investigate the recurring issue that just resurfaced. Check recent errors, failing tests, git history, and any known unfixed bugs to identify what broke again. Apply a proper fix — not a workaround — and confirm it doesn't regress once resolved.
```

**Expected:** `clarify`  
**Failures:**
- expected clarify, got rewrite

### T5.3 — Profane / ugly

**Input:**
```
i don't even know what im looking at anymore just fix it
```

**Output (`rewrite`, 11.7s):**
```
Audit the current state of the code in focus — identify what's broken, confusing, or structurally unsound. Fix the root issue, clean up any tangled logic that makes it hard to follow, and leave it in a state that's readable and working. Verify with tests or a quick smoke-run that behavior is correct after the changes.
```

**Expected:** `clarify`  
**Failures:**
- expected clarify, got rewrite

### T6.2 — Multi-task lazy

**Input:**
```
fix the bug, write tests, and update the docs
```

**Output (`rewrite`, 9.5s):**
```
Investigate and fix the bug in this codebase — identify the root cause, apply a minimal targeted fix, and add a regression test that would have caught it. Then write tests for any untested paths exposed by the fix, following the project's existing test patterns. Finally, update the relevant documentation to reflect the corrected behavior; do not rewrite sections unaffected by the change.
```

**Expected:** `rewrite`  
**Failures:**
- missing required term: 'docs'

### T9.1 — Weird inputs

**Input:**
```
🐛 → 🦋
```

**Output (`rewrite`, 8.6s):**
```
Investigate the current bug. Find the root cause, apply a minimal fix, and verify the fix with existing tests — add a targeted regression test if the failure mode isn't already covered.
```

**Expected:** `clarify`  
**Failures:**
- expected clarify, got rewrite

### T9.3 — Weird inputs

**Input:**
```
fix the bug — el botón no funciona
```

**Output (`rewrite`, 5.6s):**
```
Fix the broken button. Identify which button is unresponsive, trace the event handler or wiring failure, apply a minimal fix, and confirm the button works as expected without breaking adjacent behavior.
```

**Expected:** `rewrite`  
**Failures:**
- missing required term: 'botón'

### T10.3 — Sophisticated

**Input:**
```
the codebase has accumulated 3 different ways to handle errors, pick one and standardize
```

**Output (`rewrite`, 8.9s):**
```
Audit the codebase for all error handling patterns and identify the three approaches in use. Pick the most consistent, idiomatic one based on the project's language and conventions. Migrate all error handling to that single pattern, removing the other two. Verify the refactor with the existing test suite and confirm no error paths were silently dropped.
```

**Expected:** `rewrite`  
**Failures:**
- missing required term: 'errors'

## All results

### Lazy classics

#### ✅ T1.1 — `expect: rewrite` · 7.5s

**Input:** `fix the login bug`

**Output (`rewrite`):**

```
Investigate the login bug. Identify the failing case, apply a minimal fix, and confirm existing tests still pass — add a regression test for the specific failure mode you find.
```

#### ✅ T1.2 — `expect: rewrite` · 7.1s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Profile the current code path and identify the top hotspots by wall time. Propose targeted fixes that preserve existing behavior, prioritize the highest-impact change, and add a benchmark or timing assertion that would catch a regression.
```

#### ✅ T1.3 — `expect: rewrite` · 7.0s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Add tests for the API. Cover the happy path, the common error responses, and the authentication paths, with at least one edge case per endpoint. Use the project's existing test framework and patterns. Do not change the API itself.
```

#### ✅ T1.4 — `expect: rewrite` · 6.9s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API and the file's external behavior. Update directly impacted call sites in the same file only. Verify with the existing test suite.
```

#### ✅ T1.5 — `expect: rewrite` · 9.3s

**Input:** `explain this`

**Output (`rewrite`):**

```
Explain the currently selected code, or the open file if nothing is selected. Walk through each section — what it does, why it is structured this way, and any non-obvious behavior or invariants. Skip the trivially obvious.
```

### Super-short

#### ✅ T2.1 — `expect: clarify` · 16.2s

**Input:** `fix`

**Output (`clarify`):**

```
What's broken?
```

#### ✅ T2.2 — `expect: clarify` · 10.5s

**Input:** `help`

**Output (`clarify`):**

```
What do you need help with?
```

#### ✅ T2.3 — `expect: clarify` · 7.8s

**Input:** `wtf`

**Output (`clarify`):**

```
What broke — paste the error or describe what you're seeing?
```

#### ✅ T2.4 — `expect: clarify` · 8.0s

**Input:** `make it work`

**Output (`clarify`):**

```
What's broken — paste the error, describe the symptom, or name the thing that isn't working?
```

### Genuinely cryptic

#### ✅ T3.1 — `expect: clarify` · 5.7s

**Input:** `do the thing we talked about`

**Output (`clarify`):**

```
Which task — paste the relevant message or describe what you mean?
```

#### ✅ T3.2 — `expect: clarify` · 5.4s

**Input:** `make it work like the mockup`

**Output (`clarify`):**

```
Which mockup — paste the link, file path, or attached image?
```

#### ✅ T3.3 — `expect: clarify` · 5.2s

**Input:** `the usual`

**Output (`clarify`):**

```
Which task — what do you mean by "the usual"?
```

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 7.0s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Investigate the auth issue in this codebase. Identify the root cause — whether it's a broken flow, failed token handling, misconfigured middleware, or something else — and apply a minimal targeted fix. Verify the fix doesn't break adjacent auth paths, and confirm existing tests still pass or add a regression test for the specific failure.
```

#### ✅ T4.2 — `expect: rewrite` · 6.7s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Profile the database queries and identify the top bottlenecks by execution time and frequency. Fix the highest-impact issues first — missing indexes, N+1 queries, unneeded full-table scans — without changing the schema's public interface. Verify improvements with before/after query plans or benchmarks, and add a regression test or assertion that would catch a performance rollback.
```

#### ❌ T4.3 — `expect: rewrite` · 5.0s

**Input:** `the api is broken`

**Output (`clarify`):**

```
Which API — yours or a third-party one you're calling?
```

Failures:
- expected rewrite, got clarify

#### ✅ T4.4 — `expect: rewrite` · 9.0s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Investigate the keyboard shortcuts in this app — find which ones are broken, trace why they fail to fire or register, and apply a minimal fix. Verify each repaired shortcut works end-to-end and that unrelated shortcuts remain unaffected.
```

#### ❌ T4.5 — `expect: rewrite` · 5.2s

**Input:** `this React thing isn't working`

**Output (`clarify`):**

```
Which React thing — what's the behavior you're seeing or expecting?
```

Failures:
- expected rewrite, got clarify

### Profane / ugly

#### ❌ T5.1 — `expect: clarify` · 14.4s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Investigate the recurring issue that just resurfaced. Check recent errors, failing tests, git history, and any known unfixed bugs to identify what broke again. Apply a proper fix — not a workaround — and confirm it doesn't regress once resolved.
```

Failures:
- expected clarify, got rewrite

#### ✅ T5.2 — `expect: rewrite` · 7.1s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Debug the form submission handler — the form submits without errors but produces no visible result. Trace the full submission flow: the event handler, any async calls, state updates, and UI feedback. Identify where the response is being dropped or ignored, fix it, and verify the expected outcome renders after a successful submission.
```

#### ❌ T5.3 — `expect: clarify` · 11.7s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Audit the current state of the code in focus — identify what's broken, confusing, or structurally unsound. Fix the root issue, clean up any tangled logic that makes it hard to follow, and leave it in a state that's readable and working. Verify with tests or a quick smoke-run that behavior is correct after the changes.
```

Failures:
- expected clarify, got rewrite

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 9.7s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Audit the keyboard shortcuts in this app for both correctness (each one fires from where the UI claims) and usefulness (remove or replace dead bindings). Then add a model selection control surfaced in the settings panel, and propose UI tweaks that improve daily use — implement the agreed-upon ones.
```

#### ❌ T6.2 — `expect: rewrite` · 9.5s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Investigate and fix the bug in this codebase — identify the root cause, apply a minimal targeted fix, and add a regression test that would have caught it. Then write tests for any untested paths exposed by the fix, following the project's existing test patterns. Finally, update the relevant documentation to reflect the corrected behavior; do not rewrite sections unaffected by the change.
```

Failures:
- missing required term: 'docs'

#### ✅ T6.3 — `expect: rewrite` · 9.5s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Refactor the current codebase for clarity and performance. Identify hotspots — slow queries, redundant computations, unnecessary re-renders or repeated I/O — and add appropriate caching at each layer. Preserve all existing behavior and public interfaces. Verify with the existing test suite after changes.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 13.8s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the `useAuth` hook in `hooks/useAuth.ts` to replace the `useEffect`+`useState` pattern with `useReducer`. Preserve the existing public API surface exactly — callers must not need changes outside the file. Update any internal callers within `hooks/useAuth.ts` itself. Run the existing test suite to confirm nothing regressed; fix any failures before finishing.
```

#### ✅ T7.2 — `expect: rewrite` · 7.4s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a `/healthz` endpoint that returns HTTP 200 with a JSON body containing the build SHA and uptime in seconds. Use the project's existing routing patterns and framework conventions. Source the build SHA from the environment or build artifact the project already uses, and calculate uptime from process start time. Add a smoke test or update existing tests to cover the new endpoint.
```

### Code/text dumps

#### ✅ T8.1 — `expect: either` · 6.1s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
Add JSDoc comments to the `add` function, then convert it to TypeScript with proper parameter and return type annotations. Verify the file type-checks cleanly after the change.
```

#### ✅ T8.2 — `expect: rewrite` · 12.0s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Find the source of the `TypeError: Cannot read property 'map' of undefined` error. Locate the `.map()` call on a value that can be undefined, add a null/undefined guard or fix the upstream data flow so the value is always an array. Verify the fix handles both the empty and populated cases without breaking existing behavior.
```

#### ✅ T8.3 — `expect: rewrite` · 8.7s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate the `ConnectionRefusedError` thrown at `app.run()` in `server.py` line 42. Find what service or socket `app` is trying to connect to, determine why that connection is being refused at startup, and apply a fix. Verify the server starts cleanly after the change.
```

### Weird inputs

#### ❌ T9.1 — `expect: clarify` · 8.6s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Investigate the current bug. Find the root cause, apply a minimal fix, and verify the fix with existing tests — add a targeted regression test if the failure mode isn't already covered.
```

Failures:
- expected clarify, got rewrite

#### ✅ T9.2 — `expect: clarify` · 9.4s

**Input:** `PLEASE FIX THIS`

**Output (`clarify`):**

```
What's broken — paste the error, describe the bug, or name the file?
```

#### ❌ T9.3 — `expect: rewrite` · 5.6s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Fix the broken button. Identify which button is unresponsive, trace the event handler or wiring failure, apply a minimal fix, and confirm the button works as expected without breaking adjacent behavior.
```

Failures:
- missing required term: 'botón'

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 8.9s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate the payment processing flow for race conditions. Look for shared mutable state, non-atomic read-modify-write sequences, and missing locks or transaction isolation — particularly around anything that touches balance, order status, or idempotency keys. Reproduce the condition under concurrent load if possible, identify the unsafe code path, and apply a fix using the project's existing concurrency primitives. Add a test that exercises the concurrent path and fails before the fix, passes after.
```

#### ✅ T10.2 — `expect: rewrite` · 8.1s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate why the caching layer added last week is slowing down cold-start performance. Locate the caching code, trace the cold-start path, and identify what initialization or overhead it introduces that wasn't present before. Profile or instrument the path if needed, propose a targeted fix, and verify the fix doesn't regress warm-start or cache-hit behavior.
```

#### ❌ T10.3 — `expect: rewrite` · 8.9s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Audit the codebase for all error handling patterns and identify the three approaches in use. Pick the most consistent, idiomatic one based on the project's language and conventions. Migrate all error handling to that single pattern, removing the other two. Verify the refactor with the existing test suite and confirm no error paths were silently dropped.
```

Failures:
- missing required term: 'errors'
