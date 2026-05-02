# Sharpie eval report

- Model: `sonnet` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-01 19:00)
- Tests: 34  ·  passed: 24  ·  failed: 10
- Average latency: 8.7s

Pass = expected behavior matched (rewrite vs clarify) AND all assertions held.

## Tier summary

| Tier | Pass | Fail |
|---|---:|---:|
| Lazy classics | 4 | 1 |
| Super-short (rewrite even when cryptic) | 1 | 3 |
| Cryptic external context (rewrite anyway) | 0 | 3 |
| Hallucination traps | 5 | 0 |
| Profane / ugly | 1 | 2 |
| Multi-task lazy | 3 | 0 |
| Already-good | 2 | 0 |
| Code/text dumps | 3 | 0 |
| Weird inputs | 2 | 1 |
| Sophisticated | 3 | 0 |

## Failures (the things that need fixing)

### T1.3 — Lazy classics

**Input:**
```
write tests for the api
```

**Output (`rewrite`, 6.0s):**
```
Write tests for the API. Cover the happy path, common error responses, and authentication paths, with at least one edge case per endpoint. Use the project's existing test framework and patterns. Do not change the API itself.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T2.1 — Super-short (rewrite even when cryptic)

**Input:**
```
fix
```

**Output (`rewrite`, 8.4s):**
```
Pick up the most recent failure or in-progress task visible in this conversation, the open file, or the last failing test. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If no concrete failure is in scope, list the candidates you can see and ask which one to address.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T2.2 — Super-short (rewrite even when cryptic)

**Input:**
```
help
```

**Output (`rewrite`, 11.9s):**
```
Pick up the most recent in-progress task or failure visible in this conversation, the open file, or the working directory. Identify the clearest next step and take it. If the current state is ambiguous, list the candidates you can see and ask which one to address.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T2.4 — Super-short (rewrite even when cryptic)

**Input:**
```
make it work
```

**Output (`rewrite`, 8.5s):**
```
Pick up whatever is currently broken or failing in the open file, recent diff, or last error output. Identify the root cause, apply the smallest correct fix, and verify the fix doesn't introduce regressions. If there are multiple candidates, list them and ask which one to address first.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T3.1 — Cryptic external context (rewrite anyway)

**Input:**
```
do the thing we talked about
```

**Output (`rewrite`, 8.1s):**
```
Continue the most recent in-progress task from this conversation or the current working directory's recent activity. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask which one to resume.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T3.2 — Cryptic external context (rewrite anyway)

**Input:**
```
make it work like the mockup
```

**Output (`rewrite`, 8.5s):**
```
Reconcile the current implementation with the most recently-shared mockup. If a mockup file or image is in the workspace or recent attachments, use that as the reference. Apply changes that match the mockup's structure, layout, and visual hierarchy without inventing details. If no mockup is clearly in scope, list what you can find and ask which one is the target.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T3.3 — Cryptic external context (rewrite anyway)

**Input:**
```
the usual
```

**Output (`rewrite`, 10.9s):**
```
Continue the most recent in-progress task from this conversation, the current working directory, or the open file. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask which one to resume.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T5.1 — Profane / ugly

**Input:**
```
ugh this fucking thing again, fix it
```

**Output (`rewrite`, 10.2s):**
```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps regressing, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence. If no concrete failure is immediately in scope, list the candidates you can see and ask which one to address.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T5.3 — Profane / ugly

**Input:**
```
i don't even know what im looking at anymore just fix it
```

**Output (`rewrite`, 9.1s):**
```
Pick up the most recent failing test, error, or in-progress change visible in the open file or recent diff. Identify the root cause, apply the smallest correct fix, and verify it doesn't regress anything else. If multiple candidates are in scope, pick the most recent one and state what you chose before acting.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

### T9.2 — Weird inputs

**Input:**
```
PLEASE FIX THIS
```

**Output (`rewrite`, 8.6s):**
```
Pick up the most recent failure, error, or broken state visible in this conversation, the open file, or the last test/build output. Identify the root cause, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask which one to address first.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

