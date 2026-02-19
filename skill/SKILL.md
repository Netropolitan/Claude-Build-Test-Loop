---
name: devtest
description: Spec-Build-Test loop — the user defines a spec, then two agents iterate (one builds, one tests against the spec) until the result matches. Works for any digital function — UI, APIs, CLI tools, conversational AI, data pipelines, and more.
---

# Dev-Test Skill

A general-purpose two-agent feedback loop. The user (Designer) sets the spec, one agent (Builder) implements it, and another agent (Tester) validates the result against the spec. They iterate until the Tester confirms the implementation matches. This process applies to **any digital function** — not just visual design.

## Roles

| Role | Who | Responsibility |
|------|-----|----------------|
| **Designer** | The human user | Defines the spec — what "correct" looks like. Has final say. |
| **Builder** | Agent teammate | Implements and refines the code/system to match the Designer's spec. |
| **Tester** | Agent teammate | Validates the result against the spec using appropriate testing methods. Reports discrepancies or approves. |

## Workflow

```
Designer provides spec
        |
        v
   Builder implements
        |
        v
   Tester validates against spec
        |
    Match? --YES--> Done! Report to Designer
        |
        NO
        |
        v
   Tester sends feedback to Builder
        |
        v
   Builder revises (loop back to Tester)
```

## What Can Be Spec'd and Tested

This skill is not limited to visual design. The Designer can provide any kind of spec:

| Domain | Spec Examples | How the Tester Validates |
|--------|---------------|--------------------------|
| **Visual/UI** | Mockup image, screenshot, design description | Playwright screenshots, computed style extraction, visual comparison |
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
  - A screenshot (visual)
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

### Step 2: Create the Team

Create a team named `devtest` with yourself as team lead.

### Step 3: Create Tasks

Create these tasks in the task list:

1. **"Implement spec"** — assigned to Builder
   - Description: Include the full spec, target files, tech stack, and any constraints from the Designer

2. **"Validate against spec"** — assigned to Tester
   - Description: Include the full spec, how to test the result, and the testing approach for this domain
   - Blocked by task 1 (Builder must implement first)

### Step 4: Spawn Teammates

Spawn exactly **two** teammates:

#### Builder (subagent_type: `general-purpose`)

Prompt must include:
- The full spec from the Designer
- Target file(s) to create or modify
- Tech stack and constraints
- Instruction: "You are the **Builder** in a spec-build-test loop. Your job is to implement code that satisfies the Designer's spec. After your initial implementation, the Tester will validate and send you feedback. When you receive feedback, revise the code and notify the Tester to re-check. Keep iterating until the Tester approves."
- Instruction: "After each revision, send a message to the Tester saying what you changed and that it's ready for re-testing."
- Instruction: "Do NOT mark your task as completed until the Tester has approved the implementation."

#### Tester (subagent_type: `general-purpose`)

Prompt must include:
- The full spec from the Designer so they know what "correct" looks like
- How to test the result (URL, command, endpoint, file path, etc.)
- The testing approach determined by the team lead (see Testing Methods below)
- Instruction: "You are the **Tester** in a spec-build-test loop. Your job is to validate the Builder's implementation against the Designer's spec. Be specific and actionable in your feedback."
- Instruction: "For each test round, produce a verdict:"
  - **PASS** — The implementation satisfies the spec. Report to the team lead that the result is approved.
  - **FAIL** — List specific discrepancies between the implementation and the spec. Be precise and measurable. Send this feedback directly to the Builder.
- Instruction: "After sending FAIL feedback to the Builder, wait for them to message you that revisions are ready, then re-test."
- Instruction: "There is no round limit — keep iterating until the implementation matches the spec. However, if you notice the same discrepancies persisting across 3 consecutive rounds with no meaningful improvement, escalate to the team lead. Describe what's stuck and what you've already tried so the team lead can intervene or consult the Designer."
- **Domain-specific testing instructions** (see Testing Methods below — the team lead selects and includes the relevant section)

### Step 5: Monitor the Loop

As team lead:

1. Let the Builder implement and the Tester validate
2. The two agents message each other directly — Builder sends "ready for testing" and Tester sends either PASS or FAIL with feedback
3. Monitor for:
   - **Tester PASS**: The loop is done. Notify the user with a summary of what was built and how many iterations it took.
   - **Tester stall escalation**: If the Tester reports the same issues persisting across 3 consecutive rounds with no progress, they will escalate. Intervene by reviewing the remaining discrepancies, adjusting the approach, or asking the Designer for guidance.
   - **Stalled agents**: If either agent goes idle without completing their task, send them a message to continue.
4. The loop runs until the Tester passes or the Tester escalates a stall. There is no arbitrary round limit — the goal is to match the spec.
5. When PASS is received or the user accepts the result, shut down both teammates and clean up the team.

### Step 6: Report to the Designer

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

- Navigate to the target URL with Playwright
- Take full-page screenshots with `page.screenshot()`
- Extract computed styles via `page.locator()` and `locator.evaluate()` — colors, fonts, spacing, dimensions
- Compare extracted values against the reference design
- Test at multiple viewport sizes if responsive behavior is part of the spec
- Save screenshots to `devtest-screenshots/` for evidence (e.g., `round-1.png`, `round-2.png`)

What to verify: layout/structure, colors, typography, spacing, alignment, responsive behavior, overall visual fidelity.

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

- **No round limit**: The loop runs until the Tester passes. The only escalation trigger is if the Tester detects a **stall** — the same issues persisting across 3 consecutive rounds with no meaningful progress.
- **Scope control**: The Builder should only modify files relevant to the task. No unrelated refactoring.
- **Git safety**: The Builder should commit after the initial implementation and after the final approved version. Use conventional commits: `feat(devtest): implement <target> from spec` and `fix(devtest): refinements per tester feedback`
- **No hallucinated approvals**: The Tester must actually test the live result, not assume it's correct based on reading code alone. Every verdict must be backed by concrete evidence (screenshots, test output, response logs, etc.).
- **Evidence trail**: The Tester saves evidence for every test round to `devtest-evidence/` in the project root. This gives the Designer a history of the iteration. Evidence format depends on domain — screenshots for visual, logs for API, transcripts for conversational AI, etc.
- **Tool setup**: If the Tester needs tools that aren't installed (Playwright, curl, etc.), install them before the first test run.

## Example Invocations

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

## When to Use This Skill

Use `/devtest` when:
- The user provides a clear spec and wants it implemented with iterative validation
- The user wants a build-test feedback loop for any kind of digital function
- The user says things like "make this match...", "implement this spec", "build this and test it against..."
- The user wants guaranteed quality through iterative validation rather than a single-pass implementation

Do NOT use when:
- There's no clear spec to test against (the user wants creative/exploratory work)
- The task is trivial enough that a single implementation pass is sufficient
- The user explicitly doesn't want the overhead of two agents
