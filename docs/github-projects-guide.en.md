# GitHub Projects v2 — DocuMind Team Guide (EN)

> Status: 2026-09-02 · Companion to Skill `github-projects-v2`
> Goal: let every team member produce/manage the backlog (Epic → Task → Subtask) on GitHub Projects v2 themselves — via the Web UI, the `gh` CLI, and the GraphQL API.

## 1) Overview — 3 Usage Levels

| Method | Who uses it | Strength | Requirement |
|---|---|---|---|
| **Web UI** (github.com/projects) | Everyone on the team | Easy to create/drag/filter, no code | Just a GitHub account |
| **`gh` CLI** | Ticket producers / scripts | Repeatable, JSON output pipeable | Install gh + auth `project` scope |
| **GraphQL API** | Automation / advanced scripts | Full control (fields, items), single API | PAT / GH App token |

## 2) Install + Auth (one-time setup)

```powershell
# Install gh CLI (if not present)
winget install GitHub.cli

# Auth — important: needs the project scope
gh auth login --scopes "project"

# Verify the scope is present
gh auth status

# If the scope is missing, add it (no need to fully re-login)
gh auth refresh -s project
```

> **✅ Status as of 2026-09-02:** `gh` CLI is installed (v2.98.0) and logged in as **Zynin43839** (scopes: `gist`, `project`, `read:org`, `repo`) — ready to use via CLI/script now.
> Minimum token scope: `project` (read+write) or `read:project` (read-only).

## 3) Core Commands (ticket producer)

```powershell
# 1) Create a project
gh project create --owner "@me" --title "DocuMind Backlog"

# 2) List fields — you need the field ID before setting a value.
# Use --format json to get BOTH the field-id and the option-id (required for item-edit)
gh project field-list 1 --owner "@me" --format json

# 3) Create new fields (e.g. Priority / Epic / Work Type / Estimate)
# ⚠️ Avoid the names "Type" or "Estimate" — "Type" is reserved in the UI, "Estimate" is often taken → use "Work Type" and "Story Points" instead
gh project field-create 1 --owner "@me" --name "Priority" --data-type "SINGLE_SELECT" --single-select-options "Low,Medium,High"
gh project field-create 1 --owner "@me" --name "Epic" --data-type "SINGLE_SELECT" --single-select-options "FE,BE,AUTH,INFRA,CRAWLER"
gh project field-create 1 --owner "@me" --name "Work Type" --data-type "SINGLE_SELECT" --single-select-options "Frontend,Backend,Infra,Decision,Test"
gh project field-create 1 --owner "@me" --name "Story Points" --data-type "NUMBER"

# 4) Create a draft issue (ticket) into the project
gh project item-create 1 --owner "@me" --title "Implement login form" --body "..."

# Multiline body (with AC checklist) — store in a single-quoted here-string so PowerShell doesn't interpret it
$body = @'
In base as a dev, I want X so that Y.

## Acceptance Criteria
- [ ] AC1
- [ ] AC2
'@
gh project item-create 1 --owner "@me" --title "TASK TITLE" --body $body

# 5) Edit a field on an item (Status / Priority / Epic ...)
# ⚠️ You CANNOT combine --field with --id — use --field-id + --single-select-option-id + --project-id (machine-friendly)
gh project item-edit --owner "@me" --id <item-id> --project-id <project-id> `
  --field-id <field-id> --single-select-option-id <option-id>

# example: set Priority=High, Epic=BE, Work Type=Backend on an item
gh project item-edit --owner "@me" --id PVTI_xxxx --project-id PVT_yyyy `
  --field-id PVTSSF_priority --single-select-option-id 993039bb      # High
gh project item-edit --owner "@me" --id PVTI_xxxx --project-id PVT_yyyy `
  --field-id PVTSSF_epic --single-select-option-id a20e7ca7          # BE
