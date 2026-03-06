---
name: devtest
description: Spec-Build-Test loop — the user defines a spec, then three agents iterate (Builder implements, Tester validates, Supervisor monitors for freezes) until the result matches. Works for any digital function — UI, APIs, CLI tools, conversational AI, data pipelines, and more.
---

# Design-Test Skill

A general-purpose three-agent feedback loop. The user (Designer) sets the spec, one agent (Builder) implements it, another agent (Tester) validates the result against the spec, and a third agent (Supervisor) monitors for frozen agents and stalled handoffs. They iterate until the Tester confirms the implementation matches. This process applies to **any digital function** — not just visual design.

## Roles

| Role | Who | Responsibility |
|------|-----|----------------|
| **Designer** | The human user | Defines the spec — what "correct" looks like. Has final say. |
| **Builder** | Agent teammate | Implements and refines the code/system to match the Designer's spec. |
| **Tester** | Agent teammate | Validates the result against the spec using appropriate testing methods. Reports discrepancies or approves. |
| **Supervisor** | Agent teammate | Monitors Builder and Tester every 3 minutes. Detects frozen agents, stalled handoffs, and tasks that should have been marked done. Nudges agents to continue or escalates to the team lead. |

## Workflow

```
Designer provides spec
        |
        v
   Builder implements (Round 1)
        |
        v
   Tester validates against spec (Round 1)
        |
    Match? --PASS--> Team lead validates evidence --> Done! Report to Designer
        |
   CONDITIONAL PASS? --> Team lead presents minor issues to Designer
        |                     |
        |               Accept? --YES--> Done!
        |                     |
        |                     NO (continue iterating)
        |                     |
        FAIL  <---------------+
        |
        v
   Tester sends feedback to Builder
        |
        v
   Builder checkpoints, revises (Round N), notifies Tester
        |
        v
   (loop back to Tester - Round N)

   [Supervisor monitors every 3 min throughout]
   [Builder & Tester check Supervisor liveness every 3 rounds]
```

## What Can Be Spec'd and Tested

This skill is not limited to visual design. The Designer can provide any kind of spec:

| Domain | Spec Examples | How the Tester Validates |
|--------|---------------|--------------------------|
| **Visual/UI** | Mockup image, screenshot, `.pen` file, design description | Playwright screenshots, computed style extraction, visual comparison |
| **API/Backend** | Expected request/response pairs, status codes, data shapes | HTTP requests (curl, fetch, Playwright API calls), response validation |
| **Conversational AI** | Expected conversation flows, tone, response quality, tool usage | Send prompts, check responses against expected behavior, validate tool calls |
| **CLI tools** | Expected command outputs, flags, exit codes | Run commands, compare stdout/stderr against expected output |
| **Data pipelines** | Expected input → output transformations, data shapes | Run pipeline, compare output data against expected results |
| **Business logic** | Rules, edge cases, expected outcomes | Write and run test cases, validate outcomes against rules |
| **Accessibility** | WCAG criteria, screen reader behavior | Playwright with accessibility audits, axe-core, keyboard navigation tests |
| **Performance** | Response time targets, bundle size limits | Lighthouse, timing measurements, size checks |

The team lead determines the appropriate testing strategy based on what the Designer provides and instructs the Tester accordingly.

## How to Invoke

The user invokes `/devtest` and provides:

1. **A spec** — what "correct" looks like (image, description, expected behaviors, example I/O, reference URL, etc.)
2. **A target** — the file(s), component(s), endpoint(s), or system to build/modify
3. **Optional context** — tech stack, constraints, how to test the result

If any of these are missing, ask the user before proceeding.

## Step-by-Step Execution

### Step 1: Gather Inputs and Determine Domain

Collect from the user:

- **Spec**: What the result should look like or do. This can be:
  - A local image/mockup (visual)
  - A screenshot or `.pen` file node (visual)
  - A URL to a reference page (visual)
  - Expected API request/response pairs (API)
  - Expected conversation flows or behavior descriptions (conversational AI)
  - Expected command outputs (CLI)
  - Expected data transformations (data pipeline)
  - Business rules and edge cases (logic)
  - A detailed textual description (any domain)
- **Target**: Where to implement — file path(s), endpoint(s), component name, or "new file"
- **Tech stack**: Infer from the project if not specified
- **How to test**: URL, command to run, endpoint to hit, etc. Infer the appropriate testing approach from the domain.

**Determine the domain** from the spec provided. This dictates what tools and methods the Tester will use.

### Step 2: Create the Team and Session Directory

Create a team named `devtest` with yourself as team lead.

**Session namespacing:** Generate a short session slug from the target component or task (e.g., `login-page`, `users-api`, `export-cli`). Create the evidence directory at `devtest-evidence/{session-slug}/` (e.g., `devtest-evidence/login-page/`). All evidence files, `STATE.json`, and Supervisor logs for this session go in this subdirectory. This prevents collisions if multiple devtest sessions run for different tasks.

If a session slug isn't obvious, use the format `session-{YYYYMMDD-HHMM}` (e.g., `session-20260226-1430`).

