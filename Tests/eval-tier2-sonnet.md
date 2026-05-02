# Sharpie eval report

- Model: `sonnet` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-02 01:26)
- Tests: 34  ·  passed: 34  ·  failed: 0
- Average latency: 7.5s

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

#### ✅ T1.1 — `expect: rewrite` · 7.8s

**Input:** `fix the login bug`

**Output (`rewrite`):**

```
Investigate the login bug. Identify the failing case, apply a minimal fix, and confirm existing tests still pass — add a regression test for the specific failure mode you find.
```

#### ✅ T1.2 — `expect: rewrite` · 5.7s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Investigate the performance issue. Identify what's slow — profile the relevant code path, pinpoint the bottleneck, and apply a targeted fix. Verify the improvement doesn't regress existing behavior.
```

#### ✅ T1.3 — `expect: rewrite` · 6.6s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Write tests for the API layer in this codebase. Identify all API routes or endpoint handlers, then write unit and integration tests covering the happy path, common error cases, and edge cases for each. Use the testing framework already present in the project; if none exists, pick one that matches the stack. Place tests in the conventional location for this repo.
```

#### ✅ T1.4 — `expect: rewrite` · 7.2s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API. Update directly impacted call sites in the same file. Verify with the existing test suite.
```

#### ✅ T1.5 — `expect: rewrite` · 6.6s

**Input:** `explain this`

**Output (`rewrite`):**

```
Explain what's currently in scope — open file, recent diff, selected code, or last error. Share the specific thing you want explained and I'll sharpen it into a clear prompt.
```

### Super-short (rewrite even when cryptic)

#### ✅ T2.1 — `expect: rewrite` · 6.5s

**Input:** `fix`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.2 — `expect: rewrite` · 6.5s

**Input:** `help`

**Output (`rewrite`):**

```
Rewrite your prompt into a sharper version, ready to paste into another AI tool.

**Just tell me what you want done** — describe the task, paste code, share a URL, drop an error message, or even just a single word. I'll turn it into a clear, actionable prompt for you.
```

#### ✅ T2.3 — `expect: rewrite` · 6.4s

**Input:** `wtf`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.4 — `expect: rewrite` · 7.4s

**Input:** `make it work`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Cryptic external context (rewrite anyway)

#### ✅ T3.1 — `expect: rewrite` · 8.7s

**Input:** `do the thing we talked about`

**Output (`rewrite`):**

```
Pick up the most recent task or in-progress work visible in the open files, recent conversation thread, or last failing test. Identify what needs to be done, execute the next logical step, and report what was completed. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T3.2 — `expect: rewrite` · 7.8s

**Input:** `make it work like the mockup`

**Output (`rewrite`):**

```
Pick up the mockup visible in the current context — open file, shared image, or most recently referenced design — and update the implementation to match it exactly. Align layout, spacing, typography, colors, and component structure to the mockup; preserve all existing logic and data flow. If multiple mockups or implementations are in scope, list the candidates and ask the user which pairing to target.
```

#### ✅ T3.3 — `expect: rewrite` · 7.2s

**Input:** `the usual`

**Output (`rewrite`):**

```
Pick up the most recent task or in-progress work visible in open files, recent conversation thread, or last failing test. Identify what needs to be done next, take the smallest correct step forward, and verify it doesn't break anything. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 9.0s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Investigate the authentication issue currently in scope — open files, recent diffs, failing tests, or error output. Identify the root cause, apply a minimal targeted fix, and verify existing tests still pass. If multiple auth-related candidates are visible, list them and ask the user which one to address.
```

#### ✅ T4.2 — `expect: rewrite` · 5.7s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Investigate the database performance bottlenecks visible in the current codebase — slow queries, missing indexes, N+1 patterns, inefficient schema design, or suboptimal connection handling. Identify the highest-impact issues, apply targeted fixes, and verify nothing regresses.
```

#### ✅ T4.3 — `expect: rewrite` · 4.8s

**Input:** `the api is broken`

**Output (`rewrite`):**

```
Investigate the API issue. Identify which endpoint or call site is failing, reproduce the failure, apply a minimal fix, and confirm with existing tests.
```

#### ✅ T4.4 — `expect: rewrite` · 9.2s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Identify which keyboard shortcuts are broken in the app. Check recent changes to keybinding configuration, event listeners, or shortcut handler code. Determine the root cause and apply a minimal fix, then verify the affected shortcuts work correctly.
```

#### ✅ T4.5 — `expect: rewrite` · 7.7s

**Input:** `this React thing isn't working`

**Output (`rewrite`):**

```
Pick up the most recent React issue visible in the open file, last failing test, or recent error output. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress existing behavior. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Profane / ugly

#### ✅ T5.1 — `expect: rewrite` · 10.8s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps breaking, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence.
```

