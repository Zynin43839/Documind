# Crawler Quality Plan (MVP: Completion / Coverage)

> สถานะ: **Draft เริ่มต้น** — ยังต้องคุยกับทีมก่อนล็อกการ implement (ดู deck)
> ขอบเขต MVP: ตรวจแค่ **completion / coverage** (ครบไหม ไม่ได้เน้น content quality ยัง)
> แผนนี้ใช้โครงสร้างตารางจาก `docs/database-plan.md` ที่มีอยู่แล้ว (crawl_runs, document_versions, chunks, chunk_embeddings)

---

## 1) หลักการ

- เป้าหมาย MVP: กัน corpus ที่ **ไม่สมบูรณ์** ออกจากระบบ retrieval (เช่น doc ยังไม่มี embed, crawl ค้าง)
- ยัง **ไม่ตรวจ** คุณภาพเชิงความหมายของเนื้อหา (เช่น chunk สั้นเกิน/ยาวเกิน, HTML เลอะ) — เป็นงาน phase ต่อไป (ต้องตกลงเกณฑ์กับทีมก่อน)
- ใช้ข้อมูลที่ schema รองรับอยู่แล้ว → ไม่ต้องแก้ schema เพิ่มตอนนี้

## 2) ระดับการตรวจ (3 ระดับ)

### Level 1 — Doc Fetch ครบไหม

| เช็ค | เงื่อนไข | ผ่าน / ไม่ผ่าน |
|---|---|---|
| หน้าเพจถูก fetch | `crawl_runs.pages_processed >= pages_discovered` (หรือเทียบกับที่คาด) | ผ่านเมื่อครบ |
| มี content จริง | `document_versions.content` ไม่ว่าง / ไม่ต่ำกว่า threshold ขั้นต่ำ (เริ่ม: > 0 chars) | ไม่ผ่าน → flag |
| มี version ใหม่ครบ | ทุก `documents` ที่เจอ มี `document_versions` อย่างน้อย 1 อัน | ไม่ผ่าน → flag |

### Level 2 — Chunk ครบไหม

| เช็ค | เงื่อนไข |
|---|---|
| ทุก version ถูก chunk | ทุก `document_versions` มี `chunks` ≥ 1 |
| chunk มี ordinal ต่อเนื่อง | `chunks.ordinal` เรียง 0,1,2... ไม่มีช่องว่าง (ตาม `chunks_version_ordinal_idx`) |

### Level 3 — Embed ครบไหม (สำคัญสุด)

| เช็ค | เงื่อนไข | ผ่านเมื่อ |
|---|---|---|
| ทุก chunk มี embed | ทุก `chunks` มี row ใน `chunk_embeddings` (ตาม model ที่ใช้) | coverage = 100% |
| embed มิติถูก | `embedding` เป็น `vector(768)` ตามที่ schema กำหนด | ทั้งหมด |
| is_current ชี้ version ที่ embed ครบ | version ที่ถูกตั้ง `is_current=true` ต้องมี chunks + embeddings ครบก่อน (ตาม database-plan: "Mark current only after chunks/embeddings available") | ผ่านเสมอ |

## 3) ตัวตรวจ (เครื่องมือ)

เริ่มจาก **SQL checks** (รันผ่าน Supabase / script) เพื่อดู completion ต่อ source:

```sql
-- 1. ทุก doc มี version ครบไหม
SELECT d.id, d.canonical_url,
       COUNT(v.id) AS version_count
FROM documents d
LEFT JOIN document_versions v ON v.document_id = d.id
GROUP BY d.id, d.canonical_url
HAVING COUNT(v.id) = 0;

-- 2. ทุก version มี chunk ครบไหม
SELECT v.id, COUNT(c.id) AS chunk_count
FROM document_versions v
LEFT JOIN chunks c ON c.document_version_id = v.id
GROUP BY v.id
HAVING COUNT(c.id) = 0;

-- 3. ทุก chunk มี embed ครบไหม (coverage หลัก)
SELECT c.id
FROM chunks c
LEFT JOIN chunk_embeddings e ON e.chunk_id = c.id
GROUP BY c.id
HAVING COUNT(e.id) = 0;
```

> ยังไม่เขียนเป็น script/endpoint ตัวจริง — phase นี้แค่เอกสารแผน + SQL สำหรับตรวจมือ

## 4) สิ่งที่ "ไม่ทำ" ใน MVP (รอตกลงทีม)

- ❌ เกณฑ์คุณภาพเนื้อหา (min chars, token range, HTML เลอะ, heading_path หลุด)
- ❌ Automated gate ใน pipeline (block การ publish ถ้าไม่ผ่าน) — ยังเปิดไว้ใน deck ให้ทีมตัดสินใจ
- ❌ Dashboard / `GET /crawler/status` ต่อของจริง (endpoint ประกาศไว้แล้วใน decision record §3A แต่ implement รอ)

## 5) การตัดสินใจที่ต้องถามทีม (อยู่ใน deck)

1. ควรทำ **automated gate** ใน pipeline ไหม (หรือเริ่มแค่ report)?
2. ใครเป็นคนรับผิดชอบรัน QC + ไล่แก้? (ถือเป็น task บน board?)
3. เกณฑ์คุณภาพเนื้อหาควรเริ่มใช้ตอนไหน (phase 2)?

---

อัปเดตล่าสุด: 2026-09-02