### Step 3: Create Tasks

Create these tasks in the task list:

1. **"Implement spec"** — assigned to Builder
   - Description: Include the full spec, target files, tech stack, and any constraints from the Designer

2. **"Validate against spec"** — assigned to Tester
   - Description: Include the full spec, how to test the result, and the testing approach for this domain
   - Blocked by task 1 (Builder must implement first)

3. **"Supervise devtest loop"** — assigned to Supervisor
   - Description: "Monitor Builder and Tester agents every 3 minutes. Detect frozen agents, stalled handoffs, forgotten task completion, and circular loops. Nudge agents or escalate to team lead as needed."
   - Not blocked by anything — the Supervisor starts immediately and runs continuously

### Step 4: Spawn Teammates

Spawn exactly **three** teammates:

#### Builder (subagent_type: `general-purpose`)

Prompt must include:
- The full spec from the Designer
- Target file(s) to create or modify
- Tech stack and constraints
- Instruction: "You are the **Builder** in a spec-build-test loop. Your job is to implement code that satisfies the Designer's spec. After your initial implementation, the Tester will validate and send you feedback. When you receive feedback, revise the code and notify the Tester to re-check. Keep iterating until the Tester approves."
- Instruction: "**Read the reference yourself before Round 1.** Don't work blind from a textual description alone. If the spec includes a reference image, mockup, or example output, read/view it directly using the Read tool before you start implementing. Understanding the target visually (or concretely) will produce a much better initial implementation and help you interpret the Tester's feedback accurately."
- Instruction: "**Number every round.** Your initial implementation is Round 1. Each revision after Tester feedback increments the round number. Label every message to the Tester: 'Round N: <what changed>, ready for re-testing.'"
- Instruction: "**Acknowledge every feedback item.** When you receive FAIL feedback from the Tester, respond to EACH item explicitly before starting revisions. For every issue listed, state one of: `FIXED: <what you did>`, `DEFERRED: <why you're tackling it in a later round>`, or `NEEDS CLARIFICATION: <what's unclear>`. Do not silently skip items — the Tester will just re-report them, wasting a round."
- Instruction: "After each revision, send a message to the Tester saying what you changed and that it's ready for re-testing."
- Instruction: "**Commit a checkpoint before each revision.** Before making changes based on Tester feedback, commit the current state: `git add -A && git commit -m 'checkpoint: devtest round N before revisions'`. This gives you a clean rollback point."
- Instruction: "**Rollback if a revision makes things worse.** If the Tester reports MORE failures after your revision than the previous round had, revert to your last checkpoint (`git checkout .`) and try a different approach instead of fixing forward on a broken state. Tell the Tester: 'Round N revision made things worse — rolled back to checkpoint, trying a different approach.'"
- Instruction: "**If the spec is ambiguous or contradictory**, do NOT guess. Escalate to the team lead: 'CLARIFICATION NEEDED: <describe what's unclear about the spec>'. The team lead will ask the Designer and relay the answer."
- Instruction: "Do NOT mark your task as completed until the Tester has approved the implementation."
- Instruction: "**For frontend bugs: you MUST verify your fix in the browser before notifying the Tester.** After deploying your fix, write a quick Playwright smoke test that reproduces the user's bug scenario and confirms it's now fixed. If Playwright still shows the old behavior, your fix is wrong — investigate further. Do NOT send 'ready for testing' based on reading code alone. 'The code looks correct' has been wrong repeatedly. The browser is the only source of truth."
- Instruction: "A Supervisor agent will check in on you periodically. If they ask for a status update, reply with your current round number and what you're doing. If they tell you to take action, follow their instructions."
- Instruction: "**Supervisor health check.** Every 3 rounds (after Rounds 3, 6, 9, etc.), send a message to the Supervisor: 'Builder checking in — are you still monitoring? Current round: N.' If the Supervisor does not reply within 3 minutes, escalate to the team lead: 'ALERT: Supervisor appears unresponsive — no reply to my check-in after Round N.' This ensures the Supervisor hasn't silently frozen while the loop continues unmonitored."
- Instruction: "**Context window awareness.** If you sense you are approaching your context limit (very long conversation, many rounds of feedback), proactively write a handoff summary to `devtest-evidence/STATE.json` with: current round number, what you've implemented so far, what the last Tester feedback was, which files you've modified, and your planned next approach. Then notify the team lead: 'CONTEXT LIMIT: I've saved my state to STATE.json. A fresh Builder agent may need to take over.' Do this BEFORE you run out of context — don't wait until you can no longer respond."

#### Tester (subagent_type: `general-purpose`)