#### ✅ T5.2 — `expect: rewrite` · 9.0s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Investigate the form submission handler — find where submit is wired up, confirm the handler fires, and trace why no action follows (missing await, swallowed error, silent catch, missing state update, etc.). Apply the smallest correct fix and add a note or test covering the failure case.
```

#### ✅ T5.3 — `expect: rewrite` · 6.5s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are equally likely, list them and ask the user which one to address first.
```

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 9.7s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Audit the keyboard shortcuts, model selection options, and UI configuration features currently available in this project. For each category: verify what is actually wired up and functional, identify anything broken or misleading, and apply fixes. Surface any gaps where expected functionality is missing and implement reasonable defaults.
```

#### ✅ T6.2 — `expect: rewrite` · 7.1s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Investigate and fix the bug — identify the root cause, apply a minimal targeted fix, and add a regression test. Write tests for any untested paths exposed by the fix. Update the documentation to reflect the corrected behavior, touching only the sections affected by the change.
```

#### ✅ T6.3 — `expect: rewrite` · 7.1s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Refactor the relevant code for clarity and maintainability, then profile and improve performance bottlenecks. Add caching where reads are repeated or results are recomputed unnecessarily — use the project's existing caching layer if one exists, otherwise introduce the simplest appropriate mechanism. Preserve all current behavior and verify with the existing test suite.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 6.4s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the useAuth hook in hooks/useAuth.ts to replace its current useEffect+useState pattern with useReducer. Preserve the public API exactly. Update any affected call sites within the same file. Verify the refactor with the existing test suite.
```

#### ✅ T7.2 — `expect: rewrite` · 5.9s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a `/healthz` endpoint that returns HTTP 200 with a JSON body containing the build SHA and uptime in seconds. Derive the build SHA from a `BUILD_SHA` environment variable (falling back to `"unknown"`) and calculate uptime from process start time. Wire the route into the existing server setup following the conventions already in use.
```

### Code/text dumps

#### ✅ T8.1 — `expect: rewrite` · 8.9s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
Review the provided function for correctness and edge cases — consider type coercion, non-numeric inputs, missing arguments, and floating-point behavior. Propose a sharper implementation that matches the project's conventions and add tests covering the happy path and the most likely edge cases.
```

#### ✅ T8.2 — `expect: rewrite` · 8.4s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Investigate the TypeError where `.map()` is called on an undefined value. Identify which variable or API response is undefined at the call site, add a defensive check or default value, and verify the fix handles the null/undefined case without breaking related functionality.
```

#### ✅ T8.3 — `expect: rewrite` · 8.6s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate this ConnectionRefusedError in server.py around line 42. Identify what service or port `app.run()` is trying to connect to, check whether the required dependency is running and reachable, then apply the smallest correct fix — whether that's starting the dependency, correcting the host/port config, or surfacing a clearer startup error if the connection is genuinely optional.
```

### Weird inputs

#### ✅ T9.1 — `expect: rewrite` · 5.9s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Pick up the most recent bug or broken behavior visible in the open file, last failing test, or recent conversation thread. Identify the root cause, apply a clean targeted fix, and verify existing tests still pass — add a regression test for the specific failure if one is missing.
```

#### ✅ T9.2 — `expect: rewrite` · 7.3s

**Input:** `PLEASE FIX THIS`

**Output (`rewrite`):**

```
Fix the most recent error or broken state visible in the open file, last failing test, or recent conversation context. Identify the root cause, apply the smallest correct fix, and verify it doesn't introduce regressions — add a targeted test if the failure mode was untested.
```

#### ✅ T9.3 — `expect: rewrite` · 7.4s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Investigate the broken button. Identify which button is unresponsive, trace the click handler or event binding, and apply a minimal fix. Verify no related interactions regress and add a test for the repaired behavior if a test suite exists.
```

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 8.3s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate the payment processing flow for a race condition that causes inconsistent failures. Identify all shared state, concurrent operations, and non-atomic sequences (read-modify-write, double charges, status transitions) in the flow. Pinpoint the specific code paths where two concurrent requests could interleave to produce incorrect behavior, explain the exact interleave scenario, and propose a fix using locks, atomic operations, idempotency keys, or database-level constraints as appropriate.
```

#### ✅ T10.2 — `expect: rewrite` · 6.8s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate the caching layer added last week and determine why it's slowing down cold-start performance. Look at the recent git history to find the relevant changes, trace the cold-start code path to identify where the new cache introduces latency, and pinpoint the root cause — whether it's eager initialization, blocking I/O, unnecessary serialization, or something else. Propose a targeted fix that restores cold-start speed without removing the caching benefit.
```

#### ✅ T10.3 — `expect: rewrite` · 8.5s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Investigate the codebase and identify the three competing error-handling patterns in use. Pick the most consistent, idiomatic, or widely-adopted one, then refactor all error-handling code to use that single pattern — updating every call site, removing the unused patterns, and ensuring no error paths are silently swallowed or left inconsistent.
```
