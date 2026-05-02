# Sharpie eval report

- Model: `haiku` (via Claude Code subprocess, identical flags to ClaudeCodeBackend)
- System prompt: `prompts/sharpen.md` (mtime 2026-05-01 19:44)
- Tests: 34  ·  passed: 32  ·  failed: 2
- Average latency: 15.1s

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
| Code/text dumps | 2 | 1 |
| Weird inputs | 3 | 0 |
| Sophisticated | 3 | 0 |

## Failures (the things that need fixing)

### T1.1 — Lazy classics

**Input:**
```
fix the login bug
```

**Output (`error`, 120.0s):**
```
(empty)
```

**Expected:** `rewrite`  
**Failures:**
- claude exited 124

### T8.1 — Code/text dumps

**Input:**
```
function add(a, b) { return a + b; }
```

**Output (`rewrite`, 21.6s):**
```
I need a request or direction. You've shared code, but no task — nothing to rewrite.

What would you like me to do with this function? (Optimize it, document it, test it, refactor it, etc.)
```

**Expected:** `rewrite`  
**Failures:**
- rewrite did not start with an imperative verb

## All results

### Lazy classics

#### ❌ T1.1 — `expect: rewrite` · 120.0s

**Input:** `fix the login bug`

**Output (`error`):**

```
(empty)
```

Failures:
- claude exited 124

#### ✅ T1.2 — `expect: rewrite` · 10.4s

**Input:** `this is slow`

**Output (`rewrite`):**

```
Profile the current code path and identify the top hotspots by wall time. Propose targeted fixes that preserve behavior, prioritize the highest-impact one, and add a benchmark or timing assertion that would catch a regression.
```

#### ✅ T1.3 — `expect: rewrite` · 8.2s

**Input:** `write tests for the api`

**Output (`rewrite`):**

```
Identify the API endpoints, methods, and handlers in the codebase. Write comprehensive tests covering happy paths, error cases, edge cases, and any authentication or validation logic. Use the project's existing test framework and patterns. Verify all tests pass before committing.
```

#### ✅ T1.4 — `expect: rewrite` · 10.0s

**Input:** `refactor user.ts to use async/await`

**Output (`rewrite`):**

```
Refactor user.ts to replace promise chains and callbacks with async/await. Preserve the public API. Update directly affected call sites in the same file. Verify with the existing test suite.
```

#### ✅ T1.5 — `expect: rewrite` · 11.2s

**Input:** `explain this`

**Output (`rewrite`):**

```
Explain the most recently visible code, error message, design, or concept in this conversation — open file, last error output, pasted snippet, or linked resource. If multiple candidates are in scope, list them and ask the user which one to explain.
```

### Super-short (rewrite even when cryptic)

#### ✅ T2.1 — `expect: rewrite` · 8.8s

**Input:** `fix`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T2.2 — `expect: rewrite` · 9.1s

**Input:** `help`

**Output (`rewrite`):**

```
Identify the user's immediate need from context: the open file, recent error messages, last incomplete task, or last failing test. Summarize what's in scope and ask what the user wants help with, or if unclear, offer the most likely next step.
```

#### ✅ T2.3 — `expect: rewrite` · 8.8s

**Input:** `wtf`

**Output (`rewrite`):**

```
Pick up the most recent failure, error, or broken code visible in the open file, recent test output, or conversation thread. Identify what's wrong, apply the smallest correct fix, and verify it works. If multiple issues are in scope, list them and ask the user which to address first.
```

#### ✅ T2.4 — `expect: rewrite` · 8.0s

**Input:** `make it work`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

### Cryptic external context (rewrite anyway)

#### ✅ T3.1 — `expect: rewrite` · 8.6s

**Input:** `do the thing we talked about`

**Output (`rewrite`):**

```
Continue the most recent in-progress task from this conversation or the current working directory's recent activity. Make the smallest concrete next step that moves it forward. If the most recent thread is ambiguous, list the candidates you can see and ask the user which one to resume.
```

#### ✅ T3.2 — `expect: rewrite` · 16.2s

**Input:** `make it work like the mockup`

**Output (`rewrite`):**

```
Identify the most recent mockup visible in this conversation, open files, or screenshots. Compare it against the current implementation and identify what differs. Apply the minimal changes to make the behavior and appearance match the mockup. If multiple mockups are in scope, list them and ask the user which one to prioritize.
```

#### ✅ T3.3 — `expect: rewrite` · 10.3s

**Input:** `the usual`

