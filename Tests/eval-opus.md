# Sharpie eval report

- Model: `opus` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-01 19:59)
- Tests: 34  ·  passed: 34  ·  failed: 0
- Average latency: 7.2s

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

#### ✅ T1.1 — `expect: rewrite` · 7.4s

**Input:** `fix the login bug`

**Output (`rewrite`):**

```
Investigate the login bug. Reproduce the failure, identify the root cause, and apply the smallest correct fix without changing unrelated behavior. Confirm existing tests still pass and add a regression test that covers the specific failure mode.
```

#### ✅ T1.2 — `expect: rewrite` · 7.1s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Profile the current code path and identify the top hotspots by wall time. Propose targeted fixes that preserve behavior, prioritize the highest-impact one, and add a benchmark or timing assertion that would catch a regression.
```

#### ✅ T1.3 — `expect: rewrite` · 7.2s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Write tests for the API covering the public surface — happy paths, error responses, auth and permission checks, validation of required and edge-case inputs, and any pagination, filtering, or rate-limit behavior. Match the project's existing test framework, fixtures, and mocking conventions. Run the suite and confirm all tests pass.
```

#### ✅ T1.4 — `expect: rewrite` · 6.7s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API. Update directly impacted call sites in the same file. Verify with the existing test suite.
```

#### ✅ T1.5 — `expect: rewrite` · 6.7s

**Input:** `explain this`

**Output (`rewrite`):**

```
Explain what the input "this" refers to — the most recently opened file, the highlighted code or selection, the last error message, or the current diff. Summarize what it does at a high level, then walk through the key logic step by step, calling out non-obvious behavior, side effects, and dependencies. If multiple candidates are in scope, list them and ask the user which one to explain.
```

### Super-short (rewrite even when cryptic)

#### ✅ T2.1 — `expect: rewrite` · 6.9s

**Input:** `fix`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.2 — `expect: rewrite` · 7.0s

**Input:** `help`

**Output (`rewrite`):**

```
Clarify what you need help with by anchoring on the current working context — open files, recent diffs, the last command you ran, or the most recent in-progress thread. Identify the most likely task in scope, take the smallest concrete next step, and surface what you did. If multiple candidates are equally plausible, list them and ask the user which one to pursue.
```

#### ✅ T2.3 — `expect: rewrite` · 6.7s

**Input:** `wtf`

**Output (`rewrite`):**

```
Investigate what's currently broken or unexpected — open file, last command output, recent error, or in-progress thread. Identify the specific failure or surprise, explain the root cause in one or two sentences, and propose the smallest correct next step. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.4 — `expect: rewrite` · 7.2s

**Input:** `make it work`

**Output (`rewrite`):**

```
Continue the most recent in-progress task visible in the open file, last failing test, recent diff, or current conversation thread. Identify what's broken or incomplete, apply the smallest correct change to make it work end-to-end, and verify with the existing test suite or a quick runtime check. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Cryptic external context (rewrite anyway)

#### ✅ T3.1 — `expect: rewrite` · 9.1s

**Input:** `do the thing we talked about`

**Output (`rewrite`):**

```
Continue the most recent in-progress task from this conversation or the current working directory's recent activity. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask the user which one to resume.
```

#### ✅ T3.2 — `expect: rewrite` · 7.0s

**Input:** `make it work like the mockup`

**Output (`rewrite`):**

```
Implement the current feature so its visible behavior and layout match the reference mockup most recently in scope — the open design file, latest screenshot, or design link in this conversation. Reconcile spacing, typography, color, component states, and interaction details against the mockup, and update only the code paths needed to close the gap. Verify by comparing the rendered result to the mockup side by side and adjusting until they match.
```

#### ✅ T3.3 — `expect: rewrite` · 7.2s

**Input:** `the usual`

**Output (`rewrite`):**

```
Pick up the most recent in-progress task or unresolved issue visible in the open file, recent diff, last failing test, or current conversation thread. Make the smallest concrete next step that moves it forward and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to resume.
```

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 7.3s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Investigate the auth issue currently in scope — open file, recent diff, last failing test, or most recent error message. Identify the root cause, apply the smallest correct fix, and verify with the existing test suite plus a regression test for the specific failure mode. If multiple auth-related candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T4.2 — `expect: rewrite` · 6.5s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Profile the current database workload and identify the highest-impact bottlenecks — slow queries, missing or unused indexes, N+1 patterns, lock contention, and schema or configuration issues. Apply targeted optimizations in priority order, preserving correctness and existing behavior. Verify each change with before/after measurements on representative queries, and add a benchmark or regression check for the top wins.
```

#### ✅ T4.3 — `expect: rewrite` · 7.8s

**Input:** `the api is broken`

**Output (`rewrite`):**

```
Investigate the API issue. Identify which call site or endpoint is failing, reproduce the failure, apply a minimal fix, and confirm with existing tests.
```

#### ✅ T4.4 — `expect: rewrite` · 6.5s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Investigate why keyboard shortcuts are broken in this app. Reproduce the failure, identify the root cause — event listener registration, focus or scope handling, key matching logic, or conflicts with default browser or OS bindings — and apply a minimal fix. Verify each affected shortcut works and add a regression test for the specific failure mode.
```

#### ✅ T4.5 — `expect: rewrite` · 7.7s

**Input:** `this React thing isn't working`

**Output (`rewrite`):**

```
Investigate the React issue in scope — open file, recent diff, last error message, or in-progress component. Identify what's broken (render failure, state bug, effect loop, prop mismatch, hydration mismatch, build error), reproduce it, apply the smallest correct fix, and verify with the existing test suite. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Profane / ugly

#### ✅ T5.1 — `expect: rewrite` · 6.8s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps breaking, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence.
```

