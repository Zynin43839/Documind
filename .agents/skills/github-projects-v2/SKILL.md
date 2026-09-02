---
name: github-projects-v2
description: 'Use GitHub Projects v2 (the github.com/projects planning tool, not the old Projects "classic" boards) to manage the DocuMind team backlog. Use when the user asks to create/manage/edit/query items, fields, or views in a GitHub Project, push a backlog to a board, create draft issues, set Status/Priority/Epic field values, or automate GitHub Projects via gh CLI or the GraphQL API. Triggers on: "GitHub Projects", "gh project", "Project v2", "push backlog to board", "create ticket/item on the GitHub board", "set Status field", "project GraphQL API".'
---

# GitHub Projects v2 — ทีมใช้ร่วมกัน

ใช้จัดการ backlog ของ DocuMind (Epic → Task) บน GitHub Projects v2.
คู่มือฉบับเต็ม: `docs/github-projects-guide.md` (อ่านประกอบก่อนใช้งานจริง)

## Critical Rules

1. **อย่าเดา command/GraphQL จากความจำ** — API/CLI ของ GitHub เปลี่ยนบ่อย ให้เช็ค `gh project --help` / `gh project <subcmd> --help` หรือ docs ก่อนเสมอ
2. **`gh` ต้อง auth ด้วย `project` scope** — ก่อนใช้ ตรวจ `gh auth status`; ถ้าขาด scope `gh auth refresh -s project`
3. **Add + update item แยกกัน** — GitHub ห้าม create item + set field ใน call เดียว → ต้อง `item-create` (หรือ draft) ก่อน แล้วค่อย `item-edit` fields
4. **ต้อง prefetch field ID / option ID** ก่อน set field — ใช้ `gh project field-list` แล้ว reuse ID เดิม
5. **Assignees / Labels / Milestone** ตั้งผ่าน project field ไม่ได้ → ใช้ mutation แยก (`addAssigneesToAssignable`, `addLabelsToLabelable`)
6. **Acceptance Criteria** ไม่มี field แยกใน GH Projects v2 → ใส่เป็น checklist ใน `body` ของ ticket

## 1) Check environment ก่อนเริ่ม

```powershell
# ติดตั้ง gh (ถ้ายังไม่มี)
winget install GitHub.cli

# auth + scope
gh auth login --scopes "project"
gh auth status        # ต้องเห็น project scope
gh auth refresh -s project   # ถ้าขาด scope

# ดู project ที่มี
gh project list --owner "@me"
```

## 2) Command หลัก (ผู้ผลิต ticket)

```powershell
# สร้าง project + ดู fields
gh project create --owner "@me" --title "DocuMind Backlog"
gh project field-list 1 --owner "@me"

# สร้าง field (ครั้งเดียว ตอนตั้ง project)
gh project field-create 1 --owner "@me" --name "Priority" --data-type "SINGLE_SELECT" --single-select-options "Low,Medium,High"
gh project field-create 1 --owner "@me" --name "Epic" --data-type "SINGLE_SELECT" --single-select-options "FE,BE,AUTH,INFRA,CRAWLER"

# สร้าง draft issue (ticket) + ตั้ง field
gh project item-create 1 --owner "@me" --title "Implement login form" --body "- [ ] AC1"
gh project item-edit 1 --owner "@me" --id <item-id> --field "Status" --value "In Progress"
gh project item-edit 1 --owner "@me" --id <item-id> --field "Priority" --value "High"

# ตรวจสอบ
gh project item-list 1 --owner "@me" --field "Status" --field "Priority"
```

## 3) GraphQL API (script/automation) — ใช้เมื่อ gh CLI ครอบไม่ถึง

Token scope: `project` (เขียน) / `read:project` (อ่าน)

### หา project node ID
```powershell
gh api graphql -f query='
  query($user: String! $n: Int!) {
    user(login: $user) { projectV2(number: $n) { id } }
  }' -f user="TEEREDCOM" -F n=1
```

### prefetch field/option ID
```powershell
gh api graphql -f query='
  query {
    node(id: "PROJECT_ID") {
      ... on ProjectV2 {
        fields(first: 20) {
          nodes {
            ... on ProjectV2FieldCommon { id name }
            ... on ProjectV2SingleSelectField { id name options { id name } }
          }
        }
      }
    }
  }'
```

### create draft issue
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

### set single select field (แยก call จาก create)
```powershell
gh api graphql -f query='
  mutation {
    updateProjectV2ItemFieldValue(input: {
      projectId: "PROJECT_ID"
      itemId: "ITEM_ID"
      fieldId: "FIELD_ID"
      value: { singleSelectOptionId: "OPTION_ID" }
    }) { projectV2Item { id } }
  }'
```

### add issue ของ repo เข้า project
```powershell
gh api graphql -f query='
  mutation {
    addProjectV2ItemById(input: {
      projectId: "PROJECT_ID"
      contentId: "ISSUE_NODE_ID"
    }) { item { id } }
  }'
```

## 4) Project Schema ที่แนะนำสำหรับ DocuMind

| Field | Type | Options |
|---|---|---|
| Status | SINGLE_SELECT (default) | Todo / In Progress / Done |
| Priority | SINGLE_SELECT | Low / Medium / High |
| Epic | SINGLE_SELECT | FE / BE / AUTH / INFRA / CRAWLER |
| Type | SINGLE_SELECT | Frontend / Backend / Infra / Decision / Test |
| Estimate | NUMBER | 1–13 (story points) |

## 5) Workflow ที่แนะนำ (วางแผน backlog)

1. อ่าน Template log: `Mydoc/meetings/_TEMPLATE_task-log.md` → กรอก Owner/Estimate/User Story/Acceptance Criteria
2. ตัดสินใจว่า item เป็น **draft** (backlog ยังไม่คอนเฟิร์ม) หรือ **issue จริง** (จะ implement ใน repo)
3. prefetch field/option IDs ครั้งเดียว → loop สร้าง items → set fields
4. ตรวจสอบด้วย `gh project item-list --format=json` + นับจำนวนให้ตรง

## Reference

- `docs/github-projects-guide.md` — คู่มือฉบับเต็ม (ทีม)
- GitHub Docs — Using the API to manage Projects
- `gh project` manual: https://cli.github.com/manual/gh_project
- Blog GA: https://github.blog/developer-skills/github/github-cli-project-command-is-now-generally-available/