Prompt must include:
- The full spec from the Designer so they know what "correct" looks like
- How to test the result (URL, command, endpoint, file path, etc.)
- The testing approach determined by the team lead (see Testing Methods below)
- Instruction: "You are the **Tester** in a spec-build-test loop. Your job is to validate the Builder's implementation against the Designer's spec. Be specific and actionable in your feedback."
- Instruction: "**Number every round.** Your first test is Round 1. Each re-test after Builder revisions increments the round number. Label every verdict: 'Round N verdict: PASS / FAIL / CONDITIONAL PASS'."
- Instruction: "For each test round, produce a verdict:"
  - **PASS** — The implementation fully satisfies the spec. Report to the team lead that the result is approved.
  - **CONDITIONAL PASS** — The implementation substantially matches the spec (90%+) but has minor remaining discrepancies that may not be worth additional rounds. List the remaining issues with severity labels (MINOR/COSMETIC). Report to the team lead so the Designer can decide whether to accept or continue iterating.
  - **FAIL** — List specific discrepancies between the implementation and the spec. Be precise and measurable. **Rank each issue by severity: CRITICAL (structural/functional, blocks other fixes), MAJOR (significant mismatch), or MINOR (cosmetic/polish).** The Builder should address CRITICAL issues first, then MAJOR, then MINOR. Send this feedback directly to the Builder.
- Instruction: "After sending FAIL feedback to the Builder, wait for them to message you that revisions are ready, then re-test."
- Instruction: "**Incremental testing.** After Round 1, you don't need to re-test everything from scratch every round. Focus your effort on: (1) the previously-failing criteria that the Builder claims to have fixed, (2) a spot-check of 2-3 previously-passing criteria to catch regressions. Only do a full re-test if the Builder made sweeping changes or if a regression is detected. This saves time on large specs."
- Instruction: "**Track regression.** After each test round, compare the number and severity of failures against the previous round. If a revision introduced MORE failures than the previous round, flag it in your verdict: 'REGRESSION DETECTED: Round N has X failures vs Round N-1's Y failures. Builder should consider rolling back.'"
- Instruction: "There is no round limit — keep iterating until the implementation matches the spec. However, if you notice the same discrepancies persisting across 3 consecutive rounds with no meaningful improvement, escalate to the team lead. Describe what's stuck and what you've already tried so the team lead can intervene or consult the Designer."
- Instruction: "**BEFORE your first test**, read the reference/spec material (image, expected output, etc.) carefully. For visual specs, use the Read tool on the reference image. You cannot judge whether something matches if you haven't studied what it's supposed to match."
- Instruction: "**Re-read the reference every 3 rounds.** On rounds 4, 7, 10, etc., re-read the original spec/reference material before testing. This prevents spec drift — where you start judging against your memory of the spec rather than the spec itself."
- Instruction: "**Every verdict MUST include measurements.** For visual tests: extract element positions, sizes, font sizes, and spacing — then compare against the reference proportionally. For API tests: include actual response bodies. For CLI tests: include actual stdout. A verdict of PASS with no supporting data is invalid — the team lead will reject it."
- Instruction: "**If the spec is ambiguous or contradictory**, do NOT guess or silently interpret. Escalate to the team lead: 'CLARIFICATION NEEDED: <describe what's unclear about the spec>'. The team lead will ask the Designer and relay the answer. Do not PASS or FAIL on ambiguous criteria."
- Instruction: "**Evidence naming convention.** Save ALL evidence artifacts to `devtest-evidence/` using the format: `round-{N}-{description}.{ext}`. Examples: `round-1-fullpage.png`, `round-3-canvas.png`, `round-5-api-response.json`, `round-7-measurements.json`. Never use ad-hoc names. This makes it easy to track progress across rounds and review the history."
- Instruction: "**Pre-flight check.** Before Round 1, verify the environment is ready (see Step 5: Pre-Flight Check). If the environment check fails, report to the team lead BEFORE entering the test loop."
- Instruction: "A Supervisor agent will check in on you periodically. If they ask for a status update, reply with your current round number and what you're doing. If they tell you to take action, follow their instructions."
- Instruction: "**Supervisor health check.** Every 3 rounds (after Rounds 3, 6, 9, etc.), send a message to the Supervisor: 'Tester checking in — are you still monitoring? Current round: N.' If the Supervisor does not reply within 3 minutes, escalate to the team lead: 'ALERT: Supervisor appears unresponsive — no reply to my check-in after Round N.' This ensures the Supervisor hasn't silently frozen while the loop continues unmonitored."
- Instruction: "**Context window awareness.** If you sense you are approaching your context limit (very long conversation, many rounds of testing), proactively write a handoff summary to `devtest-evidence/STATE.json` with: current round number, which spec criteria are passing/failing, the last verdict details, what testing approach you're using, and any patterns you've noticed. Then notify the team lead: 'CONTEXT LIMIT: I've saved my state to STATE.json. A fresh Tester agent may need to take over.' Do this BEFORE you run out of context — don't wait until you can no longer respond."
- **Domain-specific testing instructions** (see Testing Methods below — the team lead selects and includes the relevant section)

#### Supervisor (subagent_type: `general-purpose`)

The Supervisor is a watchdog agent that prevents the Builder and Tester from freezing or stalling. It runs alongside the other two agents for the entire duration of the devtest loop.

