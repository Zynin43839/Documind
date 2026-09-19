# CRITICAL RULES - MUST FOLLOW

## LANGUAGE OF AGENTS.md (Important)

- This file, any AGENTS.md, and any SKILL.md MUST be written in English only.
- Never write AGENTS.md or SKILL.md content in Thai (or any other language).
- Note: this rule is about those files themselves; communicating with the user in Thai is still fine.

## CURRENT WORK STATE (Handoff 2026-09-13)

- **Workload review DONE** (Nice vs Dao, T1-T20): pts 51/51 even, but Nice heavier in reality (60 vs 46 checkboxes, AC +67%). 4 under-estimated tickets: T4=4→8+, T9=8→higher, T15=8→~13, T19=3→5+. Red flags: T4 single point of failure (base of 6 tickets), 15/20 ticket bodies still have old Owner, sprint imbalance (Dao idle in S1, overloaded S3 19pts).
- **Team decision: NO CHANGES** — just go talk on each task about whether the other person wants to share the work (T4 as a pair is the first option).
- **S1 work added to GitHub Project** — repo `Zynin43839/Documind`, project `https://github.com/users/Zynin43839/projects/2`
- **PENDING TODO**: awaiting team discussion result on S2-S6 work split -> then apply agreed plan A/B/C/D (fix 20 ticket bodies / T4 pair / move sprints / adjust pts).
- **Deliverables created:**
  - `Mydoc/research/WORKLOAD-REVIEW-SLIDES.html` — 12-slide presentation (fonts embedded base64, offline-ready)
  - `Mydoc/brand/logo-documind.svg` — Documind logo (document + neural network concept)
  - `Mydoc/research/CARD-DISCUSSION.md` — temp discussion file (delete when concluded)
- **Reference data:** Owner field `PVTSSF_lAHODMTil84BiOrYzhhd7aw` (Nice=`9ecb78d2`, Dao=`f5f6b4db`), project id `PVT_kwHODMTil84BiOrY`
- **PowerShell:** Thai files must be UTF-8 (`Set-Content -Encoding UTF8`), .ps1 must be pure ASCII

## PROJECT CONTEXT (Required Reading — machine-local)

Read these before starting ANY work, in order. Read only what the task needs — do not read all files every time.

1. `README.md` — project overview, tech stack, API surface, architecture.
2. `Mydoc/decisions/DECISION-RECORD-2026-09-02.md` — the single source of truth for all locked decisions (D1–D9, V3–V9, research/deploy). **Must read before changing any plan.**
3. `Mydoc/BACKLOG-PLAN-2026-09-03.md` — ticket plan T1–T20 (work status / sprint). Read when planning or doing tracked work.
4. `docs/` keeps ONLY post-decision outcomes + operational guides: `github-projects-guide.md(.en)`, `TEAM-ONBOARDING.md`, `task-card-template.md`. Research/plan/draft files live in `Mydoc/research/`: `index-css-guide.md`, `crawler-quality-plan.md`, `frontend-component-plan.md`. (The old `frontend-plan.md` / `database-plan.md` were deleted — outdated specs; locked decisions live in `Mydoc/decisions/`.)
5. `Mydoc/graphify/GRAPH_REPORT.md` — knowledge map (optional; use `graphify query "..."` to explore relationships when needed).

Notes:
- These files are machine-local (under `Mydoc/`, gitignored) — they exist only on this machine, not on GitHub.
- Decision record is authoritative: if docs/ conflicts with it, the decision record wins — flag the mismatch instead of silently following the doc.
- Keep context small: for a frontend task read the decision record + schemablue-DESIGN.md; for a backend/db task read the decision record + backlog plan; do not read the whole repo.

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

- Whenever you make changes to the database schema, ALWAYS create a migration file and apply it to Supabase with `supabase db push`
- NEVER use drizzle or any migration tool that the team has not approved

## TESTING

- Use any testing tools, libraries available to the project for testing your changes
- Never assume your changes simply work, always test!
- If the project does not have any testing tools, scripts, MCP tools, skills, etc. available for testing, ask the user whether testing should be skipped.

## UI DESIGN

- Always follow the UI design system when creating or reviewing components or pages.
- Design System: @DESIGN.md

## FRONTEND STACK
- use React

## DOC LOCATION RULE

- `docs/` contains ONLY post-decision outcomes + operational guides: `github-projects-guide.md(.en)`, `TEAM-ONBOARDING.md`, `task-card-template.md`.
- Research / plan / draft / temporary files live in `Mydoc/` (gitignored, machine-local): `Mydoc/research/` (crawler-quality-plan, frontend-component-plan, index-css-guide, CARD-DISCUSSION, WORKLOAD-REVIEW-SLIDES), `Mydoc/brand/` (logo-documind.svg), `Mydoc/decisions/`.
- Decision record remains authoritative; if docs/ conflicts with it, flag it.

## TOOL EXECUTION DISCIPLINE (anti-loop protocol)

- **Never repeat the same intention text without executing**: if you are about to do something, EXECUTE the tool call immediately. Writing "I will do X" more than once without running a tool = LOOP = forbidden.
- **One tool call per step**: run a command -> read its output -> decide the next step -> run the next command. Do not chain several not-yet-run intentions into one message.
- **No filler preambles**: keep narration minimal before a tool call (1 short line max, or none).
- **If a command fails (e.g. git push rejected)**: fix based on the actual error output, then re-run once. Never repeat the same failing command verbatim more than twice.
- **Prefer combining dependent simple steps in a single shell command** (e.g. `git add X; git commit -m "..."`) when they must run sequentially, so progress happens in one shot.
- **Batch independent tool calls in parallel**; keep dependent calls sequential and wait for results.
- If you notice yourself emitting the same sentence repeatedly in one response, STOP and make the tool call right away instead.
