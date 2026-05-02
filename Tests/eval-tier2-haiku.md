# Sharpie eval report

- Model: `haiku` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-02 01:26)
- Tests: 34  ·  passed: 34  ·  failed: 0
- Average latency: 10.7s

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

#### ✅ T1.1 — `expect: rewrite` · 9.1s

**Input:** `fix the login bug`

**Output (`rewrite`):**

```
Investigate the login bug. Identify the failing case, apply a minimal fix, and confirm existing tests still pass — add a regression test for the specific failure mode you find.
```

#### ✅ T1.2 — `expect: rewrite` · 11.3s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Identify what's slow — check the open file, recent test output, running application, or recent conversation for the slow operation. Profile or measure it to find the bottleneck. Apply a targeted optimization and verify the improvement with before/after measurements.
```

#### ✅ T1.3 — `expect: rewrite` · 12.5s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Identify the API endpoints and the project's testing framework and patterns by examining the open codebase. Write tests covering the happy path, common edge cases, and error responses for each endpoint. Follow the project's existing test structure and naming conventions. If the scope is ambiguous, list the endpoints or test suites you found and ask the user which to prioritize.
```

#### ✅ T1.4 — `expect: rewrite` · 8.4s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API. Update directly impacted call sites in the same file. Verify with the existing test suite.
```

#### ✅ T1.5 — `expect: rewrite` · 8.7s

**Input:** `explain this`

**Output (`rewrite`):**

```
Identify what's visible in the open file, recent code change, error message, or conversation context. Explain what it does, how it works, and why it matters. Focus on the public API and key concepts. If multiple candidates are in scope, list them and ask the user which one to explain.
```

### Super-short (rewrite even when cryptic)

#### ✅ T2.1 — `expect: rewrite` · 7.7s

**Input:** `fix`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.2 — `expect: rewrite` · 11.5s

**Input:** `help`

**Output (`rewrite`):**

```
Discover what the user is trying to accomplish. Look at the open files, recent context, and available skills and tools. If a clear task is visible (broken test, in-progress feature, recent error), summarize what you see and ask which part to focus on. If context is unclear, ask one direct question about the user's immediate goal — not a menu of options, just the most likely next step.
```

#### ✅ T2.3 — `expect: rewrite` · 10.4s

**Input:** `wtf`

**Output (`rewrite`):**

```
Pick up the most recent failure, error message, broken test, or stuck task visible in the open file or recent conversation. Identify what's wrong, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.4 — `expect: rewrite` · 8.2s

**Input:** `make it work`

**Output (`rewrite`):**

```
Identify the most recent failure, failing test, open error message, or in-progress task visible in your open files or conversation thread. Isolate what's broken, apply the smallest correct fix, and verify existing tests still pass. If multiple candidates exist, list them and ask the user which one to address.
```

### Cryptic external context (rewrite anyway)

#### ✅ T3.1 — `expect: rewrite` · 9.5s

**Input:** `do the thing we talked about`

**Output (`rewrite`):**

```
Identify the most recent task, in-progress work, or decision point from the visible context — open files, git history, recent edits, saved conversation state, or project notes. Clarify what "the thing" refers to, list the candidate interpretation if multiple exist, and ask the user which one to pick up. Then execute it.
```

#### ✅ T3.2 — `expect: rewrite` · 17.7s

**Input:** `make it work like the mockup`

**Output (`rewrite`):**

```
Identify the mockup from your context (open Figma file, recent screenshot, or linked design). Apply targeted changes to match the design — visual styling, layout, interactions, and logic as needed. Verify the implementation matches the mockup exactly.
```

#### ✅ T3.3 — `expect: rewrite` · 10.6s

**Input:** `the usual`

**Output (`rewrite`):**

```
Pick up the most recent in-progress work, last failing test, or recent conversation thread. Identify the natural next step — fix, implement, test, ship, or review — and execute it. If multiple candidates are visible, list them and ask the user which to prioritize.
```

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 10.4s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Pick up the most recent auth-related failure or in-progress issue visible in the open file, test output, or recent conversation. Identify what's broken, apply a minimal fix, and verify it doesn't break existing tests. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T4.2 — `expect: rewrite` · 13.2s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Investigate database performance. Identify the slowest queries or missing indexes by examining the schema and recent code changes. Propose one high-impact, low-risk optimization—a missing index, fixed join, or caching layer. If you need production metrics or query logs to diagnose, ask the user.
```

#### ✅ T4.3 — `expect: rewrite` · 7.8s

**Input:** `the api is broken`

**Output (`rewrite`):**

```
Investigate the API issue. Identify which call site or endpoint is failing, reproduce the failure, apply a minimal fix, and confirm with existing tests.
```

#### ✅ T4.4 — `expect: rewrite` · 12.9s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Investigate the keyboard shortcuts issue. Identify which shortcuts are failing by checking recent code changes, the keybinding configuration, or event handler code. Apply a minimal targeted fix and verify with existing tests or manual spot-checks.
```