Prompt must include:
- The names of the Builder and Tester teammates
- The task IDs for "Implement spec" and "Validate against spec"
- Instruction: "You are the **Supervisor** in a spec-build-test loop. Your job is to monitor the Builder and Tester agents and ensure the loop keeps moving. You do NOT build or test anything yourself."
- Instruction: "**Every 3 minutes**, perform a health check by doing ALL of the following:"
  1. "Check the task list — look at task statuses and when they were last updated."
  2. "Send a message to the Builder asking: 'Status check — what are you currently working on?' Wait for a reply."
  3. "Send a message to the Tester asking: 'Status check — what are you currently working on?' Wait for a reply."
  4. "If either agent does NOT reply within 2 minutes, send them a follow-up message: 'You appear to be idle. Please continue your work or report what's blocking you.'"
  5. "If an agent still doesn't respond after the follow-up, escalate to the team lead: 'ALERT: [Builder/Tester] appears frozen — no response after two check-in attempts.'"
- Instruction: "**Detect stalled handoffs.** If the Builder has sent a 'ready for testing' message but the Tester hasn't started testing within 3 minutes, nudge the Tester: 'The Builder has finished revisions and is waiting for you to test. Please begin your validation.'"
- Instruction: "**Detect forgotten task completion.** If the Tester has sent a PASS verdict but neither agent has marked their tasks as completed within 3 minutes, nudge both agents: 'The Tester has approved the implementation. Please mark your tasks as completed.'"
- Instruction: "**Detect circular loops.** If you observe the same FAIL feedback being sent back and forth more than 8 times with no meaningful change in the feedback content, escalate to the team lead: 'ALERT: Builder and Tester appear stuck in a loop — same feedback repeating across rounds.'"
- Instruction: "**Detect deadlocks.** If both agents respond to your check-in but both say they are 'waiting for the other agent' (or neither has messaged the other for 10+ minutes), break the deadlock. Determine whose turn it is based on the last message exchange — if the Builder last sent 'ready for testing', tell the Tester to start testing. If the Tester last sent FAIL feedback, tell the Builder to start revising. If unclear, tell the Builder to send a status update to the Tester."
- Instruction: "**Detect silent Builder.** During each check-in, run `git diff --stat` in the project directory. If there are uncommitted file changes but the Builder has NOT sent a 'ready for testing' message to the Tester, nudge the Builder: 'You appear to have made code changes but haven't notified the Tester. If your revisions are ready, send a message to the Tester so they can re-test.'"
- Instruction: "**Detect evidence gaps.** During each check-in, check whether the `devtest-evidence/` directory has new files since the last check-in (use `ls -lt devtest-evidence/ | head -5`). If the Tester has run test rounds but no new evidence files have appeared, nudge the Tester: 'You appear to be testing without saving evidence artifacts to devtest-evidence/. Every test round must save screenshots, logs, or other evidence. Please save your test output before continuing.'"
- Instruction: "**Git checkpoint reminder.** During each check-in, run `git log --oneline -1 --format=%ar` to check when the last commit was made. If 15+ minutes have passed since the last commit AND there are uncommitted changes (check via `git status --porcelain`), nudge the Builder: 'You have been working for 15+ minutes without committing. Please make a checkpoint commit to avoid losing work: git add -A && git commit -m \"checkpoint: devtest progress\"'"
- Instruction: "**Detect ineffective rounds.** After each Tester verdict, read the verdict message content. If the Tester reports that a round produced no visible change or identical results to the previous round despite the Builder claiming to have made fixes, this is a CRITICAL signal — do NOT treat it as a normal FAIL. Escalate immediately to the team lead with: 'ALERT: Builder's Round N changes had no observable effect. This likely means the Builder is modifying the wrong layer, wrong file, wrong data structure, or the change isn't reaching the rendering path. The team lead should investigate the data flow before another round is wasted.'"
- Instruction: "**Read test evidence between rounds.** Don't just check agent liveness — after each Tester verdict, read the latest evidence screenshot or test output from `devtest-evidence/{session-slug}/`. Compare it visually or structurally against the previous round's evidence. If they are identical or near-identical, flag it even if the Tester doesn't explicitly call it out."
- Instruction: "**Detect wrong-layer fixes.** If the Builder reports changing database values, config, or backend data but the Tester sees no frontend change, suggest the team lead investigate whether: (1) the frontend is caching stale data, (2) the rendering code doesn't read from where the Builder wrote, (3) the data is stored in a different field/table than the Builder modified, or (4) a container restart is needed to pick up DB changes."
- Instruction: "**Track round-over-round delta.** Maintain a log in `STATE.json` under a `roundHistory` key: for each round, record the Builder's claimed change and the Tester's verdict summary. If two consecutive rounds have the same verdict summary (e.g., 'title overlaps image, no gap'), escalate: 'ALERT: Rounds N-1 and N have identical failure descriptions. The Builder's approach is not addressing the root cause. Team lead should intervene with architectural guidance.'"
- Instruction: "**Use `sleep 180` (3 minutes) between each health check cycle.** Do not check more frequently than every 3 minutes — the agents need time to work."
- Instruction: "**Maintain the state file.** After each health check cycle, update `devtest-evidence/STATE.json` with the current loop state. Format: `{ \"round\": N, \"builderStatus\": \"...\", \"testerStatus\": \"...\", \"lastVerdict\": \"PASS|FAIL|CONDITIONAL PASS\", \"passingCriteria\": [...], \"failingCriteria\": [...], \"roundHistory\": [{\"round\": N, \"builderChange\": \"...\", \"verdictSummary\": \"...\"}], \"lastUpdated\": \"ISO timestamp\" }`. This file enables the loop to resume if the team lead's context resets."
- Instruction: "**Continue running until the team lead shuts you down.** Do not mark your own task as completed or stop checking. You run for the entire duration of the devtest session."
- Instruction: "**Respond to agent check-ins promptly.** The Builder and Tester will periodically send you a check-in message to verify you are still active. When you receive one, reply immediately with your current status: last check-in time, current observations, and any concerns. Failing to respond will cause them to escalate to the team lead that you are frozen."
- Instruction: "**Acknowledge shutdown explicitly.** When the team lead tells you to shut down, reply with: 'SUPERVISOR SHUTTING DOWN — acknowledged.' Then mark your task as completed. Do NOT go silent without acknowledging — the team lead needs confirmation that you received the shutdown command and are stopping cleanly."
- Instruction: "Keep a brief log of each check-in cycle. Format: `[HH:MM] Builder: <status> | Tester: <status> | Issues: <none or description>`"

