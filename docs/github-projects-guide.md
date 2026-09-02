# GitHub Projects v2 — คู่มือใช้ในทีม DocuMind

> สถานะ: สรุป 2026-09-02 · field-NOV ประกอบ Skill `github-projects-v2`
> เป้า: ให้ทุกคนในทีมผลิต/จัดการ backlog (Epic → Task → Subtask) บน GitHub Projects v2 ได้เอง ทั้งผ่าน Web UI, `gh` CLI และ GraphQL API

## 1) ภาพรวม 3 ระดับการใช้งาน

| วิธี | ใครใช้ | จุดเด่น | ต้องมีอะไร |
|---|---|---|---|
| **Web UI** (github.com/projects) | ทุกคนในทีม | สร้าง/ลาก/กรองง่าย ไม่ต้องโค้ด | แค่บัญชี GitHub |
| **`gh` CLI** | ผู้ผลิต ticket / script | ทำซ้ำได้, JSON output เอาไป pipe | ติดตั้ง gh + auth `project` scope |
| **GraphQL API** | automation / script ขั้นสูง | ควบคุมทุกอย่าง (fields, items), 1 สาย API | PAT / GH App token |

## 2) ติดตั้ง + Auth (ทำครั้งแรก)

```powershell
# ติดตั้ง gh CLI (ถ้ายังไม่มี)
winget install GitHub.cli

# Auth — สำคัญมาก: ต้องมี project scope
gh auth login --scopes "project"

# ตรวจสอบว่า scope ครบไหม
gh auth status

# ถ้าขาด scope ให้เพิ่ม (ไม่ต้อง re-login หมด)
gh auth refresh -s project
```

> **✅ สถานะ ณ 2026-09-02:** ติดตั้ง `gh` CLI แล้ว (v2.98.0) และ logged in แล้วเป็น **Zynin43839** (scopes: `gist`, `project`, `read:org`, `repo`) — พร้อมใช้ CLI/script ได้ทันที
> Token scope ขั้นต่ำ: `project` (อ่าน+เขียน) หรือ `read:project` (อ่านอย่างเดียว)

## 3) Command หลัก (ผู้ผลิต ticket)

```powershell
# 1) สร้าง project
gh project create --owner "@me" --title "DocuMind Backlog"

# 2) ดู fields ที่มี — ต้องรู้ field ID ก่อน set value
# ใช้ --format json จะได้ทั้ง field-id และ option-id (จำเป็นสำหรับ item-edit)
gh project field-list 1 --owner "@me" --format json

# 3) สร้าง field ใหม่ (เช่น Priority / Epic / Work Type / Estimate)
# ⚠️ อย่าใช้ชื่อ "Type" (ติดชื่อสงวนใน UI) — board ใช้ชื่อ "Estimate" (TEXT / story points ตั้งเอง)
gh project field-create 1 --owner "@me" --name "Priority" --data-type "SINGLE_SELECT" --single-select-options "Low,Medium,High"
gh project field-create 1 --owner "@me" --name "Epic" --data-type "SINGLE_SELECT" --single-select-options "FE,BE,AUTH,INFRA,CRAWLER"
gh project field-create 1 --owner "@me" --name "Work Type" --data-type "SINGLE_SELECT" --single-select-options "Frontend,Backend,Infra,Decision,Test"
gh project field-create 1 --owner "@me" --name "Estimate" --data-type "TEXT"

# 4) สร้าง draft issue (ticket) เข้า project
# body ที่เป็นแค่บรรทัดเดียว
gh project item-create 1 --owner "@me" --title "Implement login form" --body "..."

# body หลายบรรทัด (มี checklist AC) — เก็บในตัวแปร single-quoted here-string เพื่อกัน PowerShell ตีความ
$body = @'
In base as a dev, I want X so that Y.

## Acceptance Criteria
- [ ] AC1
- [ ] AC2
'@
gh project item-create 1 --owner "@me" --title "TASK TITLE" --body $body

# 5) แก้ field บน item (Status / Priority / Epic ...)
# ⚠️ ไม่มีทางใช้ --field กับ --id พร้อมกัน — ต้องระบุ field-id + option-id (ID) แบบ machine-friendly
gh project item-edit --owner "@me" --id <item-id> --project-id <project-id> `
  --field-id <field-id> --single-select-option-id <option-id>

