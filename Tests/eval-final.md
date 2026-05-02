# Sharpie eval report

- Model: `sonnet` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-01 19:00)
- Tests: 34  ·  passed: 34  ·  failed: 0
- Average latency: 8.8s

Pass = expected behavior matched (rewrite vs clarify) AND all assertions held.

## Tier summary

| Tier | Pass | Fail |
|---|---:|---:|
| Lazy classics | 5 | 0 |
| Super-short (rewrite even when cryptic) | 4 | 0 |
| Cryptic external context (rewrite anyway) | 3 | 0 |
| Hallucination traps | 5 | 0 |
| Profane / ugly | 3 | 0 |
| Multi-task lazy | 3 | 0 |
| Already-good | 2 | 0 |
| Code/text dumps | 3 | 0 |
| Weird inputs | 3 | 0 |
| Sophisticated | 3 | 0 |

## All results

### Lazy classics

#### ✅ T1.1 — `expect: rewrite` · 5.8s

**Input:** `fix the login bug`

**Output (`rewrite`):**

```
Investigate the login bug in the current codebase. Identify the failing case — trace through the auth flow, reproduce the failure, and apply a minimal targeted fix. Verify existing tests still pass and add a regression test covering the specific failure mode you find.
```

#### ✅ T1.2 — `expect: rewrite` · 8.1s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Profile the current code path and identify the top bottlenecks by wall time. Propose targeted fixes that preserve existing behavior, prioritize the highest-impact change, and add a benchmark or timing assertion that would catch a future regression.
```

#### ✅ T1.3 — `expect: rewrite` · 5.8s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Write tests for the API using the project's existing test framework and patterns. Cover the happy path, common error responses, authentication paths, and at least one edge case per endpoint. Do not modify the API itself — add tests only.
```

#### ✅ T1.4 — `expect: rewrite` · 6.3s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API and the file's external behavior. Update directly impacted call sites in the same file only. Verify with the existing test suite.
```

#### ✅ T1.5 — `expect: rewrite` · 12.9s

**Input:** `explain this`

**Output (`rewrite`):**

```
Explain the currently selected code or the focused file in context. Describe what it does, why it works the way it does, and flag any non-obvious logic, side effects, or design decisions worth understanding. If nothing is selected, explain the most recently active or relevant piece of code in scope.
```

### Super-short (rewrite even when cryptic)

#### ✅ T2.1 — `expect: rewrite` · 9.1s

**Input:** `fix`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress existing behavior. If no concrete failure is clearly in scope, list the candidates you can see and ask the user which one to address.
```

#### ✅ T2.2 — `expect: rewrite` · 8.6s

**Input:** `help`

**Output (`rewrite`):**

```
Pick up the most recent in-progress task, error, or open question visible in this conversation or the current working directory. Identify the most actionable next step and either execute it or surface a concrete list of candidates for the user to choose from.
```

#### ✅ T2.3 — `expect: rewrite` · 9.2s

**Input:** `wtf`

**Output (`rewrite`):**

```
Pick up the most recent failure, error, or broken state in this conversation or the current open file. Identify what went wrong, apply the correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask which one to address.
```

#### ✅ T2.4 — `expect: rewrite` · 9.5s

**Input:** `make it work`

**Output (`rewrite`):**

```
Identify what is currently broken or failing in the open file or most recent in-progress task — check for errors, failing tests, or incomplete wiring. Apply the smallest correct fix that makes it work. Verify the fix by running the relevant tests or confirming the behavior end-to-end. If the failure is ambiguous, list the candidates you can see and ask which one to target.
```

### Cryptic external context (rewrite anyway)

#### ✅ T3.1 — `expect: rewrite` · 9.9s

**Input:** `do the thing we talked about`

**Output (`rewrite`):**

```
Continue the most recent in-progress task from this conversation or the current working directory's recent activity. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask which one to resume.
```

#### ✅ T3.2 — `expect: rewrite` · 6.9s

**Input:** `make it work like the mockup`

**Output (`rewrite`):**