## All results

### Lazy classics

#### ✅ T1.1 — `expect: rewrite` · 8.0s

**Input:** `fix the login bug`

**Output (`rewrite`):**

```
Investigate the login bug in the current codebase. Identify the failing case — check auth logic, session handling, token validation, or form submission depending on what's relevant — apply a minimal targeted fix, and confirm existing tests still pass. Add a regression test for the specific failure mode you find.
```

#### ✅ T1.2 — `expect: rewrite` · 6.5s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Profile the current code path and identify the top three hotspots by wall time. Propose targeted fixes that preserve existing behavior, prioritize the highest-impact one, and add a benchmark or timing assertion that would catch a future regression.
```

#### ❌ T1.3 — `expect: rewrite` · 6.0s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Write tests for the API. Cover the happy path, common error responses, and authentication paths, with at least one edge case per endpoint. Use the project's existing test framework and patterns. Do not change the API itself.
```

Failures:
- rewrite did not start with an imperative verb

#### ✅ T1.4 — `expect: rewrite` · 6.3s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API and the file's external behavior. Update directly impacted call sites in the same file only. Verify with the existing test suite.
```

#### ✅ T1.5 — `expect: rewrite` · 9.2s

**Input:** `explain this`

**Output (`rewrite`):**

```
Explain the currently selected code or the most relevant section of the open file. Describe what it does, why it exists, and any non-obvious behavior or side effects. If there is no selection, use the file in focus or the most recent diff as context.
```

### Super-short (rewrite even when cryptic)

#### ❌ T2.1 — `expect: rewrite` · 8.4s

**Input:** `fix`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in this conversation, the open file, or the last failing test. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If no concrete failure is in scope, list the candidates you can see and ask which one to address.
```

Failures:
- rewrite did not start with an imperative verb

#### ❌ T2.2 — `expect: rewrite` · 11.9s

**Input:** `help`

**Output (`rewrite`):**

```
Pick up the most recent in-progress task or failure visible in this conversation, the open file, or the working directory. Identify the clearest next step and take it. If the current state is ambiguous, list the candidates you can see and ask which one to address.
```

Failures:
- rewrite did not start with an imperative verb

#### ✅ T2.3 — `expect: rewrite` · 10.1s

**Input:** `wtf`

**Output (`rewrite`):**

```
Investigate the most recent failure, error, or unexpected behavior visible in the current context — open file, last test run, recent diff, or terminal output. Identify the root cause, apply the smallest correct fix, and verify it doesn't regress. If no concrete failure is in scope, list the candidates you can see and ask which one to address.
```

#### ❌ T2.4 — `expect: rewrite` · 8.5s

**Input:** `make it work`

**Output (`rewrite`):**

```
Pick up whatever is currently broken or failing in the open file, recent diff, or last error output. Identify the root cause, apply the smallest correct fix, and verify the fix doesn't introduce regressions. If there are multiple candidates, list them and ask which one to address first.
```

Failures:
- rewrite did not start with an imperative verb

### Cryptic external context (rewrite anyway)

#### ❌ T3.1 — `expect: rewrite` · 8.1s

**Input:** `do the thing we talked about`

**Output (`rewrite`):**

```
Continue the most recent in-progress task from this conversation or the current working directory's recent activity. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask which one to resume.
```

Failures:
- rewrite did not start with an imperative verb

#### ❌ T3.2 — `expect: rewrite` · 8.5s

**Input:** `make it work like the mockup`

**Output (`rewrite`):**

```
Reconcile the current implementation with the most recently-shared mockup. If a mockup file or image is in the workspace or recent attachments, use that as the reference. Apply changes that match the mockup's structure, layout, and visual hierarchy without inventing details. If no mockup is clearly in scope, list what you can find and ask which one is the target.
```

Failures:
- rewrite did not start with an imperative verb

#### ❌ T3.3 — `expect: rewrite` · 10.9s