#### ✅ T5.2 — `expect: rewrite` · 7.8s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Investigate why the form submits without producing any visible result. Trace the submit handler end-to-end — confirm the request actually fires, inspect network response status and payload, check for swallowed errors or missing await, and verify the success path updates state, navigates, or renders feedback. Apply the smallest correct fix and add a regression test covering the post-submit behavior.
```

#### ✅ T5.3 — `expect: rewrite` · 6.7s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last error, recent diff, or current conversation thread. Identify what's actually broken, apply the smallest correct fix, and verify it doesn't regress existing behavior. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 8.2s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Audit the keyboard shortcuts in this project — verify each one is wired up, fires the intended action, and isn't shadowed by another binding; remove or fix any that are dead, broken, or redundant. Add a model selection control for the user (surface available models, persist the choice, and apply it to subsequent requests). Then review the UI for missing affordances or rough edges and propose concrete tweaks — list each issue with the file and a minimal fix, and apply the ones that are clear wins.
```

#### ✅ T6.2 — `expect: rewrite` · 5.6s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Investigate and fix the bug — identify the root cause, apply a minimal targeted fix, and add a regression test that would have caught it. Then write tests for any untested paths exposed by the fix. Finally, update the documentation to reflect the corrected behavior; only sections affected by the change.
```

#### ✅ T6.3 — `expect: rewrite` · 8.1s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Refactor the code currently in scope — open file, recent diff, or most recently discussed module — for clarity and structure without changing external behavior. Profile the hot paths, apply targeted performance improvements, and add caching where repeated work or expensive calls justify it; choose a cache strategy (in-memory, memoized, or persistent) appropriate to the call pattern and document invalidation rules. Verify with the existing test suite and add benchmarks or assertions that would catch a regression.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 5.1s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the useAuth hook in hooks/useAuth.ts to replace the useEffect+useState pattern with useReducer. Preserve the public API. Update directly affected call sites in the same file. Verify with the existing test suite.
```

#### ✅ T7.2 — `expect: rewrite` · 6.9s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a /healthz endpoint to this service that responds with HTTP 200 and a JSON body containing the current build SHA and process uptime in seconds. Wire it into the existing router or framework following the project's conventions, source the build SHA from whatever mechanism the project already uses (env var, build-time constant, or git), and compute uptime from process start. Add a test covering the 200 response and the presence and types of both fields.
```

### Code/text dumps

#### ✅ T8.1 — `expect: rewrite` · 7.2s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
Review the provided code. Identify what it does, any correctness or edge-case issues (type coercion with mixed types, undefined or missing arguments, non-numeric inputs, floating-point precision, overflow), and propose a sharper implementation that matches the project's conventions. Add tests covering the happy path and the most likely edge cases.
```

#### ✅ T8.2 — `expect: rewrite` · 7.3s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Investigate this TypeError where `.map` is being called on an undefined value. Locate the call site, trace why the expected array is undefined at that point (missing initial state, async data not yet loaded, failed fetch, or wrong property access), and apply the smallest correct fix — initialize the value as an array, guard the call, or fix the upstream source. Add a regression test covering the undefined case.
```

#### ✅ T8.3 — `expect: rewrite` · 8.1s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate this ConnectionRefusedError raised at server.py line 42 during app.run(). Identify what the app is trying to connect to (host, port, or dependent service), confirm whether that target should be running and reachable, and apply the smallest correct fix — start the dependency, correct the address or port, or surface a clearer error if the connection is genuinely optional. Verify the server starts cleanly afterward.
```

### Weird inputs

#### ✅ T9.1 — `expect: rewrite` · 8.1s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Investigate the most recently-discussed bug or in-progress fix in this conversation, the open file, or the recent diff. Apply a clean refined fix that improves the code's clarity along with its correctness, and verify with the existing test suite.
```

#### ✅ T9.2 — `expect: rewrite` · 6.0s

**Input:** `PLEASE FIX THIS`

**Output (`rewrite`):**

```
Investigate the most recent failure or in-progress issue visible in the open file, last error, recent diff, or active conversation thread. Identify the root cause, apply the smallest correct fix, and verify it does not regress existing behavior. If multiple candidate issues are in scope, list them and ask the user which one to address.
```

#### ✅ T9.3 — `expect: rewrite` · 6.8s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Investigate the non-functional button. Identify which button is in scope from the open file, recent diff, or most recent error, reproduce the failure, and trace the click handler through to whatever it should trigger. Apply the smallest correct fix and add a regression test covering the specific failure mode.
```

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 7.2s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate the suspected race condition in the payment processing flow. Trace the concurrent code paths, identify shared state and ordering assumptions that could fail under interleaving, and reproduce the issue with a targeted stress or concurrency test that exercises the suspected window. Once reproduced, apply a minimal correct fix (locking, idempotency, transactional boundary, or atomic operation as appropriate) and add a regression test that would catch the race deterministically.
```

#### ✅ T10.2 — `expect: rewrite` · 8.6s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate why the caching layer added last week regressed cold-start performance. Compare cold-start timings before and after the change, profile the cold path to identify where the new cache adds overhead (initialization, lookups that always miss, synchronous warmup, lock contention, serialization), and confirm the root cause with measurements rather than assumptions. Apply the smallest fix that restores cold-start performance without losing the warm-path benefits, and add a benchmark or assertion that would catch a future regression.
```

#### ✅ T10.3 — `expect: rewrite` · 6.8s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Audit the codebase to identify the three existing error-handling patterns and where each is used. Pick the strongest pattern based on consistency with the project's conventions, ergonomics, and coverage of failure modes, then refactor all call sites to use it uniformly. Remove the now-unused patterns and any helpers tied to them, and verify with the existing test suite.
```