```
Reconcile the current implementation with the most recently-shared mockup. If a mockup file or image is in the workspace or recent attachments, use that as the source of truth. Apply changes that match the mockup's structure, layout, and visual hierarchy without inventing details. If no mockup is clearly in scope, list what you can find and ask the user which one is the target.
```

#### ✅ T3.3 — `expect: rewrite` · 9.3s

**Input:** `the usual`

**Output (`rewrite`):**

```
Continue the most recent in-progress task from this conversation, open file, or recent git activity. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask which one to resume.
```

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 7.6s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Investigate the auth issue in the current codebase. Identify the failing path — login, token validation, session handling, or redirect — reproduce the failure, and apply a minimal targeted fix. Verify existing auth-related tests still pass and add a regression test for the specific failure mode you find.
```

#### ✅ T4.2 — `expect: rewrite` · 7.9s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Profile the database layer and identify the top bottlenecks by query time, index usage, and connection overhead. Propose targeted optimizations — missing indexes, query rewrites, caching, or connection pooling — prioritize the highest-impact one, and implement it. Add a benchmark or timing assertion that would catch a future regression.
```

#### ✅ T4.3 — `expect: rewrite` · 6.8s

**Input:** `the api is broken`

**Output (`rewrite`):**

```
Investigate the API issue. Identify which endpoint or call site is failing, reproduce the failure with a minimal case, and apply a targeted fix. Verify the fix with existing tests and add a regression test for the specific failure mode found.
```

#### ✅ T4.4 — `expect: rewrite` · 11.8s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Investigate the broken keyboard shortcuts in this app. Identify which bindings are failing to fire, trace the root cause in the event handling or registration code, and apply a minimal targeted fix. Verify each affected shortcut works end-to-end after the change.
```

#### ✅ T4.5 — `expect: rewrite` · 8.7s

**Input:** `this React thing isn't working`

**Output (`rewrite`):**

```
Investigate the React issue in the current file or most recently modified component. Identify the root cause — whether it's a rendering error, broken hook, prop mismatch, or runtime exception — and apply a minimal targeted fix. Verify the fix doesn't regress adjacent behavior, and add or update a test if one exists for this path.
```

### Profane / ugly

#### ✅ T5.1 — `expect: rewrite` · 8.9s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps breaking, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence.
```

#### ✅ T5.2 — `expect: rewrite` · 8.5s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Investigate the form submission handler that appears to do nothing after submit. Trace the full submit path — event handler, any async calls, state updates, and error boundaries — and identify where execution silently stops or fails. Apply a minimal fix and verify the form completes its intended action end-to-end, adding error logging if the failure was previously swallowed.
```

#### ✅ T5.3 — `expect: rewrite` · 11.4s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Pick up the most recently active file, diff, or failing test in scope and orient from there. Identify the clearest problem — broken behavior, failing assertion, tangled logic, whatever stands out first — apply a focused fix, and leave the code in a state that's easy to reason about. If multiple issues are visible, list them in priority order and fix the most critical one. If scope is genuinely ambiguous, name the candidates you can see and ask which thread to pull.
```

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 14.3s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Audit the keyboard shortcuts in this app for both correctness (each binding fires from where the UI claims) and usefulness (remove or replace dead or redundant bindings). Add a model selection control accessible to the user — surface it where it fits naturally in the existing UI flow. Then identify and implement UI tweaks that improve daily usability, prioritizing the highest-impact changes first.
```

#### ✅ T6.2 — `expect: rewrite` · 6.9s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Investigate and fix the bug in the affected code. Identify the root cause, apply a minimal targeted fix, and add a regression test that would catch the same failure mode recurring. Write tests for any untested paths exposed by the fix, following the project's existing patterns and test framework. Finally, update the documentation to reflect the corrected behavior — only sections directly affected by the change.
```

#### ✅ T6.3 — `expect: rewrite` · 7.7s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Refactor the current code for clarity and performance — identify hotspots, simplify logic, and remove any unnecessary work in critical paths. Add caching where repeated computation or I/O can be avoided, following the project's existing patterns. Preserve all public interfaces and verify correctness with the existing test suite after each change.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 6.0s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the useAuth hook in hooks/useAuth.ts to replace the useEffect+useState pattern with useReducer. Preserve the public API contract exactly. Update only the call sites within the same file. Run the existing test suite to confirm nothing regressed.
```