# example: set Priority=High, Epic=BE, Work Type=Backend บน item
gh project item-edit --owner "@me" --id PVTI_xxxx --project-id PVT_yyyy `
  --field-id PVTSSF_priority --single-select-option-id 993039bb      # High
gh project item-edit --owner "@me" --id PVTI_xxxx --project-id PVT_yyyy `
  --field-id PVTSSF_epic --single-select-option-id a20e7ca7          # BE
gh project item-edit --owner "@me" --id PVTI_xxxx --project-id PVT_yyyy `
  --field-id PVTSSF_worktype --single-select-option-id c8dbb666      # Backend

# 6) ตรวจสอบ items + field (field-list --format json ยืนยัน option-ID ที่ถูกต้อง)
gh project item-list 1 --owner "@me" --format json
```

### Command อื่นที่ใช้ประจำ

```powershell
gh project list --owner "@me"                    # ดูทุก project
gh project item-list 1 --format=json             # export ไป report/script
gh project item-create 1 --owner "@me" --title "Task" --body "AC: ..."   # สร้าง task
gh project item-archive 1 --owner "@me" --id <item-id> # เก็บ item ที่จบ (ใช้ item-id PVTI_)
gh project item-archive 1 --owner "@me" --id <item-id> --undo # ยกเลิกการ archive กลับมา
gh project field-delete 1 --id <fieldId>         # ลบ field — ⚠️ ไม่มี flag --owner (ใช้ได้เฉพาะ --id)
gh project delete 1 --owner "@me"                # ลบทั้ง project
```

## 4) การใช้งานผ่าน GraphQL API (สำหรับ script/automation)

GitHub Projects v2 ขับด้วย **GraphQL**. ตัวอย่าง flow สำคัญ (อ้างอิง docs.github.com):

### 4.1 หา node ID ของ project

```powershell
gh api graphql -f query='
  query($user: String! $n: Int!) {
    user(login: $user) { projectV2(number: $n) { id } }
  }' -f user="TEEREDCOM" -F n=1
```

### 4.2 หา field ID + option ID (ต้อง prefetch ก่อน set field)

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

> ระบบต้องจำ `field id` + `option id` — ทำครั้งเดียวแล้ว reuse ซ้ำได้ (ไม่ต้อง query ทุกครั้ง)

### 4.3 เพิ่ม draft issue

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

### 4.4 Set field value (ต้องทำคนละ call กับ create)

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

### 4.5 Add issue ของ repo เข้า project

```powershell
gh api graphql -f query='
  mutation {
    addProjectV2ItemById(input: {
      projectId: "PROJECT_ID"
      contentId: "ISSUE_NODE_ID"
    }) { item { id } }
  }'
```

### ⚠️ เตือน error ที่พบจริง (เทส 2026-09-02) — ใช้ CLI native ดีกว่า GraphQL มือ