**Output (`rewrite`):**

```
Pick up the most recent in-progress task visible in the open file, recent diff, last failing test, or this conversation thread. Make the smallest concrete next step that moves it forward. If multiple candidates are in scope, list them and ask the user which one to resume.
```

### Hallucination traps

#### ✅ T4.1 — `expect: rewrite` · 10.9s

**Input:** `fix the auth thing`

**Output (`rewrite`):**

```
Pick up the most recent authentication issue or in-progress auth task from the open file, recent error messages, recent conversation thread, or recent failing tests. Identify what's broken with the auth flow, apply a minimal fix, and verify the issue is resolved. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T4.2 — `expect: rewrite` · 9.9s

**Input:** `make the database faster`

**Output (`rewrite`):**

```
Profile the database for slow queries or high load. Identify the top bottleneck by query latency, resource usage, or throughput. Propose a minimal fix — indexing, query optimization, caching, or schema adjustment — and verify it improves the benchmark without regressing.
```

#### ✅ T4.3 — `expect: rewrite` · 8.6s

**Input:** `the api is broken`

**Output (`rewrite`):**

```
Investigate the API issue. Identify which call site or endpoint is failing, reproduce the failure with minimal steps, and apply the smallest correct fix. Verify with existing tests.
```

#### ✅ T4.4 — `expect: rewrite` · 19.1s

**Input:** `shortcuts are broken in my app`

**Output (`rewrite`):**

```
Investigate the most recently broken shortcuts. Identify the failing case from the open file, test failures, or error logs. Apply the smallest correct fix and verify existing shortcuts still work. If multiple issues are in scope, list them and ask the user which one to fix first.
```

#### ✅ T4.5 — `expect: rewrite` · 14.3s

**Input:** `this React thing isn't working`

**Output (`rewrite`):**

```
Investigate the React issue visible in the open file, recent error, or last failing test. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which to address first.
```

### Profane / ugly

#### ✅ T5.1 — `expect: rewrite` · 10.4s

**Input:** `ugh this fucking thing again, fix it`

**Output (`rewrite`):**

```
Pick up the recurring issue most recently in scope — open file, last failing test, last error message, or in-progress thread. Identify what keeps breaking, apply a proper fix rather than a workaround, and add a guard or test that would catch the next recurrence.
```

#### ✅ T5.2 — `expect: rewrite` · 8.3s

**Input:** `ok so basically the form like submits but then nothing happens?? help`

**Output (`rewrite`):**

```
Investigate the form submission. Check the browser console for errors, network tab for failed requests, and the form's submit handler in the open files. Identify whether submission succeeds silently, fails silently, or throws an error. Once you locate the failure point, apply the smallest fix and verify the form now produces the expected result.
```

#### ✅ T5.3 — `expect: rewrite` · 13.0s

**Input:** `i don't even know what im looking at anymore just fix it`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task from the open file, last failing test, recent error, or conversation thread. Identify what's broken, apply the smallest correct fix, and add a test or safeguard to prevent regression. If multiple candidates are in scope, list them and ask which one to address.
```

### Multi-task lazy

#### ✅ T6.1 — `expect: rewrite` · 10.5s

**Input:** `are these shortcuts actually useful and do they actually work? Fix that, also what about model selection for the user? And what about the UI features or tweaks?`

**Output (`rewrite`):**

```
Investigate the shortcuts feature — verify they actually function as designed and identify whether the UX makes them discoverable and useful to users. In parallel, identify gaps in model selection (what options does the user see, and are they missing expected choices), and catalog any obvious UI polish issues or feature tweaks that would improve usability. Prioritize by impact and fix the highest-leverage gaps.
```

#### ✅ T6.2 — `expect: rewrite` · 12.9s

**Input:** `fix the bug, write tests, and update the docs`

**Output (`rewrite`):**

```
Investigate and fix the most recent bug visible in open files or test failures. Apply a minimal fix and add a regression test. Expand test coverage for newly exposed paths. Update documentation for sections affected by the change.
```

#### ✅ T6.3 — `expect: rewrite` · 12.7s

**Input:** `refactor and improve performance and add caching`

**Output (`rewrite`):**

```
Profile the current code to identify the top performance bottlenecks. Add caching to the highest-impact path. Refactor any inefficiencies found during profiling. Verify the improvements with a benchmark and confirm no regressions.
```

### Already-good

#### ✅ T7.1 — `expect: rewrite` · 22.5s

**Input:** `Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.`

**Output (`rewrite`):**

```
Refactor the useAuth hook in hooks/useAuth.ts to remove the useEffect+useState pattern in favor of useReducer. Preserve the public API. Update affected callers in the same file. Verify with the existing test suite.
```

#### ✅ T7.2 — `expect: rewrite` · 18.9s

**Input:** `Add a /healthz endpoint that returns 200 OK with a JSON body containing build SHA and uptime in seconds.`

**Output (`rewrite`):**

```
Add a /healthz endpoint that returns 200 OK with a JSON body containing the build SHA and server uptime in seconds.
```

### Code/text dumps

#### ❌ T8.1 — `expect: rewrite` · 21.6s

**Input:** `function add(a, b) { return a + b; }`

**Output (`rewrite`):**

```
I need a request or direction. You've shared code, but no task — nothing to rewrite.

