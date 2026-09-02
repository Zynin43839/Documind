# คู่มือเริ่มต้นสำหรับทีม — ต้องอ่านเอกสารอะไรบ้าง

> เอกสารนี้ใช้เป็นจุดเริ่มต้นสำหรับสมาชิกทีมใหม่และทีมเดิม เพื่อรู้ว่าต้องอ่านอะไรก่อนเริ่มงาน
> สรุปโดยย่อ: อ่าน **ลำดับด้านล่างตามบทบาท** แล้วเข้าดูรายละเอียดจากลิงก์

---

## 1) อ่านก่อนเริ่มทุกคน (ขั้นต่ำ)

| ลำดับ | เอกสาร | เนื้อหาโดยย่อ | ที่อยู่ |
|---|---|---|---|
| 1 | **README.md** | ภาพรวมโปรเจกต์ + tech stack + API + architecture | `/README.md` |
| 2 | **คู่มือ GitHub Projects** | วิธีใช้ board, status workflow, วิธีเพิ่ม/ย้าย card | `docs/github-projects-guide.md` |
| 3 | **Template task card** | รูปแบบ card มาตรฐาน (User Story, AC, Metadata) | `docs/task-card-template.md` |

## 2) อ่านตามบทบาท

### Frontend
- `docs/frontend-plan.md` — แผนหน้า UI + mockup
- `docs/index-css-guide.md` — แนวทางการใช้ CSS/design system

### Backend / Database
- `docs/database-plan.md` — โครงสร้างฐานข้อมูล + schema

### ทุกคนที่จัดการงาน (PO / PM / Dev)
- `scripts/import-cards.ps1` — script import card ขึ้น board อัตโนมัติ
- `docs/examples/status-*.md` — ตัวอย่าง card แยกตาม status

## 3) เอกสารภายในทีม (ไม่อยู่ใน GitHub repo — อยู่ในเครื่อง/แชร์)

| เอกสาร | เนื้อหา | หมายเหตุ |
|---|---|---|
| `Mydoc/decisions/DECISION-RECORD-2026-09-02.md` | การตัดสินใจทั้งหมด (D1–D9, API endpoints ครบ) | เป็น "lock" ของทีม — ต้องอ่านก่อนเปลี่ยนแผน |
| `Mydoc/meetings/` | บันทึกประชุม + decision decks | อ่านเมื่อเกี่ยวข้องกับรอบนั้น |
| `Mydoc/reference/` | research/วิเคราะห์เชิงลึก | อ่านเมื่อทำงานเรื่องนั้น |

> ⚠️ ไฟล์กลุ่มนี้ถูก `.gitignore` ไว้ (Mydoc/) — แชร์ผ่านเครื่อง/แชร์ folder กันเอง

---

## 4) กฎที่ทีมต้องรู้

1. **การตัดสินใจที่ "ล็อก" แล้ว (decision record) — อย่าเปลี่ยนเอง** ถ้าจะเปลี่ยนต้องคุยในทีมก่อน
2. **board ใช้ GitHub Projects v2** — status workflow: Backlog → Todo → In Progress → In Review → Done / Blocked
3. **card ใหม่ ใช้ template เดียวกันเสมอ** (`docs/task-card-template.md`)
4. **เอกสาร AGENTS.md / SKILL.md ต้องเป็นภาษาอังกฤษเท่านั้น** (สำหรับ workflow ของ AI ช่วยงาน)
5. **เปลี่ยน schema DB ต้องรัน drizzle generate + migrate** (ห้าม push ตรงๆ)

---

*อัปเดทล่าสุด: 2026-09-02*