#### ✅ T7.2 — `expect: rewrite` · 7.3s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a `/healthz` endpoint that returns `200 OK` with a JSON body containing the build SHA and uptime in seconds. Source the build SHA from the environment or the most reliable build-time constant already in use in this project. Source uptime from process start time. Follow existing routing and handler patterns in the codebase. Verify the endpoint responds correctly with a quick smoke test or curl.
```

### Code/text dumps

#### ✅ T8.1 — `expect: rewrite` · 12.8s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
Review the pasted `add` function in context of the surrounding codebase. Identify whether it needs type annotations, error handling, tests, or integration with existing utilities — then apply whichever improvements are warranted by the project's conventions. If the intent is something more specific (rename, extend, replace), check the recent conversation or open file for signals and act on those; otherwise ask which improvement to prioritize.
```

#### ✅ T8.2 — `expect: rewrite` · 7.8s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Investigate the `TypeError: Cannot read property 'map' of undefined`. Trace which variable is undefined at the point `.map` is called, identify why it's not the expected array, and apply a minimal fix — either guard against undefined or fix the upstream source of the value. Add a test or assertion that would catch this class of error on the affected path.
```

#### ✅ T8.3 — `expect: rewrite` · 7.9s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate this ConnectionRefusedError raised in server.py at line 42 when calling `app.run()`. Identify what the app is trying to connect to — the target host, port, or dependent service — and determine whether that dependency is misconfigured, not running, or using the wrong address. Apply the smallest correct fix, and if the connection target is optional, surface a clearer error rather than crashing.
```

### Weird inputs

#### ✅ T9.1 — `expect: rewrite` · 7.0s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Investigate the most recently-discussed bug or in-progress fix in this conversation, the open file, or the recent diff. Apply a clean, refined fix that improves the code's clarity along with its correctness, and verify with the existing test suite.
```

#### ✅ T9.2 — `expect: rewrite` · 8.3s

**Input:** `PLEASE FIX THIS`

**Output (`rewrite`):**

```
Identify the most recent error, failing test, or broken behavior visible in the current context — open files, recent diff, last terminal output, or in-progress thread. Apply the smallest correct fix, preserve surrounding behavior, and verify with existing tests or a quick smoke-test. If multiple candidates are in scope, list them and ask which one to address first.
```

#### ✅ T9.3 — `expect: rewrite` · 6.8s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Fix the button that isn't responding. Identify why the click handler isn't firing — check for event propagation issues, disabled state, overlapping elements blocking the hit target, or a missing/broken event binding. Apply the minimal correct fix and verify the button works as expected across its relevant states.
```

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 12.1s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate a suspected race condition in the payment processing flow. Audit concurrent code paths — look for shared state, non-atomic read-modify-write sequences, missing locks or transaction isolation, and any async operations that assume sequential execution. Since it doesn't reproduce consistently, add structured logging or assertions at the critical sections to surface the interleaving when it does occur, and write a stress or concurrency test that amplifies the timing window. Propose a fix with the minimal footprint needed to make the operation safe under concurrent load.
```

#### ✅ T10.2 — `expect: rewrite` · 13.9s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate why the recently-added caching layer is degrading cold-start performance. Trace the cold-start code path introduced by the caching layer — look for initialization overhead, eager loading, blocking setup work, or serialization that runs unconditionally at startup rather than lazily. Identify the root cause, propose a targeted fix that preserves warm-run cache behavior, and add a timing assertion or benchmark to guard against future regressions.
```

#### ✅ T10.3 — `expect: rewrite` · 8.0s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Audit the codebase for all error-handling patterns and identify the three distinct approaches in use. Pick the most consistent, idiomatic, and widely-used one as the canonical pattern, then refactor all other call sites to match it. Preserve existing error messages and propagation behavior — only the handling mechanism should change. Run the test suite to confirm no regressions.
```