| อาการ | สาเหตุ | วิธีแก้ที่ใช้ได้จริง |
|---|---|---|
| `HTTP 502` บน `addProjectV2DraftIssue` / `updateProjectV2ItemFieldValue` via `-f query=` | payload ผ่าน `-f query=` บน Windows/PowerShell ถูกทำ quote ใน node-id หลุด (ส่ง `PVT_..` ไม่มี `"`) | ใช้ `gh project item-create` / `item-edit` (CLI native) แทน — CLI ทำ GraphQL ให้เอง ไม่เจอ 502 |
| `Argument 'id' ... Expected type 'ID!'` | node-id ถูกส่งโดยไร้ quote | อย่า inline id ใน `-f query=` |
| `--field cannot be used with --id` | `gh project item-edit` ห้าม `--field`+`--id` พร้อมกัน | ใช้ `--field-id` + `--single-select-option-id` + `--project-id` + `--id <item-id PVTI_>` |
| `--id` ต้องเป็น draft content `DI_` (เมื่อใส่ title/body) | ถ้าใส่ `--title`/`--body` พร้อมกัน gh ตีความ `--id` เป็น draft content id | ตั้ง field แยก call (ไม่ใส่ title/body) → ใช้ item-id `PVTI_` |
| `HTTP 502` บน `updateProjectV2SingleSelectFieldOptions` (เพิ่ม option เข้า field เดิม) | mutation แก้ options ถูก server ตีกลับ 502 — ทดสอบแล้วผ่านทั้ง `gh api graphql` และ `curl` ตรง (แม้ query ธรรมดาผ่าน `gh api graphql` จะทำงาน) | **ไม่มี CLI-native** สำหรับเพิ่ม option → ต้องทำผ่าน Web UI (ดูด้านล่าง) |

> ### 🔧 เพิ่ม option ใหม่ใน field ที่มีอยู่ (เช่น เพิ่มคอลัมน์ "Brain storm" ใน Status) — ต้องผ่าน Web UI
>
> **ข้อจำกัด:** `gh project` มีแค่ `field-create` / `field-delete` (สร้าง/ลบ field ทั้งก้อน) — **ไม่มีคำสั่งเพิ่ม option เข้า field เดิม**. mutation `updateProjectV2SingleSelectFieldOptions` ติด 502 บนเครื่องนี้ จึงต้องทำผ่านเว็บ
>
> **ขั้นตอน Web UI (เพิ่ม status option ใหม่):**
> 1. เปิดโปรเจกต์ Documind → มุมขวาบนกดเมนู `⋮⋮` → **Settings**
> 2. ทางซ้ายเลือก field **`Status`** (หรือ field ที่ต้องการ)
> 3. กลางหน้าจะเห็น options (Todo / In Progress / Done ...)
> 4. กด **+ Add option** → พิมพ์ชื่อใหม่ (เช่น `Brain storm`) → **Save**
> 5. กลับ board view → คอลัมน์ใหม่ขึ้นทันที (refresh ถ้าจำเป็น)
>
> > 💡 board (Board view) เรียงคอลัมน์ตาม **Status field** — เพิ่ม option ใน Status = ได้คอลัมน์ใหม่บน board

> **สรุปแนวปฏิบัติ (จากที่เทสสำเร็จ 2026-09-02):**
> 1. สร้าง item ด้วย `gh project item-create` (native) → ได้ item-id `PVTI_`
> 2. ตั้ง field ด้วย `gh project item-edit --id <PVTI_> --project-id <PVT_> --field-id <PVTSSF_> --single-select-option-id <option>` —
>    **ต้อง** prefetch option-id จาก `gh project field-list --format json` ก่อน
> 3. ตรวจกับ `gh project item-list --format json`

### ✅ บันทึกผลเทสจริง 2026-09-02 (ทุกคำสั่งผ่านแล้ว)

