# Sharpie eval report

- Model: `sonnet` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-01 19:59)
- Tests: 34  ·  passed: 33  ·  failed: 1
- Average latency: 8.0s

Pass = expected behavior matched (rewrite vs clarify) AND all assertions held.

## Tier summary

| Tier | Pass | Fail |
|---|---:|---:|
| Lazy classics | 4 | 1 |
| Super-short (rewrite even when cryptic) | 4 | 0 |
| Cryptic external context (rewrite anyway) | 3 | 0 |
| Hallucination traps | 5 | 0 |
| Profane / ugly | 3 | 0 |
| Multi-task lazy | 3 | 0 |
| Already-good | 2 | 0 |
| Code/text dumps | 3 | 0 |
| Weird inputs | 3 | 0 |
| Sophisticated | 3 | 0 |

## Failures (the things that need fixing)

### T1.5 — Lazy classics

**Input:**
```
explain this
```

**Output (`rewrite`, 10.7s):**
```
Locate the most relevant subject visible in the current context — open file, selected code, recent output, or last conversation thread — and explain it clearly. Cover what it does, why it exists, and any non-obvious behavior worth flagging. If multiple candidates are in scope, list them and ask the user which one to explain.
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

## All results

### Lazy classics

#### ✅ T1.1 — `expect: rewrite` · 6.2s

**Input:** `fix the login bug`

**Output (`rewrite`):**

```
Investigate the login bug visible in the current codebase. Identify the failing case, apply a minimal fix, and confirm existing tests still pass — add a regression test for the specific failure mode you find.
```

#### ✅ T1.2 — `expect: rewrite` · 6.9s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Profile the current code path and identify the top hotspots by wall time. Propose targeted fixes that preserve behavior, prioritize the highest-impact change, and add a benchmark or timing assertion that would catch a regression.
```

#### ✅ T1.3 — `expect: rewrite` · 7.2s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Write tests for the API layer. Identify all routes, handlers, and edge cases visible in the codebase, then generate a comprehensive test suite covering happy paths, error responses, auth failures, and invalid inputs. Mirror the project's existing test conventions and tooling.
```

#### ✅ T1.4 — `expect: rewrite` · 6.7s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API. Update directly affected call sites in the same file. Verify with the existing test suite.
```

#### ❌ T1.5 — `expect: rewrite` · 10.7s

**Input:** `explain this`

**Output (`rewrite`):**

```
Locate the most relevant subject visible in the current context — open file, selected code, recent output, or last conversation thread — and explain it clearly. Cover what it does, why it exists, and any non-obvious behavior worth flagging. If multiple candidates are in scope, list them and ask the user which one to explain.
```

Failures:
- rewrite did not start with an imperative verb

### Super-short (rewrite even when cryptic)

#### ✅ T2.1 — `expect: rewrite` · 6.8s

**Input:** `fix`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.2 — `expect: rewrite` · 6.7s

**Input:** `help`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's blocked or unclear, make the smallest concrete next step that moves it forward, and ask the user to confirm before proceeding if multiple candidates are in scope.
```

#### ✅ T2.3 — `expect: rewrite` · 9.3s

**Input:** `wtf`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.4 — `expect: rewrite` · 11.4s

**Input:** `make it work`

**Output (`rewrite`):**

```
Pick up the most recent failure visible in the open file, last failing test, or recent error output. Identify the root cause, apply the smallest correct fix, and verify it doesn't regress anything. If multiple broken things are in scope, list them and ask the user which to address first.
```

### Cryptic external context (rewrite anyway)

#### ✅ T3.1 — `expect: rewrite` · 9.2s

**Input:** `do the thing we talked about`

**Output (`rewrite`):**

```
Continue the most recent in-progress task from this conversation or the current working directory's recent activity. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask the user which one to resume.
```

#### ✅ T3.2 — `expect: rewrite` · 9.5s

**Input:** `make it work like the mockup`

**Output (`rewrite`):**

```
Pick up the most recent mockup visible in this conversation, open file, or recent diff and implement the UI to match it exactly. Identify gaps between the current implementation and the mockup — layout, spacing, typography, colors, component structure — and apply the necessary changes. If multiple mockups or candidate files are in scope, list them and ask the user which one to target.
```

#### ✅ T3.3 — `expect: rewrite` · 7.3s

**Input:** `the usual`

**Output (`rewrite`):**

```
Pick up the most recent in-progress task or unfinished work visible in the open files, recent conversation, or current working directory. Make the smallest concrete next step that moves it forward. If multiple candidates are in scope, list them and ask which one to resume.
```

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 7.3s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Investigate the most recently touched authentication code in this project. Identify what's broken — failed login, token handling, session expiry, or misconfigured middleware — and apply the smallest correct fix. Verify it doesn't break existing tests; add a targeted regression test for the specific failure you find.
```

#### ✅ T4.2 — `expect: rewrite` · 6.9s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Audit the current database schema, queries, and access patterns for performance bottlenecks. Identify the highest-impact issues — missing indexes, slow queries, N+1 patterns, or schema inefficiencies — and apply targeted fixes. Verify improvements don't break existing functionality.
```

#### ✅ T4.3 — `expect: rewrite` · 5.6s

**Input:** `the api is broken`

**Output (`rewrite`):**

```
Investigate the API issue. Identify which call site or endpoint is failing, reproduce the failure, apply a minimal fix, and confirm with existing tests.
```

#### ✅ T4.4 — `expect: rewrite` · 10.6s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Fix the keyboard shortcuts that are currently broken in the app. Identify which shortcuts are failing — check event listeners, key bindings, handler registration, and any conflicting intercepts — then apply targeted fixes and verify each shortcut works as expected.
```