#### ✅ T4.5 — `expect: rewrite` · 17.0s

**Input:** `this React thing isn't working`

**Output (`rewrite`):**

```
Investigate the React issue. Check open files, recent errors, failed tests, or browser console output to identify what's broken. Apply the minimal fix and verify it doesn't regress. If multiple candidates are visible, list them and ask which to address first.
```

### Profane / ugly

#### ✅ T5.1 — `expect: rewrite` · 9.5s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps breaking, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence.
```

#### ✅ T5.2 — `expect: rewrite` · 8.5s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Investigate the form submission issue. Identify the form in the open file or most recent work — trace where the submit handler logs output, whether it's making the API call, and whether the response is being received but not displayed. Add console logs to the submit handler and response callback to confirm which step is failing, then apply the minimal fix (wire the missing state update, handler, or callback).
```

#### ✅ T5.3 — `expect: rewrite` · 8.3s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Pick up the most recent failure, failing test, or in-progress task visible in the open file, recent diffs, or conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address first.
```

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 10.4s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Audit the shortcuts visible in the current context — assess whether they actually work, whether they solve real workflows or just clutter the interface, and whether the naming/binding conventions match user expectations. Then address: (1) model selection UI — is it clear and does the user's choice persist? (2) UI refinements — any friction in settings, keybindings, or toggles that should be smoothed out? Flag issues, propose fixes, and ask the user which areas to fix first if multiple candidates are in scope.
```

#### ✅ T6.2 — `expect: rewrite` · 9.8s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Identify the most recent bug from the open file, recent diffs, or failing test. Fix it with a minimal targeted change, add a regression test for that specific failure, write tests for any newly exposed untested paths, and update only the documentation sections affected by the fix. If multiple candidate bugs are in scope, list them and ask the user which to address.
```

#### ✅ T6.3 — `expect: rewrite` · 10.0s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Identify the most performance-critical or frequently-accessed code in the current project — the main request handler, hot path, or most-called function. Review it for refactoring opportunities: simplify logic, reduce branching, eliminate redundant work. Add caching (in-memory or persistent, depending on the data) for expensive operations — database queries, external API calls, or compute-heavy results. Measure before and after with the same workload. Propose the changes and explain the performance wins.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 15.4s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the useAuth hook in hooks/useAuth.ts to replace useEffect+useState with useReducer. Preserve the public API. Update directly affected call sites in the same file. Verify with the existing test suite.
```

#### ✅ T7.2 — `expect: rewrite` · 9.2s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a /healthz endpoint that returns HTTP 200 with a JSON response containing the build SHA and uptime in seconds. Ensure the uptime counter resets on application restart and is accurate within one second.
```

### Code/text dumps

#### ✅ T8.1 — `expect: rewrite` · 7.6s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
Review the provided add function. Identify what it does, any correctness or edge-case issues (type safety, undefined arguments, falsy values, overflow), and propose a sharper implementation that matches your project's conventions. Add tests for the happy path (normal numbers) and the most likely edge cases.
```

#### ✅ T8.2 — `expect: rewrite` · 10.4s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Investigate this TypeError. Identify which variable or return value is undefined when the code tries to call `.map()` on it — check the stack trace, open file, or most recent test failure. Trace why it's undefined at that point, apply a minimal fix, and verify with tests.
```

#### ✅ T8.3 — `expect: rewrite` · 10.1s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate this ConnectionRefusedError in server.py line 42. Identify what the app is trying to connect to (host, port, dependent service, database), confirm whether that target should be running, and apply the smallest correct fix — start the dependency, correct the address, or surface a clearer error if the connection is genuinely optional.
```

### Weird inputs

#### ✅ T9.1 — `expect: rewrite` · 10.9s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Pick up the most recent failure, broken test, or error message visible in the open file, recent git history, or conversation thread. Identify the root cause, apply a minimal correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address first.
```

#### ✅ T9.2 — `expect: rewrite` · 7.7s

**Input:** `PLEASE FIX THIS`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, recent error message, or conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T9.3 — `expect: rewrite` · 8.5s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Investigate the button issue. Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 15.5s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate the race condition in the payment processing flow. Examine the code for concurrent state mutations, timing dependencies, and points where parallel requests could interfere — missing locks, non-atomic operations, transaction isolation issues, or cache invalidation timing. Identify the most likely culprit, propose a minimal fix, and add a test or guard that would catch the condition.
```

#### ✅ T10.2 — `expect: rewrite` · 9.7s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate why the caching layer added last week increased cold-start latency instead of improving it. Profile cold-start before and after that change to identify which initialization or retrieval path was affected, then propose a fix that preserves the caching benefit while restoring performance.
```

#### ✅ T10.3 — `expect: rewrite` · 13.6s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Identify the three error-handling patterns currently scattered through the codebase. Select the most robust and idiomatic approach, then refactor all error handling to use it consistently across all files. Verify the test suite passes.
```