gh project item-edit --owner "@me" --id PVTI_xxxx --project-id PVT_yyyy `
  --field-id PVTSSF_worktype --single-select-option-id c8dbb666      # Backend

# 6) Verify items + fields (field-list --format json confirms the correct option IDs)
gh project item-list 1 --owner "@me" --format json
```

### Other frequently used commands

```powershell
gh project list --owner "@me"                    # list all projects
gh project item-list 1 --format=json             # export for report/script
gh project item-create 1 --owner "@me" --title "Task" --body "AC: ..."   # create a task
gh project item-archive 1 --owner "@me" --id <item-id> # archive a completed item (use the item-id PVTI_)
gh project item-archive 1 --owner "@me" --id <item-id> --undo # restore an archived item
gh project field-delete 1 --id <fieldId>         # delete a field — ⚠️ has no --owner flag (only --id)
gh project delete 1 --owner "@me"                # delete a whole project
```

## 4) Using the GraphQL API (for scripts/automation)

GitHub Projects v2 is driven by **GraphQL**. Key flows (per docs.github.com):

### 4.1 Find the project node ID

```powershell
gh api graphql -f query='
  query($user: String! $n: Int!) {
    user(login: $user) { projectV2(number: $n) { id } }
  }' -f user="TEEREDCOM" -F n=1
```

### 4.2 Find field ID + option ID (must prefetch before setting a field)

```powershell
gh api graphql -f query='
  query {
    node(id: "PROJECT_ID") {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2FieldCommon { id name }
            ... on ProjectV2SingleSelectField {
              id name
              options { id name }
            }
          }
        }
      }
    }
  }'
```

> The system must remember the `field id` + `option id` — do it once and reuse (no need to query every time).

### 4.3 Add a draft issue

```powershell
gh api graphql -f query='
  mutation {
    addProjectV2DraftIssue(input: {
      projectId: "PROJECT_ID"
      title: "TASK_TITLE"
      body: "TASK_BODY"
    }) { projectItem { id } }
  }'
```

### 4.4 Set a field value (must be a separate call from create)

```powershell
# single select (Status/Priority/Epic)
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "PROJECT_ID"
      itemId: "ITEM_ID"
      fieldId: "FIELD_ID"
      value: { singleSelectOptionId: "OPTION_ID" }
    }) { projectV2Item { id } }
  }'

# text
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "PROJECT_ID"
      itemId: "ITEM_ID"
      fieldId: "FIELD_ID"
      value: { text: "value" }
    }) { projectV2Item { id } }
  }'
```

### 4.5 Add a repo issue to the project

```powershell
gh api graphql -f query='
  mutation {
    addProjectV2ItemById(input: {
      projectId: "PROJECT_ID"
      contentId: "ISSUE_NODE_ID"
    }) { item { id } }
  }'
```

### ⚠️ Errors hit in real testing (2026-09-02) — prefer native CLI over hand-written GraphQL

| Symptom | Cause | Working fix |
|---|---|---|
| `HTTP 502` on `addProjectV2DraftIssue` / `updateProjectV2ItemFieldValue` via `-f query=` | On Windows/PowerShell, node-ids inside `-f query=` lose their quotes (sent as `PVT_..` without `"`) | Use `gh project item-create` / `item-edit` (native CLI) — the CLI does the GraphQL itself and avoids the 502 |
| `Argument 'id' ... Expected type 'ID!'` | node-id sent without quotes | Do not inline ids inside `-f query=` |
| `--field cannot be used with --id` | `gh project item-edit` forbids `--field` + `--id` together | Use `--field-id` + `--single-select-option-id` + `--project-id` + `--id <item-id PVTI_>` |
| `--id` must be a draft content `DI_` (when title/body provided) | If you pass `--title`/`--body` too, gh interprets `--id` as the draft content id | Set fields in a separate call (no title/body) → use the item-id `PVTI_` |
| `HTTP 502` on `updateProjectV2SingleSelectFieldOptions` (add an option to an existing field) | The options-editing mutation is rejected by the server with 502 — verified via both `gh api graphql` and direct `curl` (even though a plain query through `gh api graphql` works) | **No native CLI** to add an option → must be done via Web UI (see below) |