#### ✅ T4.5 — `expect: rewrite` · 8.7s

**Input:** `this React thing isn't working`

**Output (`rewrite`):**

```
Investigate the most recent React issue visible in the open file, last failing test, or recent error output. Identify the root cause, apply a minimal targeted fix, and verify existing tests still pass — add a regression test if a specific failure mode is confirmed. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Profane / ugly

#### ✅ T5.1 — `expect: rewrite` · 8.6s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps breaking, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence.
```

#### ✅ T5.2 — `expect: rewrite` · 7.8s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Investigate the form submission handler — find where the form submit event is wired up, trace what happens after the handler fires, and identify why no visible action occurs. Check for missing event prevention, silent errors, unhandled promise rejections, or a response that's processed but never reflected in the UI. Apply the smallest fix that makes the submission produce the expected result, and verify no related flows regress.
```

#### ✅ T5.3 — `expect: rewrite` · 7.5s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, recent error output, or active conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 11.3s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Audit the keyboard shortcuts in the current project — verify each one is wired up correctly and actually triggers its intended action, then remove or fix any that are broken or redundant. While in there, implement model selection so the user can switch between available models from the UI. Finally, review the existing UI for low-hanging tweaks: consolidate any inconsistent patterns, tighten spacing, and surface any settings or controls currently buried or missing.
```

#### ✅ T6.2 — `expect: rewrite` · 6.4s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Investigate and fix the bug — identify the root cause, apply a minimal targeted fix, and add a regression test. Write tests for any untested paths exposed by the fix. Update the documentation to reflect the corrected behavior, touching only sections affected by the change.
```

#### ✅ T6.3 — `expect: rewrite` · 8.1s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Refactor the code visible in the current working context for clarity, performance, and caching. Identify the highest-impact hotspots — redundant computation, repeated data fetches, or expensive operations called more than necessary — and apply targeted fixes: memoization, caching layers, or structural refactors where appropriate. Preserve all existing behavior and verify with the existing test suite.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 6.1s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the useAuth hook in hooks/useAuth.ts to replace the useEffect+useState pattern with useReducer. Preserve the public API exactly. Update any call sites within the same file affected by the refactor. Verify correctness with the existing test suite after changes.
```

#### ✅ T7.2 — `expect: rewrite` · 7.5s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a /healthz endpoint that returns HTTP 200 with a JSON body containing the build SHA and uptime in seconds. Read the build SHA from an environment variable at startup and fall back to a placeholder if unset. Calculate uptime from process start time. Wire the route into the existing router without altering any other endpoints.
```

### Code/text dumps

#### ✅ T8.1 — `expect: rewrite` · 5.3s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
Add JSDoc comments and parameter type annotations to this function, then verify it handles edge cases such as non-numeric inputs and returns a meaningful result or throws a descriptive error for invalid arguments.
```

#### ✅ T8.2 — `expect: rewrite` · 7.3s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Investigate the TypeError occurring where `.map` is called on an undefined value. Locate the call site, confirm why the value is undefined at that point — missing data, failed fetch, wrong prop, or timing issue — and apply the minimal fix, adding a guard or default value where appropriate. Verify no existing tests regress and add one if the case was uncovered.
```

#### ✅ T8.3 — `expect: rewrite` · 10.3s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate the ConnectionRefusedError on server.py line 42. Identify what service or address the app is trying to connect to at startup, confirm whether that dependency is running and reachable, and apply the smallest correct fix — either start the required dependency, correct the connection target, or surface a clearer startup error if the dependency is optional.
```

### Weird inputs

#### ✅ T9.1 — `expect: rewrite` · 6.3s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Investigate the most recently-discussed bug or in-progress fix in this conversation, the open file, or the recent diff. Apply a clean refined fix that improves the code's clarity along with its correctness, and verify with the existing test suite.
```

#### ✅ T9.2 — `expect: rewrite` · 8.9s

**Input:** `PLEASE FIX THIS`

**Output (`rewrite`):**

```
Pick up the most recent failure, broken test, or in-progress issue visible in the open file, recent diff, or last error output. Identify the root cause, apply the smallest correct fix, and verify it doesn't regress anything. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T9.3 — `expect: rewrite` · 9.6s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Fix the broken button. Identify which button is unresponsive, trace its event handler or action binding to find the root cause, and apply a minimal targeted fix. Verify the button works end-to-end and that no adjacent interactions regress.
```

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 9.8s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate the payment processing flow for race conditions. Identify any shared state, concurrent writes, or non-atomic operations across async boundaries — especially around order creation, charge attempts, and status updates. Reproduce the issue by reviewing the code paths rather than relying on runtime observation, and propose a fix using locks, idempotency keys, or atomic operations as appropriate. Flag any related code paths that share the same vulnerability.
```

#### ✅ T10.2 — `expect: rewrite` · 9.1s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate why the caching layer added last week is degrading cold-start performance. Identify the initialization path — look for eager loading, blocking setup, or synchronous operations in the cache layer that run before the first request is served. Compare the cold-start code path before and after the change, pinpoint the bottleneck, and propose a targeted fix that preserves cache correctness.
```

#### ✅ T10.3 — `expect: rewrite` · 6.4s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Standardize error handling across the codebase by auditing all three existing patterns, selecting the most consistent and idiomatic one, and refactoring all error-handling code to use it. Remove the other two approaches entirely, update any shared utilities or middleware that implement them, and verify the existing test suite still passes.
```