**Input:** `the usual`

**Output (`rewrite`):**

```
Continue the most recent in-progress task from this conversation, the current working directory, or the open file. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask which one to resume.
```

Failures:
- rewrite did not start with an imperative verb

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 6.0s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Fix the authentication issue currently in scope — check the open file, recent diff, or last failing test to identify what's broken. Apply the smallest correct fix that resolves the failure without changing unrelated behavior. Verify with existing tests and add a regression test for the specific failure mode you find.
```

#### ✅ T4.2 — `expect: rewrite` · 8.9s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Profile the database layer and identify the top bottlenecks by query time or call frequency. Apply targeted fixes — indexes, query rewrites, connection pooling, or caching — using whatever the project already has in place. Verify each change improves performance without breaking existing behavior, and add a benchmark or slow-query log that would catch future regressions.
```

#### ✅ T4.3 — `expect: rewrite` · 8.7s

**Input:** `the api is broken`

**Output (`rewrite`):**

```
Investigate the API issue. Identify which endpoint or call site is failing, reproduce the failure, and apply a minimal fix. Confirm with existing tests — add a regression test for the specific failure mode you find.
```

#### ✅ T4.4 — `expect: rewrite` · 9.3s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Investigate the broken keyboard shortcuts in this app. Identify which bindings are failing to fire, trace the event handling from the trigger to the handler, and apply a minimal targeted fix. Verify the corrected shortcuts work end-to-end and confirm no other bindings were disrupted.
```

#### ✅ T4.5 — `expect: rewrite` · 10.9s

**Input:** `this React thing isn't working`

**Output (`rewrite`):**

```
Investigate the React issue currently in scope — open file, last error in the console, failing test, or recent diff. Identify the root cause, apply the smallest correct fix, and verify the component renders and behaves as expected. If no concrete failure is visible from context, list the candidates you can see and ask which one to address.
```

### Profane / ugly

#### ❌ T5.1 — `expect: rewrite` · 10.2s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps regressing, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence. If no concrete failure is immediately in scope, list the candidates you can see and ask which one to address.
```

Failures:
- rewrite did not start with an imperative verb

#### ✅ T5.2 — `expect: rewrite` · 8.8s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Investigate the form submission handler — the form submits without error but produces no visible side effect. Trace the full submit path: check that the handler fires, that any async call resolves, that state updates or redirects actually execute, and that errors aren't being silently swallowed. Fix the root cause, then verify the happy path end-to-end.
```

#### ❌ T5.3 — `expect: rewrite` · 9.1s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Pick up the most recent failing test, error, or in-progress change visible in the open file or recent diff. Identify the root cause, apply the smallest correct fix, and verify it doesn't regress anything else. If multiple candidates are in scope, pick the most recent one and state what you chose before acting.
```

Failures:
- rewrite did not start with an imperative verb

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 13.2s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Audit the keyboard shortcuts in this app for both correctness (each binding fires reliably from where the UI claims) and usefulness (remove or replace dead, redundant, or confusing bindings). Fix any that are broken or misleading. Then surface a model selection control so the user can switch models from the UI — implement it end-to-end, wired to whatever model config the app already uses. Finally, do a general UI pass: identify and implement tweaks that improve clarity, consistency, or daily usability without introducing new dependencies.
```

#### ✅ T6.2 — `expect: rewrite` · 7.2s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Investigate and fix the bug in the currently open or most recently modified code. Identify the root cause, apply a minimal targeted fix, and add a regression test that would catch the same failure. Write tests for any untested paths exposed by the fix, following the project's existing test patterns and framework. Finally, update the documentation to reflect the corrected behavior — only the sections affected by the change.
```

#### ✅ T6.3 — `expect: rewrite` · 9.6s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Refactor the most recently edited or currently open code for clarity, removing duplication and tightening structure without changing external behavior. Profile the critical path and apply targeted performance improvements to the highest-impact bottlenecks. Add caching at the appropriate layer — memoization, request-level, or persistent — using the project's existing patterns. Verify correctness and performance gains with the existing test suite or a benchmark.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 6.0s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the useAuth hook in hooks/useAuth.ts to replace the useEffect+useState pattern with useReducer. Preserve the public API exactly. Update any affected call sites within the same file only. Verify the refactor with the existing test suite and confirm all tests pass.
```

