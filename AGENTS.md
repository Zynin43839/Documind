# CRITICAL RULES - MUST FOLLOW

## LANGUAGE OF AGENTS.md (Important)

- This file and any AGENTS.md MUST be written in English only.
- Never write AGENTS.md content in Thai (or any other language).
- Note: this rule is about the AGENTS.md file itself; communicating with the user in Thai is still fine.

## RESPONSES

- Keep responses concise and to the point - unless the user asks otherwise

## PLANNING MODE

- Always ask clarifying questions
- Never assume design, tech stack or features
- Use deep-dive sub-agents to assist with research
- Use deep-dive sub-agents to review the different aspects of your plan before presenting to the user

## CHANGE / EDIT MODE

- Never implement features yourself when possible - use sub-agents!
- Identify changes from the plan that can be implemented in parallel, and use sub-agents to implement the features efficiently
- When using sub-agents to implement features, act as a coordinator only
- Use the best model for the task - premium models for complex tasks (like coding) and mid-tier models for simpler tasks, like documentation
- After completing features (large or small), always run commands like lint, type check and next build to check code quality

## DATABASE SCHEMA CHANGES

- Whenever you make changes to the database schema, ALWAYS run the drizzle generate and migrate commands
- NEVER run drizzle push!

## TESTING

- Use any testing tools, libraries available to the project for testing your changes
- Never assume your changes simply work, always test!
- If the project does not have any testing tools, scripts, MCP tools, skills, etc. available for testing, ask the user whether testing should be skipped.

## UI DESIGN

- Always follow the UI design system when creating or reviewing components or pages.
- Design System: @DESIGN.md

## FRONTEND STACK
- use React

## TOOL EXECUTION DISCIPLINE (anti-loop protocol)

- **Never repeat the same intention text without executing**: if you are about to do something, EXECUTE the tool call immediately. Writing "I will do X" more than once without running a tool = LOOP = forbidden.
- **One tool call per step**: run a command -> read its output -> decide the next step -> run the next command. Do not chain several not-yet-run intentions into one message.
- **No filler preambles**: keep narration minimal before a tool call (1 short line max, or none).
- **If a command fails (e.g. git push rejected)**: fix based on the actual error output, then re-run once. Never repeat the same failing command verbatim more than twice.
- **Prefer combining dependent simple steps in a single shell command** (e.g. `git add X; git commit -m "..."`) when they must run sequentially, so progress happens in one shot.
- **Batch independent tool calls in parallel**; keep dependent calls sequential and wait for results.
- If you notice yourself emitting the same sentence repeatedly in one response, STOP and make the tool call right away instead.