> ทดสอบจริงบนโปรเจกต์ Documind (#2) / โปรเจกต์ทดลองชั่วคราว (สร้างแล้วลบ) — crud ทุกคำสั่งใช้ได้

| หมวด | คำสั่ง | ผล |
|---|---|---|
| CREATE | `gh project create --owner "@me" --title "..." --format json` | ✅ สร้างได้ แล้วลบออก |
| CREATE | `gh project field-create 2 --owner "@me" --name "Sprint" --data-type "SINGLE_SELECT" --single-select-options "S1,S2,S3,S4"` | ✅ สร้าง field ได้ แล้วลบออก |
| CREATE | `gh project item-create 2 --owner "@me" --title "..." --body "..."` | ✅ สร้าง draft issue ได้ |
| READ | `gh project list --owner "@me"` | ✅ |
| READ | `gh project field-list 2 --owner "@me" --format json` | ✅ ได้ field-id + option-id |
| READ | `gh project item-list 2 --owner "@me" --format json` | ✅ |
| UPDATE | `gh project item-edit --owner "@me" --id <PVTI_> --project-id <PVT_> --field-id <PVTSSF_> --single-select-option-id <oid>` | ✅ set field ได้ |
| UPDATE | `gh project item-edit 2 --owner "@me" --id <DI_> --title "..." --body "..."` | ✅ update title/body (ต้องใช้ content id `DI_`) |
| UPDATE | `gh project item-archive 2 --owner "@me" --id <PVTI_>` และ `--undo` | ✅ archive + unarchive ได้ |
| DELETE | `gh project field-delete 2 --id <fieldId>` | ✅ (ไม่มี flag `--owner`) |
| DELETE | `gh project delete 3 --owner "@me"` | ✅ ลบโปรเจกต์ได้ |

> **Note:** `field-delete` ไม่รับ `--owner` — ตอน doc เดิมเขียน `--owner` จะ error `unknown flag: --owner`

## 5) ⚠️ ข้อจำกัดสำคัญ (รู้ไว้ก่อนวางแผน)

| # | ข้อจำกัด | ผลกระทบ | วิธีรับมือ |
|---|---|---|---|
| 1 | **Add + update แยกกัน** — GitHub ห้าม create item + set field ใน call เดียว | 1 ticket = อย่างน้อย 2 API call (create แล้วค่อย set) | ทำ script prefetch field/option ID แล้ว reuse; loop ต่อ item |
| 2 | **Field ID / option ID ต้อง prefetch** | ต้อง know ID ก่อน set ทุกครั้ง | query ครั้งเดียวแล้ว cache |
| 3 | **Draft issue vs Issue จริง** — draft = ticket ลอย (ไม่ผูก repo), issue จริง dataset ผูกกับ repo | เลือกตามเป้า: draft สำหรับ backlog ที่ยังไม่คอนเฟิร์ม, issue สำหรับ track ใน code | งาน implementation ใช้ issue จริง (ใน repo), backlog วางแผนใช้ draft |
| 4 | **Assignees / Labels / Milestone** ตั้งผ่าน project field ไม่ได้ | ต้องใช้ mutation แยก (addAssigneesToAssignable / addLabelsToLabelable) | ใช้เฉพาะถ้าจำเป็นจริง |
| 5 | **ไม่มี subtask/dependency native** ใน project items | ไม่มี native hierarchy เหมือน Linear | ใช้ sub-issues (GitHub issue parent/child) หรือ checklist ใน body; dependency ใช้ `dependent_on` ไม่มี → ใช้ manual/labels |

## 6) แนวทางที่แนะนำสำหรับ DocuMind

- ใช้ **Status field 6 สถานะ** (Backlog / Todo / In Progress / In Review / Done / Blocked) — ดูคำอธิบายแต่ละสถานะใน §7
  - เพิ่ม fields: `Priority`, `Epic`, `Work Type`, `Estimate`
- ใช้ **draft issue** สำหรับ backlog ที่ยังไม่คอนเฟิร์ม / **issue จริง** สำหรับ task ที่จะ implement แล้วต้องการ track ใน repo
- **Acceptance criteria** ใส่ใน `body` ของ ticket (เป็น checklist `- [ ]`) — GitHub Projects v2 ไม่มี field AC แยก → ใช้ body checklist
- เขียน **script reusable** ที่ prefetch field/option ID แล้ว loop สร้าง items (เพราะ 2-step) → แจกใน repo เพื่อให้ทีมไม่ต้องจำ GraphQL

## 7) ตัวอย่าง project schema ที่เสนอ (สำหรับ DocuMind)

### 7.1 Field schema

| Field | Type | Options |
|---|---|---|
| Status | SINGLE_SELECT (default) | Backlog / Todo / In Progress / In Review / Done / Blocked |
| Priority | SINGLE_SELECT | Low / Medium / High |
| Epic | SINGLE_SELECT | FE / BE / AUTH / INFRA / CRAWLER |
| Work Type | SINGLE_SELECT | Frontend / Backend / Infra / Decision / Test |
| Estimate | TEXT (story points ตั้งเอง) | 1–13 (story points) |
| Sprint | SINGLE_SELECT | S1 / S2 / S3 / S4 |
| Due Date | DATE | YYYY-MM-DD |

### 7.1b คำอธิบาย field เพิ่มเติม (Sprint / Due Date)

| Field | ใช้ทำอะไร | ใช้ยังไง | หมายเหตุ |
|---|---|---|---|
| **Sprint** | จัดกลุ่มงานตามรอบ sprint (S1–S4) | เลือกค่าเป็นราย card เช่น งานใน Sprint 1 เลือก S1 | ใช้กรอง/จัดกลุ่ม board ตาม sprint ได้ |
| **Due Date** | กำหนดวันส่งงาน/กำหนดส่ง (deadline) | ระบุวันที่ (YYYY-MM-DD) เช่น 2026-09-20 | ใช้เร่งงานใกล้ deadline; draft issue ไม่ผูก repo → ใช้ field นี้แทน milestone |


### 7.2 คำอธิบายแต่ละสถานะ (Status)

| สถานะ | ความหมาย | ใช้เมื่อ | ส่งต่อความคืบหน้าอย่างไร |
|---|---|---|---|
| **Backlog** | อยู่ในคิว/ยังไม่จัดทำ | งานรับมาแต่ยังไม่ถึงเวลาทำ หรือรอจัดลำดับ | พอพร้อมทำ → เปลี่ยนเป็น Todo |
| **Todo** | อนุมัติแล้ว รอเริ่ม | งานพร้อมเริ่มทำ (มีใครรับผิดชอบแล้ว) | เริ่มทำ → In Progress |
| **In Progress** | กำลังทำอยู่ | dev กำลังเขียน/ทำอยู่ | เสร็จ → In Review (หรือ Done ถ้าไม่มี review) |
| **In Review** | ตรวจสอบ/QA | ส่ง code review / ทดสอบก่อนปิด | ผ่าน → Done / มีจุดแก้ → In Progress |
| **Done** | เสร็จสมบูรณ์ | AC ผ่านครบ, merge/test ผ่าน | จบ (ไม่ต้องขยับต่อ) |
| **Blocked** | ติดขัด | ต้องรอ decision/resource/คนอื่น | ปลดล็อกแล้ว → กลับสถานะเดิม (เช่น In Progress) |

> 💡 **หลักการใช้:** ลาก card ไปตามคอลัมน์เมื่อสถานะเปลี่ยน (Board view). ใช้ **Blocked** แทนปล่อยค้างใน In Progress เงียบ ๆ — จะเห็นงานติดได้ทันที. การเปลี่ยนสถานะรองรับด้วย `gh project item-edit --field-id Status --single-select-option-id <option>` (native, ใช้ได้) และ Web UI — ผู้อ้างอิง option-id จาก `gh project field-list --format json`.

---

## อ้างอิง

- GitHub Docs — [Using the API to manage Projects](https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects)
- GitHub CLI manual — `gh project` ([gh_project](https://cli.github.com/manual/gh_project), `item-create`, `item-edit`, `field-create`)
- GitHub Blog — [GitHub CLI project command GA](https://github.blog/developer-skills/github/github-cli-project-command-is-now-generally-available/)
- แฟ้มที่จะประกอบเป็น **Skill** สำหรับทีม: อ้างอิงตามไฟล์นี้