#### ✅ T7.2 — `expect: rewrite` · 10.2s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a `/healthz` endpoint that returns `200 OK` with a JSON body containing the build SHA and uptime in seconds. Source the build SHA from the environment or build-time injection used elsewhere in the project, and compute uptime from process start time. Follow the existing routing patterns and middleware conventions already in the codebase. Verify the endpoint responds correctly with a quick smoke test or curl.
```

### Code/text dumps

#### ✅ T8.1 — `expect: rewrite` · 11.4s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
Review the pasted `add` function and improve it to match the project's conventions — add type annotations if the codebase uses TypeScript, add a JSDoc comment if the project documents utilities, and add or extend tests if a test file covers this module. Apply all changes in place and verify nothing is broken.
```

#### ✅ T8.2 — `expect: rewrite` · 9.0s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Investigate the `TypeError: Cannot read property 'map' of undefined` — identify which variable is undefined at the call site, trace why it arrives without a value, and apply a minimal fix that guards against the undefined case or ensures the data is always defined before use. Add a targeted test or assertion that would catch this regression.
```

#### ✅ T8.3 — `expect: rewrite` · 7.0s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate this `ConnectionRefusedError` on `server.py` line 42. Identify what `app.run()` is trying to connect to — host, port, or dependent service — and confirm whether that target is running and reachable. Apply the smallest correct fix: start the missing dependency, correct the address configuration, or surface a clearer startup error if the connection is genuinely optional.
```

### Weird inputs

#### ✅ T9.1 — `expect: rewrite` · 6.9s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Investigate the most recently-discussed bug or in-progress fix in this conversation, the open file, or the recent diff. Apply a clean, refined fix that improves the code's clarity along with its correctness, and verify with the existing test suite.
```

#### ❌ T9.2 — `expect: rewrite` · 8.6s

**Input:** `PLEASE FIX THIS`

**Output (`rewrite`):**

```
Pick up the most recent failure, error, or broken state visible in this conversation, the open file, or the last test/build output. Identify the root cause, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask which one to address first.
```

Failures:
- rewrite did not start with an imperative verb

#### ✅ T9.3 — `expect: rewrite` · 5.8s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Fix the button that isn't responding. Identify why the click handler isn't firing — check for event propagation issues, disabled state, overlapping elements, or a misconfigured handler — and apply the smallest correct fix. Verify the button works end-to-end and confirm no related interactions regressed.
```

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 7.6s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate a suspected race condition in the payment processing flow. Audit concurrent code paths — look for shared state, non-atomic read-modify-write operations, missing locks or transaction isolation gaps, and any place where multiple requests could interleave on the same resource. Identify the specific condition under which the race manifests, add appropriate synchronization or transactional guarantees, and write a test that exercises the concurrent path to confirm the fix holds.
```

#### ✅ T10.2 — `expect: rewrite` · 11.4s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate the cold-start regression introduced by the caching layer added last week. Diff the relevant commits to identify what initialization work the cache adds on first load — look for eager hydration, blocking I/O, lock contention, or deferred setup that is now running synchronously at startup. Measure cold-start time before and after the change to confirm the delta, then propose a targeted fix that preserves cache behavior on warm paths without penalizing initialization.
```

#### ✅ T10.3 — `expect: rewrite` · 7.3s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Audit the codebase for all error-handling patterns and identify the three competing approaches. Pick the most consistent, idiomatic one for the project's stack — prefer whichever is already used in the most critical paths or has the best error propagation. Refactor all call sites to use the chosen pattern, removing the other two. Verify the test suite passes after the change.
```