> ### 🔧 Add a new option to an existing field (e.g. add a "Brain storm" column to Status) — must use Web UI
>
> **Limitation:** `gh project` only has `field-create` / `field-delete` (create/delete a whole field) — **there is no command to add an option to an existing field**. The `updateProjectV2SingleSelectFieldOptions` mutation hits 502 on this machine, so it must be done via the web.
>
> **Web UI steps (add a new status option):**
> 1. Open the DocuMind project → top-right menu `⋮⋮` → **Settings**
> 2. On the left, select the **`Status`** field (or the field you want)
> 3. In the middle you'll see the options (Todo / In Progress / Done ...)
> 4. Click **+ Add option** → type the new name (e.g. `Brain storm`) → **Save**
> 5. Back on the board view → the new column appears immediately (refresh if needed)
>
> > 💡 Board view columns are driven by the **Status field** — adding an option to Status = a new column on the board.

> **Summary of what actually works (tested 2026-09-02):**
> 1. Create the item with `gh project item-create` (native) → get the item-id `PVTI_`
> 2. Set the field with `gh project item-edit --id <PVTI_> --project-id <PVT_> --field-id <PVTSSF_> --single-select-option-id <option>` —
>    **must** prefetch the option-id from `gh project field-list --format json` first
> 3. Verify with `gh project item-list --format json`

### ✅ Real test record 2026-09-02 (all commands verified)

