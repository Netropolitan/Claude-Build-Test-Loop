# /devtest — Spec-Build-Test Loop for Claude Code

A Claude Code skill that creates a three-agent feedback loop: one agent builds, another tests against your spec, and a third supervises for freezes and stalls. They iterate until the result matches. Works for any digital function — UI, APIs, CLI tools, conversational AI, data pipelines, and more.

## How It Works

```
You provide a spec (the "Designer")
        |
        v
   Builder agent implements (Round 1)
        |
        v
   Tester agent validates against your spec
        |
    Match? --PASS--> Team lead validates evidence --> Done!
        |
   CONDITIONAL PASS? --> You decide: accept or keep iterating
        |
        FAIL
        |
        v
   Tester sends specific, ranked feedback to Builder
        |
        v
   Builder checkpoints, revises, notifies Tester
        |
        v
   (loop back to Tester — Round N)

   [Supervisor monitors every 3 min throughout]
   [Builder & Tester verify Supervisor is alive every 3 rounds]
```

Four roles drive the process:

| Role | Who | What They Do |
|------|-----|--------------|
| **Designer** | You | Define what "correct" looks like — mockup, expected behavior, example I/O, etc. |
| **Builder** | Agent | Implements code to match your spec. Revises based on Tester feedback. Commits checkpoints before each revision. |
| **Tester** | Agent | Validates the result against your spec using domain-appropriate tools. Reports PASS, CONDITIONAL PASS, or ranked FAIL feedback. |
| **Supervisor** | Agent | Monitors Builder and Tester every 3 minutes. Detects frozen agents, stalled handoffs, circular loops, and ineffective rounds. Nudges or escalates. |

The loop runs until the Tester approves — there's no arbitrary round limit. If the same issues persist for 3+ rounds without progress, the Tester escalates so you can adjust the approach.

## What You Can Spec and Test

This isn't just for visual design. Any digital function with a clear "what correct looks like" works:

| Domain | Spec Examples | How It's Tested |
|--------|---------------|-----------------|
| **Visual/UI** | Mockup image, screenshot, design description | Playwright screenshots + proportional measurement extraction |
| **API/Backend** | Request/response pairs, status codes, data shapes | HTTP requests, response validation |
| **Conversational AI** | Conversation flows, tone, expected responses | Scripted prompts, response comparison |
| **CLI tools** | Expected outputs, flags, exit codes | Command execution, stdout/stderr comparison |
| **Data pipelines** | Input → output transformations | Pipeline execution, output comparison |
| **Business logic** | Rules, edge cases, expected outcomes | Test case execution |
| **Accessibility** | WCAG criteria, keyboard navigation | Playwright + axe-core audits |
| **Performance** | Response time targets, bundle size limits | Lighthouse, timing measurements |

## Prerequisites