### Step 5: Pre-Flight Check

Before the loop begins, the Tester must verify the environment is ready. This prevents wasting early rounds on infrastructure problems.

The Tester performs these checks **before Round 1 testing** (include in the Tester's prompt):

- **For visual/UI tests**: Navigate to the target URL and confirm the page loads (HTTP 200, no blank screen). If using Playwright, confirm it's installed and the browser launches.
- **For API tests**: Send a basic health-check request (GET / or a known endpoint) to confirm the server is reachable and responding.
- **For CLI tests**: Confirm the target script exists and is executable. Run `--help` or a no-op invocation to verify it starts.
- **For all domains**: Confirm the `devtest-evidence/` directory exists (create it if not). Confirm git is clean or has a known starting state.

If the pre-flight check fails, the Tester sends the failure details to the team lead **before entering the test loop**. The team lead resolves the environment issue (or asks the Designer) before proceeding. Do NOT start Round 1 testing against a broken environment.

### Step 6: Monitor the Loop

> **Resuming a devtest loop?** If you are starting a new session and `devtest-evidence/STATE.json` exists, read it first. It contains the current round, what's passing/failing, and agent state from the previous session. Use this to pick up where the loop left off rather than starting from Round 1.

As team lead:

1. Let the Builder implement, the Tester validate, and the Supervisor watch over both.
2. The two agents message each other directly — Builder sends "Round N: ready for testing" and Tester sends a numbered verdict (PASS / CONDITIONAL PASS / FAIL with feedback).
3. **The Supervisor handles routine liveness monitoring.** It checks in on both agents every 3 minutes, detects stalled handoffs, and nudges idle agents. The team lead no longer needs to manually poll for stalled agents — the Supervisor will escalate if there's a problem.
4. **Designer progress updates.** Every 5 rounds, send the Designer (user) a brief status update:
   - Current round number
   - What's passing / what's still failing
   - Whether progress is being made or the loop is stalling
   - Estimated closeness to completion (e.g., "3 of 8 spec criteria now passing")
   This lets the Designer intervene early, adjust the spec, or accept a CONDITIONAL PASS without waiting for the loop to complete or stall.
5. **Respond to Supervisor escalations.** The Supervisor will alert you if:
   - An agent appears frozen (no response to two check-in attempts)
   - The Builder and Tester are stuck in a circular loop (same feedback repeating 8+ times)
   - A stalled handoff isn't resolving after a nudge
   - A deadlock where both agents are waiting for each other
   - The Builder is making changes without notifying the Tester
   - The Tester is testing without saving evidence to `devtest-evidence/`
   - The Builder hasn't committed in 15+ minutes with uncommitted changes
   - The Builder's changes had no observable effect (wrong layer / wrong file / data not reaching render path)
   - Two consecutive rounds have identical failure descriptions (Builder not addressing root cause)
   When escalated, intervene by reviewing the situation, sending direct instructions to the stuck agent, adjusting the approach, or consulting the Designer. For wrong-layer/ineffective-round alerts specifically: investigate the data flow yourself before letting the Builder try again — check whether the Builder is modifying the right file, whether the frontend reads from the right data source, and whether a restart is needed.
6. **Respond to spec clarification requests.** If the Builder or Tester escalates a "CLARIFICATION NEEDED" about an ambiguous or contradictory part of the spec, present the question to the Designer and relay their answer back to the requesting agent.
7. **Validate every PASS or CONDITIONAL PASS before accepting it.** When the Tester sends a PASS or CONDITIONAL PASS:
   - **Check for evidence.** Does the verdict include concrete data? For visual tests: a measurement table with positions, sizes, and proportional comparisons. For API tests: actual response bodies. For CLI tests: actual stdout/stderr. A verdict with no supporting data is invalid — reject it and tell the Tester to re-test with proper measurements.
   - **Check the evidence quality.** "Elements exist" is not evidence. The Tester must show that the implementation matches the spec *proportionally and quantitatively*. If the measurement table only has trivial checks (e.g., "button exists: YES"), reject it and tell the Tester to measure positions, sizes, fonts, colors, and spacing.
   - **Spot-check the screenshots yourself** (for visual tests). Read the Tester's screenshot and the reference image. If something is visibly wrong that the Tester missed, reject the verdict and send specific feedback about what doesn't match.
   - **For CONDITIONAL PASS**: Present the remaining minor issues to the Designer. Let them decide: accept as-is, or continue iterating. If they accept, treat it as a PASS.
   - Only after confirming the evidence is thorough and credible should you accept the verdict.
8. Monitor for:
   - **Tester stall escalation**: If the Tester reports the same issues persisting across 3 consecutive rounds with no progress, they will escalate. Intervene by reviewing the remaining discrepancies, adjusting the approach, or asking the Designer for guidance.
   - **Regression alerts**: If the Tester flags that a revision introduced more failures than the previous round, tell the Builder to roll back to their checkpoint and try a different approach.
   - **Supervisor escalations**: Handle any frozen-agent or circular-loop alerts from the Supervisor (see point 5 above).
   - **Context limit alerts**: If any agent reports "CONTEXT LIMIT" and says they've saved state to `STATE.json`, spawn a fresh replacement agent of the same type. Include in the new agent's prompt: "You are replacing a previous [Builder/Tester] that hit its context limit. Read `devtest-evidence/STATE.json` for the current loop state and continue from where they left off. Current round: N."
   - **Supervisor unresponsive alerts**: If the Builder or Tester escalates that the Supervisor didn't respond to their check-in, investigate immediately. Send a message to the Supervisor yourself. If the Supervisor doesn't reply within 2 minutes, it has frozen — stop it and spawn a fresh Supervisor with the same prompt, including: "You are replacing a previous Supervisor that became unresponsive. Read `devtest-evidence/STATE.json` for the current loop state and resume monitoring from there."
9. The loop runs until the Tester passes with adequate evidence, the Designer accepts a CONDITIONAL PASS, or the Tester escalates a stall. There is no arbitrary round limit — the goal is to match the spec.
10. When a validated PASS is received or the user accepts the result, shut down all three teammates (Builder, Tester, and Supervisor). **Send each agent a shutdown message and wait for their acknowledgement before stopping them.** The Supervisor in particular must reply with 'SUPERVISOR SHUTTING DOWN — acknowledged.' If any agent doesn't acknowledge within 2 minutes, stop them forcefully and note it. Then clean up the team.

### Step 7: Report to the Designer

When the loop completes, present to the user:

- Summary of what was implemented
- Number of iterations it took
- Any compromises or known deviations from the spec
- The final file(s) modified
- Evidence collected during testing (screenshots, test output, logs)

## Testing Methods by Domain

The team lead determines the domain from the spec and includes the appropriate testing instructions in the Tester's prompt. The Tester should use the most concrete, measurable validation available.

### Visual/UI Testing

Primary tool: **Playwright**

**CRITICAL: "Element exists" is NOT a pass.** Visual testing requires **proportional measurement** — verifying that elements are the right size, in the right position, and match the reference layout. A test that only checks "is the button present?" without verifying its position, size, and relationship to neighboring elements is worthless.

#### Step 1: Read the Reference
Before testing anything, the Tester MUST **read the reference image** (using the Read tool on the image file). Study it carefully. Identify every distinct visual element, its approximate proportional position (% of container width/height), and its relationship to neighboring elements.

#### Step 2: Capture the Live Result
- Navigate to the target URL with Playwright
- Take screenshots with `page.screenshot()` — both full-page and targeted element screenshots
- Save to `devtest-evidence/` using the naming convention: `round-{N}-{description}.{ext}` (e.g., `round-1-fullpage.png`, `round-3-canvas.png`, `round-5-api-response.json`). Consistent naming is mandatory — see Evidence Naming Convention below.

#### Step 3: Extract Measurements
Do NOT just eyeball the screenshot. Extract concrete data:
- **DOM/Canvas measurements**: Use `page.evaluate()` to extract element positions, sizes, and styles from the DOM or canvas library (e.g., Konva `stage.find()`, CSS `getBoundingClientRect()`)
- **Computed styles**: font sizes, colors, padding, margins via `window.getComputedStyle()`
- **Proportional positions**: Calculate each element's position as a percentage of its container (e.g., "circle center at 11.5% from left, 40.7% from top")

#### Step 4: Compare Proportionally
For each element, compare the live measurement against the reference:
- **Position**: Is it in the same proportional location? (within ~2-3% tolerance)
- **Size**: Is it the same proportional size? (within ~10% tolerance)
- **Relationships**: Do elements maintain the same spatial relationships? (e.g., "text starts 40px to the right of circle edge", "circle is vertically centered in card with 0px offset")
- **Typography**: Do font sizes, weights, and families match?
- **Colors**: Do fill colors, stroke colors, and backgrounds match?
- **Spacing**: Are gaps between elements proportionally correct?

#### Verdict Format for Visual Tests
Every PASS or FAIL must include a **measurement table** like:

```
| Element | Property | Reference | Live | Match? |
|---------|----------|-----------|------|--------|
| Circle 1 | center Y vs card center | centered | +0px offset | YES |
| Title 1 | Y position | aligned with circle top | 55px below card top | YES |
| Body text | font size | ~14px | 14px | YES |
| Diamond | aspect ratio | 1:1 square | 1.0 | YES |
```

A PASS without this table is invalid.

If Playwright is not installed: `npm init -y && npm install playwright && npx playwright install chromium`

### API/Backend Testing

Primary tools: **curl, Playwright API context, or Python requests**

- Send HTTP requests to the target endpoints
- Validate response status codes, headers, and body structure
- Compare response data against expected shapes and values from the spec
- Test error cases and edge cases specified by the Designer
- Check authentication/authorization if relevant
- Log request/response pairs as evidence

What to verify: status codes, response body shape, data correctness, error handling, headers, latency.

### Conversational AI Testing

Primary tools: **Direct interaction, API calls, or scripted prompts**

- Send the specified prompts/conversation flows to the AI system
- Capture responses verbatim
- Compare responses against expected behavior (tone, content, tool usage, accuracy)
- Test edge cases (adversarial inputs, ambiguous queries, multi-turn flows)
- Validate tool calls if the AI is expected to use tools
- Log full conversation transcripts as evidence

What to verify: response quality, tone, accuracy, tool usage, conversation flow, edge case handling.

### CLI Tool Testing

Primary tools: **Bash execution**

- Run the specified commands with expected arguments
- Capture stdout, stderr, and exit codes
- Compare against expected outputs from the spec
- Test flag combinations, error conditions, and help text
- Log command outputs as evidence

What to verify: stdout/stderr content, exit codes, flag behavior, error messages, help text.

### Data Pipeline Testing

Primary tools: **Script execution, file comparison**

- Run the pipeline with the specified input data
- Capture output data
- Compare output against expected transformations from the spec
- Check data types, shapes, edge cases, and error handling
- Log input/output pairs as evidence

What to verify: output data correctness, transformations, data types, edge cases, error handling.

### Business Logic Testing

Primary tools: **Unit test execution, scenario scripts**

- Write and run test cases for the specified rules
- Test happy paths, edge cases, and boundary conditions from the spec
- Validate outcomes against expected results
- Log test results as evidence

What to verify: rule correctness, edge cases, boundary conditions, error states.

## Guardrails

- **No round limit**: The loop runs until the Tester passes or the Designer accepts a CONDITIONAL PASS. The only escalation trigger is if the Tester detects a **stall** — the same issues persisting across 3 consecutive rounds with no meaningful progress.
- **Round numbering**: Both Builder and Tester must label every message with the round number. This enables progress tracking, regression detection, and accurate Supervisor monitoring.
- **Scope control**: The Builder should only modify files relevant to the task. No unrelated refactoring.
- **Git safety**: The Builder commits a checkpoint before each revision and after the final approved version. Use conventional commits: `feat(devtest): implement <target> from spec` and `fix(devtest): round N refinements per tester feedback`. Checkpoints use: `checkpoint: devtest round N before revisions`.
- **Rollback on regression**: If a revision introduces more failures than the previous round, the Builder must revert to the last checkpoint and try a different approach rather than fixing forward on a broken state.
- **No hallucinated approvals**: The Tester must actually test the live result, not assume it's correct based on reading code alone. Every verdict must be backed by concrete evidence (screenshots, test output, response logs, etc.). For visual tests specifically: "elements are present" is NOT sufficient for a PASS. The Tester must verify **positions, sizes, proportions, and spatial relationships** match the reference. A PASS that only checks element existence without measurements will be rejected by the team lead.
- **Tester must read the reference first — and re-read it periodically**: Before the first test round, the Tester must read/view the reference material. Every 3 rounds thereafter, the Tester must re-read the original reference to prevent spec drift.
- **Spec clarification over guessing**: If the spec is ambiguous or contradictory, agents must escalate to the team lead rather than silently interpreting. The team lead relays the question to the Designer.
- **Designer stays informed**: The team lead sends the Designer a progress update every 5 rounds, so they can intervene, adjust the spec, or accept a CONDITIONAL PASS without waiting for completion or stall.
- **Pre-flight check**: The Tester verifies the environment is ready (server running, URL responding, tools installed) before Round 1. No wasting rounds on infrastructure problems.
- **Evidence trail**: The Tester saves evidence for every test round to `devtest-evidence/` in the project root. This gives the Designer a history of the iteration. Evidence format depends on domain — screenshots for visual, logs for API, transcripts for conversational AI, etc.
- **Evidence naming convention**: All evidence files must follow the format `round-{N}-{description}.{ext}` (e.g., `round-1-fullpage.png`, `round-3-api-response.json`). No ad-hoc names. Consistent naming enables easy progress tracking and review.
- **Feedback prioritization**: FAIL verdicts must rank issues by severity (CRITICAL > MAJOR > MINOR). The Builder addresses CRITICAL issues first, preventing wasted rounds on cosmetic fixes while structural problems persist.
- **Resumability**: The Supervisor maintains `devtest-evidence/STATE.json` with the current loop state after every health check. If the team lead's context resets or an agent hits its context limit, the loop can resume from the state file rather than starting over.
- **Context window awareness**: If an agent senses it is approaching its context limit, it must proactively save a handoff summary to `STATE.json` and alert the team lead BEFORE going silent. The team lead spawns a fresh replacement agent that reads `STATE.json` and continues from the current round.
- **Mutual accountability**: The Supervisor monitors the Builder and Tester, but the Builder and Tester also monitor the Supervisor. Every 3 rounds, both agents ping the Supervisor to verify it's still active. If the Supervisor doesn't respond, they escalate to the team lead, who replaces it with a fresh instance. No agent runs unmonitored.
- **Supervisor shutdown acknowledgement**: When shutting down the loop, the team lead must send explicit shutdown messages and wait for acknowledgement from all agents. The Supervisor must reply with 'SUPERVISOR SHUTTING DOWN — acknowledged.' before being stopped. Agents that don't acknowledge within 2 minutes are force-stopped.
- **Builder reads the reference**: For visual specs, the Builder must read the reference image before Round 1 — not just work from the textual spec. Understanding the target directly produces better initial implementations and faster convergence.
- **Feedback acknowledgement**: The Builder must respond to every item in the Tester's FAIL feedback (FIXED / DEFERRED / NEEDS CLARIFICATION). Silently skipping items wastes rounds when the Tester re-reports them.
- **Session namespacing**: Each devtest session uses its own subdirectory under `devtest-evidence/{session-slug}/`. This prevents file collisions across concurrent or sequential devtest runs.
- **Incremental testing**: After Round 1, the Tester focuses on previously-failing criteria and spot-checks a few previously-passing ones, rather than re-running the full test suite every round. Full re-tests only when the Builder makes sweeping changes or a regression is detected.
- **Tool setup**: If the Tester needs tools that aren't installed (Playwright, curl, etc.), install them during the pre-flight check before the first test run.
- **Builder must verify via browser before notifying Tester**: The Builder cannot declare "ready for testing" based solely on reading code or running backend checks. For any frontend bug, the Builder MUST run a quick Playwright smoke test after deploying their fix to confirm the change is actually observable in the browser. "I read the code and it looks correct" is not verification — the browser is the source of truth. If the Builder cannot confirm their fix is visible in Playwright, they must NOT send "ready for testing" to the Tester.
- **Team lead must NOT bypass the loop**: The team lead must never investigate a bug independently, declare it fixed based on code reading, and skip the Builder/Tester agents. The devtest loop exists because code-reading is unreliable — "the code looks correct" has been wrong repeatedly. If the team lead catches themselves thinking "it must be a container restart issue" or "the logic looks right", that is exactly when Playwright needs to run, not a reason to skip it. The team lead's job is to orchestrate the agents, not to do their jobs for them.
- **Frontend bugs require frontend proof**: For any bug reported by the user in the browser, the PASS verdict MUST include Playwright evidence showing the fix working in the actual browser. Backend logs, code analysis, git diffs, or "it should work because I changed X" are never acceptable as PASS evidence for frontend bugs. No Playwright screenshot or request interception confirming the fix = no PASS.

## Example Invocations

### Visual Design
```
/devtest
Here's the mockup for the new login page: ~/designs/login-mockup.png
Implement it in frontend/src/pages/Login.tsx
React + Tailwind, dev server at localhost:5173/login
```

### API Endpoint
```
/devtest
Build a POST /api/users endpoint that:
- Accepts { name, email, role }
- Validates email format and role is one of ["admin", "user", "viewer"]
- Returns 201 with the created user object including an auto-generated ID
- Returns 422 with field-level errors for invalid input
Implement in backend/app/routes/users.py
```

### Conversational AI
```
/devtest
The partner agent should:
- Greet the user by name when they first connect
- Answer questions about today's schedule by checking the calendar tool
- Refuse to answer questions outside its domain with a polite redirect
- Maintain a warm, professional Irish tone throughout
Test by sending prompts to the /api/partner/chat endpoint
```

### CLI Tool
```
/devtest
Build a CLI script `bin/export.sh` that:
- Accepts --format (json|csv) and --output <path> flags
- Exports all active users from the database
- Defaults to json format and stdout if no flags given
- Shows usage help with --help
- Exits with code 1 and a clear error if the DB is unreachable
```

## When to Use This Skill

Use `/devtest` when:
- The user provides a clear spec and wants it implemented with iterative validation
- The user wants a build-test feedback loop for any kind of digital function
- The user says things like "make this match...", "implement this spec", "build this and test it against..."
- The user wants guaranteed quality through iterative validation rather than a single-pass implementation

Do NOT use when:
- There's no clear spec to test against (the user wants creative/exploratory work)
- The task is trivial enough that a single implementation pass is sufficient
- The user explicitly doesn't want the overhead of three agents