What would you like me to do with this function? (Optimize it, document it, test it, refactor it, etc.)
```

Failures:
- rewrite did not start with an imperative verb

#### ✅ T8.2 — `expect: rewrite` · 21.3s

**Input:** `TypeError: Cannot read property 'map' of undefined`

**Output (`rewrite`):**

```
Investigate the TypeError: Cannot read property 'map' of undefined. Identify which variable or expression is undefined at the .map() call, apply a minimal fix, and verify the error is resolved.
```

#### ✅ T8.3 — `expect: rewrite` · 15.0s

**Input:** `Traceback (most recent call last): /   File "server.py", line 42, in <module> /     app.run() / ConnectionRefusedError: [Errno 61] Connection refused`

**Output (`rewrite`):**

```
Investigate this ConnectionRefusedError on server.py line 42 in the app.run() call. Identify what service or endpoint the app is trying to connect to, confirm whether that dependency should be running, and apply the smallest correct fix — start the dependency, correct the connection address, or surface a clearer error if the connection is optional.
```

### Weird inputs

#### ✅ T9.1 — `expect: rewrite` · 9.2s

**Input:** `🐛 → 🦋`

**Output (`rewrite`):**

```
Investigate the most recently-discussed bug or in-progress fix in this conversation, the open file, or the recent diff. Apply a clean refined fix that improves the code's clarity along with its correctness, and verify with the existing test suite.
```

#### ✅ T9.2 — `expect: rewrite` · 7.6s

**Input:** `PLEASE FIX THIS`

**Output (`rewrite`):**

```
Pick up the most recent failure or in-progress task visible in the open file, last failing test, or recent conversation thread. Identify what's broken, apply the smallest correct fix, and verify it doesn't regress. If multiple candidates are in scope, list them and ask the user which one to address.
```

#### ✅ T9.3 — `expect: rewrite` · 12.0s

**Input:** `fix the bug — el botón no funciona`

**Output (`rewrite`):**

```
Identify the failing button in the open file, most recent diff, or current branch. Reproduce the issue, apply a minimal fix to restore the button's functionality, and verify with existing tests or a manual check that the interaction now works and nothing else regresses.
```

### Sophisticated

#### ✅ T10.1 — `expect: rewrite` · 9.8s

**Input:** `I think there's a race condition somewhere in our payment processing flow but I haven't been able to reproduce it consistently`

**Output (`rewrite`):**

```
Investigate the payment processing flow for race conditions. Look for concurrent writes or reads to shared state (database rows, cache, files, or in-memory data) that aren't properly synchronized or transactional. Check for timing-sensitive assertions in tests or integration tests that might reveal the bug under load. Reproduce with a stress test or load generator hitting the flow concurrently, and if you identify the race, apply the minimal synchronization fix and add a test that reliably surfaces it.
```

#### ✅ T10.2 — `expect: rewrite` · 7.5s

**Input:** `the new caching layer we added last week made cold-start slower somehow, can you figure out why`

**Output (`rewrite`):**

```
Investigate the cold-start regression in the recent caching layer changes. Profile the cold-start execution path to identify the hotspots that have gotten slower, determine what the caching layer is doing during initialization, and propose a targeted fix that preserves the caching benefits without the startup penalty.
```

#### ✅ T10.3 — `expect: rewrite` · 8.6s

**Input:** `the codebase has accumulated 3 different ways to handle errors, pick one and standardize`

**Output (`rewrite`):**

```
Identify the three error handling patterns currently in use across the codebase. Evaluate each for clarity, debuggability, and consistency with existing conventions. Pick the strongest one, then refactor all error handling to use that pattern consistently. Verify with the existing test suite.
```