- **Claude Code** with [Agent Teams](https://docs.anthropic.com/en/docs/claude-code) enabled
- Agent Teams must be turned on in your settings (see Installation below)

## Installation

### Quick Install (one command)

```bash
curl -fsSL https://raw.githubusercontent.com/Netropolitan/Claude-Build-Test-Loop/main/install.sh | bash
```

This downloads the skill, places it in `~/.claude/skills/devtest/`, and enables Agent Teams in your settings. Restart Claude Code after running it.

### Manual Install

#### 1. Enable Agent Teams

Agent Teams is required for this skill. Add the following to your `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

If the file already exists, merge the `env` block into your existing settings. Restart Claude Code after making this change.

#### 2. Install the Skill

Copy the `skill/` folder into your Claude Code skills directory:

```bash
# Create the skill directory
mkdir -p ~/.claude/skills/devtest

# Copy the skill file
cp skill/SKILL.md ~/.claude/skills/devtest/SKILL.md
```

Or if you cloned this repo:

```bash
cp -r skill/ ~/.claude/skills/devtest/
```

#### 3. Verify

Start a new Claude Code session and type `/devtest` — you should see the skill activate and ask you for a spec.

### Uninstall

```bash
rm -rf ~/.claude/skills/devtest
```

To also disable Agent Teams, remove the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` line from `~/.claude/settings.json`.

## Usage

Invoke with `/devtest` followed by your spec:

### Visual Design

```
/devtest
Here's the mockup for the new login page: ~/designs/login-mockup.png
Implement it in src/pages/Login.tsx
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
Implement in backend/routes/users.py
```

### Conversational AI

```
/devtest
The chat agent should:
- Greet the user by name when they first connect
- Answer questions about today's schedule by checking the calendar tool
- Refuse to answer questions outside its domain with a polite redirect
- Maintain a warm, professional tone throughout
Test by sending prompts to the /api/chat endpoint
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

## How the Agents Work

### Builder Agent
- Receives your full spec and target files
- Reads the reference material directly before Round 1 (doesn't work blind from descriptions)
- Implements the first version, then iterates based on Tester feedback
- **Commits a checkpoint before each revision** — gives a clean rollback point
- **Rolls back if a revision makes things worse** instead of fixing forward on a broken state
- Acknowledges every feedback item explicitly (FIXED / DEFERRED / NEEDS CLARIFICATION)
- For frontend work: verifies fixes in the browser via Playwright before notifying the Tester
- Numbers every round for tracking
- Uses conventional commits: `feat(devtest): ...` and `fix(devtest): ...`
- **Checks in on the Supervisor every 3 rounds** to verify it's still active

### Tester Agent
- Receives your full spec as the definition of "correct"
- Reads the reference material before testing — re-reads it every 3 rounds to prevent spec drift
- Uses domain-appropriate tools to validate (Playwright, curl, bash, etc.)
- Produces a **PASS**, **CONDITIONAL PASS**, or **FAIL** verdict each round
- FAIL feedback is ranked by severity: **CRITICAL > MAJOR > MINOR**
- Every verdict includes concrete measurements (not just "it looks right")
- Tracks regression — flags when a revision introduces more failures than the previous round
- Uses incremental testing after Round 1 (focuses on previously-failing criteria + spot-checks)
- Saves evidence to `devtest-evidence/{session-slug}/` with consistent naming: `round-{N}-{description}.{ext}`
- Performs a pre-flight environment check before Round 1
- **Checks in on the Supervisor every 3 rounds** to verify it's still active

### Supervisor Agent
- Runs alongside Builder and Tester for the entire session
- Performs health checks every 3 minutes:
  - Checks task statuses
  - Pings both agents for status updates
  - Follows up on non-responsive agents
  - Escalates frozen agents to the team lead
- Detects and handles:
  - **Stalled handoffs** — Builder finished but Tester hasn't started
  - **Deadlocks** — both agents waiting for each other
  - **Circular loops** — same feedback repeating 8+ times
  - **Silent Builder** — code changes without notification to Tester
  - **Evidence gaps** — Tester testing without saving artifacts
  - **Missing checkpoints** — 15+ minutes without a git commit
  - **Ineffective rounds** — Builder's changes had no observable effect
  - **Wrong-layer fixes** — backend changes not reaching frontend
  - **Forgotten task completion** — PASS sent but tasks not marked done
- Maintains `STATE.json` for loop resumability
- Reads test evidence between rounds to independently verify progress
- **Responds promptly to Builder/Tester check-ins** — if it doesn't, they escalate
- **Acknowledges shutdown explicitly** — replies with confirmation before stopping

### Mutual Accountability

The agents monitor each other in both directions:

- **Supervisor → Builder/Tester**: Health checks every 3 minutes, nudges idle agents, escalates frozen ones
- **Builder/Tester → Supervisor**: Liveness check every 3 rounds, escalate to team lead if Supervisor is unresponsive
- **Team lead**: Replaces any frozen agent (including the Supervisor) with a fresh instance that reads `STATE.json` to continue

This prevents the common failure mode where the Supervisor silently freezes and the loop continues without oversight.

### Stall Detection
There's no artificial round limit. The loop keeps going until the Tester passes. The only exceptions:
- If the Tester sees the same issues repeating for 3 consecutive rounds with no progress, it escalates
- If the Supervisor detects the same failure descriptions for 2 consecutive rounds, it escalates
- If an agent hits its context limit, it saves state and the team lead spawns a replacement

## Evidence Trail

Every test round produces evidence saved to `devtest-evidence/{session-slug}/` in your project root:

| Domain | Evidence Format |
|--------|----------------|
| Visual/UI | Screenshots (`round-1-fullpage.png`, `round-3-canvas.png`, ...) |
| API | Request/response logs (`round-1-api-response.json`, ...) |
| Conversational AI | Conversation transcripts |
| CLI | Command output logs |
| Business logic | Test results |

The Supervisor also maintains `STATE.json` with round history, enabling the loop to resume across sessions.

## Guardrails

- **No hallucinated approvals** — The Tester must actually run tests with concrete measurements, not assume correctness from code. "Elements exist" is not a PASS.
- **Scope control** — The Builder only modifies files relevant to the spec
- **Git safety** — Checkpoints before every revision, rollback on regression
- **Evidence required** — Every verdict backed by screenshots, measurements, response logs, or test output
- **Mutual monitoring** — All three agents are watched: Supervisor watches Builder/Tester, they watch the Supervisor back
- **Graceful shutdown** — All agents must acknowledge shutdown before being stopped
- **Resumability** — `STATE.json` enables picking up where a previous session left off
- **Spec clarity** — Ambiguous specs are escalated to you, never silently interpreted
- **Browser is truth** — For frontend work, Playwright verification is mandatory before any "ready for testing" or PASS verdict

## Tips

- **Be specific in your spec.** The more precise your definition of "correct," the faster the loop converges. Vague specs lead to vague feedback loops.
- **Provide a testable endpoint.** If the Builder is creating a web UI, make sure a dev server URL is available for the Tester to hit. If it's an API, provide the base URL.
- **Include edge cases.** If you care about error handling, specify the error cases in your spec. The Tester will only check what you define as "correct."
- **Let it run.** The loop is designed to iterate. Don't interrupt unless the Tester escalates a stall or you get a progress update and want to adjust.
- **Watch the progress updates.** Every 5 rounds, the team lead sends you a status update. This is your chance to course-correct without waiting for the loop to stall.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Skill not found when typing `/devtest` | Ensure `SKILL.md` is at `~/.claude/skills/devtest/SKILL.md` and restart Claude Code |
| "Agent Teams not enabled" error | Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` to `~/.claude/settings.json` and restart |
| Tester can't reach the URL | Make sure your dev server is running before invoking `/devtest` |
| Playwright not installed | The Tester will attempt to install it during pre-flight; ensure Node.js is available |
| Agents stall / go idle | The Supervisor will nudge them automatically; if the Supervisor itself freezes, Builder/Tester will escalate and it gets replaced |
| Supervisor doesn't acknowledge shutdown | Team lead force-stops after 2-minute timeout and notes it in the report |
| Loop seems stuck | Check `devtest-evidence/STATE.json` for round history — if consecutive rounds have identical verdicts, the approach needs changing |

## License

MIT License. See [LICENSE](LICENSE) for details.
