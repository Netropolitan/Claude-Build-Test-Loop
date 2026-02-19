# /devtest — Spec-Build-Test Loop for Claude Code

A Claude Code skill that creates a two-agent feedback loop: one agent builds, another tests against your spec. They iterate until the result matches. Works for any digital function — UI, APIs, CLI tools, conversational AI, data pipelines, and more.

## How It Works

```
You provide a spec (the "Designer")
        |
        v
   Builder agent implements
        |
        v
   Tester agent validates against your spec
        |
    Match? --YES--> Done!
        |
        NO
        |
        v
   Tester sends specific feedback to Builder
        |
        v
   Builder revises → Tester re-checks → repeat
```

Three roles drive the process:

| Role | Who | What They Do |
|------|-----|--------------|
| **Designer** | You | Define what "correct" looks like — mockup, expected behavior, example I/O, etc. |
| **Builder** | Agent | Implements code to match your spec. Revises based on Tester feedback. |
| **Tester** | Agent | Validates the result against your spec. Reports PASS or specific FAIL feedback. |

The loop runs until the Tester approves — there's no arbitrary round limit. If the same issues persist for 3+ rounds without progress, the Tester escalates so you can adjust the approach.

## What You Can Spec and Test

This isn't just for visual design. Any digital function with a clear "what correct looks like" works:

| Domain | Spec Examples | How It's Tested |
|--------|---------------|-----------------|
| **Visual/UI** | Mockup image, screenshot, design description | Playwright screenshots + computed style extraction |
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

### 1. Enable Agent Teams

Agent Teams is required for this skill. Add the following to your `~/.claude/settings.json`:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

If the file already exists, merge the `env` block into your existing settings. Restart Claude Code after making this change.

### 2. Install the Skill

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

### 3. Verify

Start a new Claude Code session and type `/devtest` — you should see the skill activate and ask you for a spec.

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
- Implements the first version
- Receives feedback from the Tester and revises
- Commits code after initial implementation and after final approval
- Uses conventional commits: `feat(devtest): ...` and `fix(devtest): ...`

### Tester Agent
- Receives your full spec as the definition of "correct"
- Uses domain-appropriate tools to validate:
  - **Visual**: Playwright for screenshots and computed style extraction
  - **API**: curl/fetch for HTTP request/response validation
  - **CLI**: Bash execution for command output comparison
  - **AI**: Scripted prompts for response quality checks
- Produces a **PASS** or **FAIL** verdict each round
- FAIL feedback is specific and measurable (e.g., "Header background is `#333` but spec shows `#1a1a2e`")
- Saves evidence to `devtest-evidence/` in your project root

### Stall Detection
There's no artificial round limit. The loop keeps going until the Tester passes. The only exception: if the Tester sees the same issues repeating for 3 consecutive rounds with no progress, it escalates to you so you can adjust the spec or approach.

## Evidence Trail

Every test round produces evidence saved to `devtest-evidence/` in your project root:

| Domain | Evidence Format |
|--------|----------------|
| Visual/UI | Screenshots (`round-1.png`, `round-2.png`, ...) |
| API | Request/response logs |
| Conversational AI | Conversation transcripts |
| CLI | Command output logs |
| Business logic | Test results |

This gives you a complete history of the iteration.

## Guardrails

- **No hallucinated approvals** — The Tester must actually run tests, not assume correctness from code
- **Scope control** — The Builder only modifies files relevant to the spec
- **Git safety** — Commits after initial implementation and final approval
- **Evidence required** — Every PASS/FAIL verdict is backed by concrete test output

## Tips

- **Be specific in your spec.** The more precise your definition of "correct," the faster the loop converges. Vague specs lead to vague feedback loops.
- **Provide a testable endpoint.** If the Builder is creating a web UI, make sure a dev server URL is available for the Tester to hit. If it's an API, provide the base URL.
- **Include edge cases.** If you care about error handling, specify the error cases in your spec. The Tester will only check what you define as "correct."
- **Let it run.** The loop is designed to iterate. Don't interrupt unless the Tester escalates a stall.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Skill not found when typing `/devtest` | Ensure `SKILL.md` is at `~/.claude/skills/devtest/SKILL.md` and restart Claude Code |
| "Agent Teams not enabled" error | Add `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS: "1"` to `~/.claude/settings.json` and restart |
| Tester can't reach the URL | Make sure your dev server is running before invoking `/devtest` |
| Playwright not installed | The Tester will attempt to install it automatically; ensure Node.js is available |
| Agents stall / go idle | The team lead will nudge them; if persistent, restart the session |

## License

MIT License. See [LICENSE](LICENSE) for details.