> Tested live on the Documind project (#2) / a throwaway project (created then deleted) — every CRUD command works.

| Category | Command | Result |
|---|---|---|
| CREATE | `gh project create --owner "@me" --title "..." --format json` | ✅ created, then removed |
| CREATE | `gh project field-create 2 --owner "@me" --name "Sprint" --data-type "SINGLE_SELECT" --single-select-options "S1,S2,S3,S4"` | ✅ created, then removed |
| CREATE | `gh project item-create 2 --owner "@me" --title "..." --body "..."` | ✅ draft issue created |
| READ | `gh project list --owner "@me"` | ✅ |
| READ | `gh project field-list 2 --owner "@me" --format json` | ✅ returns field-id + option-id |
| READ | `gh project item-list 2 --owner "@me" --format json` | ✅ |
| UPDATE | `gh project item-edit --owner "@me" --id <PVTI_> --project-id <PVT_> --field-id <PVTSSF_> --single-select-option-id <oid>` | ✅ set field value |
| UPDATE | `gh project item-edit 2 --owner "@me" --id <DI_> --title "..." --body "..."` | ✅ update title/body (needs content id `DI_`) |
| UPDATE | `gh project item-archive 2 --owner "@me" --id <PVTI_>` and `--undo` | ✅ archive + unarchive |
| DELETE | `gh project field-delete 2 --id <fieldId>` | ✅ (no `--owner` flag) |
| DELETE | `gh project delete 3 --owner "@me"` | ✅ project removed |

> **Note:** `field-delete` does not accept `--owner` — the previous doc version with `--owner` fails with `unknown flag: --owner`.

## 5) ⚠️ Key Limitations (know before planning)

| # | Limitation | Impact | Workaround |
|---|---|---|---|
| 1 | **Add + update are separate** — GitHub does not allow create-item + set-field in one call | 1 ticket = at least 2 API calls (create, then set) | Write a script that prefetches field/option IDs and reuses them; loop per item |
| 2 | **Field ID / option ID must be prefetched** | Must know the ID before every set | Query once, then cache |
| 3 | **Draft issue vs real Issue** — draft = floating ticket (not bound to a repo), real issue is bound to a repo | Pick based on the goal: draft for unconfirmed backlog, issue for tracking in code | Implementation work uses real issues (in the repo), planning backlog uses drafts |
| 4 | **Assignees / Labels / Milestone** cannot be set via a project field | Requires separate mutations (addAssigneesToAssignable / addLabelsToLabelable) | Use only when truly needed |
| 5 | **No native subtask/dependency** in project items | No native hierarchy like Linear | Use sub-issues (GitHub parent/child issues) or a checklist in the body; there is no `dependent_on` for dependencies → use manual tracking/labels |

## 6) Recommended Approach for DocuMind

- Use the **Status field with 6 states** (Backlog / Todo / In Progress / In Review / Done / Blocked) — see explanations in §7
  - add fields: `Priority`, `Epic`, `Work Type`, `Story Points`
- Use **draft issues** for unconfirmed backlog / **real issues** for tasks to be implemented and tracked in the repo
- Put **acceptance criteria** in the ticket `body` (as a `- [ ]` checklist) — GitHub Projects v2 has no separate AC field → use a body checklist
- Write **reusable scripts** that prefetch field/option IDs and loop to create items (because of the 2-step flow) → share them in the repo so the team need not memorize GraphQL

## 7) Proposed Project Schema (for DocuMind)

### 7.1 Field schema

| Field | Type | Options |
|---|---|---|
| Status | SINGLE_SELECT (default) | Backlog / Todo / In Progress / In Review / Done / Blocked |
| Priority | SINGLE_SELECT | Low / Medium / High |
| Epic | SINGLE_SELECT | FE / BE / AUTH / INFRA / CRAWLER |
| Work Type | SINGLE_SELECT | Frontend / Backend / Infra / Decision / Test |
| Estimate | TEXT (story points set manually) | 1–13 (story points) |
| Sprint | SINGLE_SELECT | S1 / S2 / S3 / S4 |
| Due Date | DATE | YYYY-MM-DD |

### 7.1b Extra field descriptions (Sprint / Due Date)

| Field | What it's for | How to use | Note |
|---|---|---|---|
| **Sprint** | Group work by sprint round (S1–S4) | Set a value per card, e.g. work in Sprint 1 → choose S1 | Useful to filter / group the board by sprint |
| **Due Date** | Set the delivery / deadline date | Enter a date (YYYY-MM-DD), e.g. 2026-09-20 | Useful to prioritize near-deadline work; draft issues aren't bound to a repo → use this instead of milestone |


### 7.2 Status descriptions

| Status | Meaning | Use when | How to advance |
|---|---|---|---|
| **Backlog** | Queued / not yet scheduled | Task received but not time to do, or waiting to be prioritized | When ready → move to Todo |
| **Todo** | Approved, ready to start | Task is ready to start (has an owner) | Started → In Progress |
| **In Progress** | Currently being worked on | Dev is writing/building it | Finished → In Review (or Done if no review) |
| **In Review** | Under review/QA | Sent for code review / testing before closing | Passed → Done / needs fixes → In Progress |
| **Done** | Complete | All AC met, merge/test passed | Finished (no further moves) |
| **Blocked** | Stuck | Waiting on a decision/resource/another person | Unblocked → back to previous state (e.g. In Progress) |

> 💡 **Usage:** Drag the card across columns as the state changes (Board view). Use **Blocked** instead of leaving work silently in In Progress — you'll see stuck tasks immediately. Changing status is supported by `gh project item-edit --field-id Status --single-select-option-id <option>` (native, works) and the Web UI — look up option-ids via `gh project field-list --format json`.

---

## References

- GitHub Docs — [Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- GitHub CLI manual — `gh project` ([gh_project](https://cli.github.com/manual/gh_project), `item-create`, `item-edit`, `field-create`)
- GitHub Blog — [GitHub CLI project command GA](https://github.blog/developer-skills/github/github-cli-project-command-is-now-generally-available/)
- The file that forms the basis of the **Skill** for the team: this file
