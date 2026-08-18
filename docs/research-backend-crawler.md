# Research Notes — Backend และ Crawler

> เอกสารสรุปผลการวิจัย backend + crawler ของโปรเจกต์ DocuMind (อัปเดต: 17 ส.ค. 2026)
> ครอบคลุม: สถาปัตยกรรม Express, Supabase Auth/RLS, การ stream คำตอบ (SSE), pgvector retrieval, สถาปัตยกรรม crawler, และการวิเคราะห์ข้อดีข้อเสียของ research ครั้งก่อน

## สถานะปัจจุบันของโปรเจกต์

- `server/` — Express + TypeScript (`tsx`), dependencies: `@supabase/supabase-js`, `@google/generative-ai`, `cors`, `dotenv` มีแค่ `index.ts` (health check) + โฟลเดอร์ scaffold `controllers/ models/ routes/ services/ middleware/ utils/ __tests__` (`.gitkeep`)
- `crawler/` — TypeScript + `playwright` ยังว่าง มีแค่โฟลเดอร์ scaffold `crawlers/ processors/ __tests__`
- `docs/database-plan.md` — schema เต็มรูปแล้ว (Supabase + pgvector, Drizzle, RLS, RPC) เป็นเสาหลักที่ backend/crawler ต้องสร้างตาม
- `docs/research-notes.md` — research รอบก่อน (ฟอนต์, Thai typography, Thai RAG, i18n, Gemini embeddings)

---

## 1. Backend: สถาปัตยกรรม Express

### 1.1 โครงสร้างโฟลเดอร์ (ตาม scaffold ที่มีอยู่)

```
server/src/
  index.ts          # bootstrap: express, cors, json, mount routes
  routes/           # กำหนดเส้นทาง API → delegate ไป controller
  controllers/      # จัดการ HTTP (req/res) ไม่มี business logic
  services/         # business logic: auth, chat, retrieval, crawl ingestion
  middleware/       # validateJwt, errorHandler, rateLimit
  models/           # types / Zod schemas (contracts)
  utils/            # helpers ทั่วไป
  __tests__/        # vitest
```

### 1.2 รูปแบบที่แนะนำ (จาก research)

- **Controllers บาง, Services หนา** — controller จัดการ HTTP เท่านั้น (parse body, เรียก service, ส่ง response), logic อยู่ service (ทดสอบง่าย ไม่ต้อง mock HTTP)
- **Zod สำหรับ validate ที่ boundary** — validate ทุก input ก่อนเข้าสู่ business logic โดยเฉพาะ prompt ของ user (ความยาว, type) ก่อนเข้าสู่ LLM
- **แยก transport ออกจาก domain** — เส้นทาง streaming (SSE) ต้องแยกจากเส้นทางปกติ เพราะ error handling ต่างกัน (mid-stream เปลี่ยน status code ไม่ได้)
- **Error handling กลาง** — error middleware สุดท้าย แปลง error → JSON ตาม format ที่ตกลง; อย่าให้ raw DB error หลุดไป client

---

## 2. Supabase Auth + RLS (หลักการที่ต้องยึด)

สรุปจาก research (มีผลโดยตรงกับ `database-plan.md` ที่เขียนไว้แล้ว):

### 2.1 กฎเหล็กเรื่อง key

| Key | ใช้ที่ไหน | หมายเหตุ |
|---|---|---|
| `anon` key | client + Express (เชื่อมต่อแบบ user JWT) | RLS ยังทำงาน ตาม `auth.uid()` |
| `service_role` key | **server-side เท่านั้น** (crawler, cron, admin) | bypass RLS ทั้งหมด — ห้ามเด็ดขาดใน browser |

- `service_role` ต้องไม่ขึ้น client bundle; ใช้เฉพาะเส้นทาง admin ที่พิสูจน์ตัวตนแล้ว (crawler ingestion, webhook, scheduled job)
- **ข้อควรระวัง**: แม้ใช้ `service_role` ใน Express ก็ต้อง validate ว่า request มาจากใครก่อน (service_role เป็นแค่ key ของ DB ไม่ใช่ authorization grant)

### 2.2 verify user บน server

- **ใช้ `auth.getUser()` ไม่ใช่ `auth.getSession()`** — `getUser()` ตรวจ JWT กับ Supabase จริง (เครือข่าย 1 รอบ), `getSession()` แค่อ่าน token จาก cookie/localStorage โดยไม่ verify → ปลอมได้
- สร้าง middleware `validateJwt`: ดึง Bearer token จาก header → `supabase.auth.getUser()` → เก็บ `user` ลง `req` → 401 ถ้าไม่มี
- RLS เป็นเกราะสุดท้าย — แม้ app logic พลาด `where user_id` DB ก็ยังบังคับด้วย `WITH CHECK`

### 2.3 RLS (ตรงกับ database-plan.md อยู่แล้ว)

- เปิด RLS ทุกตาราง (default deny-all) แล้วค่อยเขียน policy
- user อ่านได้เฉพาะของตัวเอง: `conversations`, `messages`, `retrieval_*`, `citations` (โดย `user_id = auth.uid()`)
- `profiles`: user อ่าน/แก้เฉพาะของตัวเอง
- browser client ห้ามสร้าง `assistant messages`, `citations`, `retrieval_*`, corpus tables (`documentation_sources`, `documents`, `chunks`, `embeddings`) — corpus ผ่าน Express/guarded RPC เท่านั้น
- ใช้ `(select auth.uid())` แทน `auth.uid()` เปล่า เพื่อให้ planner ทำ initPlan คำนวณครั้งเดียว (perf)
- `UPDATE` ต้องมีทั้ง `USING` + `WITH CHECK` (กันปลอมแปลง `user_id`)

---

## 3. การ stream คำตอบ (SSE)

Flow ที่แนะนำ: **browser → Express POST → Gemini stream → Express forward SSE → browser**

### 3.1 ทำไมต้องมี Express อยู่ตรงกลาง

- ไม่ expose `GEMINI_API_KEY` ให้ browser
- ตรงนี้คือที่ตรวจ auth (JWT), rate limit, validate input, log usage
- ตรงนี้คือที่เก็บ `messages`/`retrieval_runs` ลง DB ก่อน/หลัง stream

### 3.2 ข้อกำหนดการส่ง SSE

```http
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
X-Accel-Buffering: no     # บอก nginx ห้าม buffer
```

สำคัญที่สุด:
- **`X-Accel-Buffering: no`** — nginx/proxy บuffer อยู่แล้วโดย default → stream กลายเป็นก้อนเดียว (พัง)
- **`req.on('close')` → abort upstream** — user ปิด tab กลางคัน ต้อง cancel token ที่กำลังเสียเงิน
- timeout: default proxy 30s จะตัด stream ยาว — ตั้ง `proxy_read_timeout` ให้ยาวกว่า response ยาวสุด
- gzip middleware/compression **ต้อง exclude เส้นทาง stream** (จะ buffer ทั้งหมด)

### 3.3 รูปแบบ SSE event (ทำให้ client แยกสถานะได้)

ไม่ควรส่ง raw token อย่างเดียว ใช้ named events:

```text
event: status   data: {"phase": "thinking"|"typing"}
event: delta    data: {"text": "..."}
event: done     data: {}
event: error    data: {"message": "..."}
```

เหตุผล: client ต้องแยกได้ว่า "ยังพิมพ์อยู่" vs "จบแล้ว" vs "error กลางคัน" — หลัง stream เริ่มแล้ว status code เปลี่ยนไม่ได้ (เป็น 200 ไปแล้ว) ต้องส่ง error เป็น event

### 3.4 ฝั่ง client

- ใช้ `fetch` + `ReadableStream` reader (POST + Authorization header ได้) — **EventSource ไม่พอ** เพราะเป็น GET เท่านั้น ส่ง header ไม่ได้
- buffering ครึ่ง frame: `buffer.split('\n\n')` เก็บ tail ไว้สำหรับ chunk ถัดไป (chunk boundary อาจตัดกลาง frame)
- `AbortController` สำหรับปุ่ม stop / ส่งคำถามใหม่ (กัน ghost updates)
- แยกสถานะ `aborted` (user intent) กับ `error` (failure) — aborted ไม่ต้องโชว์ red banner

### 3.5 Gemini SDK (JS)

- ใช้แพ็กเกจ `@google/genai` (รุ่นใหม่กว่า `@google/generative-ai` ที่อยู่ใน package.json — ควรอัปเกรด)
- streaming: `client.models.generateContentStream({ model, contents })` → `for await (const chunk of stream)` → `chunk.text`
- **pin SDK version < 3.0.0** (รุ่นถัดไปตัด Node <22 และเปลี่ยน API) — ตอนนี้ Node ต้อง ≥ 20
- เก็บ `usage`/token count จาก final chunk หลัง stream จบ (ประเมิน cost)
- mid-stream error: abort ฝั่ง Gemini ทันที แล้วส่ง `event: error`

---

## 4. pgvector Retrieval (ต่อจาก database-plan.md)

### 4.1 RPC `match_documentations` (guard ผ่าน server)

- PostgREST ไม่รองรับ operator ของ pgvector → ต้อง wrap ใน function แล้วเรียกด้วย `rpc()`
- **ใช้ cosine distance `<=>`** — คำนวณ similarity = `1 - distance`
- **`ORDER BY` ต้อง sort ด้วย distance ตรงๆ (asc) ไม่ใช่ `1 - distance`** — ไม่งั้น index ไม่ถูกใช้ (ปัญหาจริงที่เจอบ่อย)
- `match_count` จำกัดช่วง (เช่น 1–20) กัน abuse
- ใช้ embeddings จาก **โมเดลเดียวกัน** เท่านั้น (เปรียบต่างคนละโมเดลไม่มีความหมาย)

```sql
-- ตัวอย่างแนวทาง (ปรับตาม schema จริง)
create or replace function match_documentation_chunks (
  query_embedding vector(768),
  match_count int default 5,
  similarity_threshold float default 0.7
) returns table (
  chunk_id uuid, content text, heading_path text[],
  source_url text, source_title text, similarity float
)
language sql stable
as $$
  select
    c.id, c.content, c.heading_path,
    d.canonical_url, s.name,
    1 - (ce.embedding <=> query_embedding) as similarity
  from chunk_embeddings ce
  join chunks c on c.id = ce.chunk_id
  join document_versions dv on dv.id = c.document_version_id and dv.is_current
  join documents d on d.id = dv.document_id and d.status = 'active'
  join documentation_sources s on s.id = d.source_id and s.status = 'active'
  where 1 - (ce.embedding <=> query_embedding) > similarity_threshold
  order by ce.embedding <=> query_embedding
  limit match_count;
$$;
```

### 4.2 Index

- corpus เล็ก (MVP) → exact cosine scan พอได้ (database-plan.md ถูกต้อง)
- เพิ่ม HNSW index (`chunk_embeddings_hnsw_cosine_idx`) เมื่อ corpus ใหญ่จริง หลังวัด latency แล้ว
- ถ้าใช้ index + filter ด้วย column อื่น → อาจได้แถวน้อยกว่า `LIMIT` ที่ขอ (index scan ไม่ guarantee จำนวน) — ต้องระวัง

### 4.3 Retrieval pipeline (server-side ทั้งหมด)

1. user send → validate → บันทึก user message (ก่อน generate)
2. embed query: `gemini-embedding` + `task_type: RETRIEVAL_QUERY` (ตาม research-notes)
3. `rpc('match_documentation_chunks', ...)` → top-5
4. เก็บ `retrieval_runs` + `retrieval_results` (ทุก chunk ที่ได้ ไม่เฉพาะที่ cite)
5. สร้าง prompt (context + question) → Gemini stream
6. stream จบ → บันทึก assistant message + `message_citations`
7. mark version `is_current` **หลัง** chunks+embeddings พร้อม (ตรง database-plan.md)

---

## 5. Crawler: สถาปัตยกรรม

### 5.1 ลำดับการทำงาน (best practice จาก research)

```
1. fetch robots.txt  → อ่าน Sitemap: + Disallow + Crawl-delay
2. walk sitemap(s)   → รายการ URL หน้า content (recursive ถ้าเป็น sitemap index)
3. fallback BFS      → ถ้าไม่มี sitemap: เริ่มจาก root_url, เดินตาม <a href> same-origin, depth 3, cap 200
4. URL normalization → strip fragment, ตัด trailing slash, ตัด ?utm_*, dedup
5. fetch + render    → Playwright networkidle, กัน cookie banner
6. extract content   → เอาแค่ main content, ตัด nav/header/footer
7. chunk + embed     → 400/80, tokenize ไทย (ตาม research-notes)
8. เก็บลง DB         → documents → document_versions → chunks → chunk_embeddings
9. update crawl_runs → counters, status
```

### 5.2 Discovery: sitemap ก่อน, BFS เป็น fallback

- **sitemap.xml** คือแหล่ง URL ที่แม่นสุด (authoritative, เร็ว ไม่ต้อง render) — docs sites ส่วนใหญ่มี
- **robots.txt** เป็นที่บอก `Sitemap:` และ `Disallow:` — ต้องอ่านก่อนเสมอ (compliance)
- **BFS fallback** เมื่อไม่มี sitemap — จำกัด depth + cap กันเปิดกว้าง
- URL ที่เจอทุกทางต้องผ่าน normalization ก่อน dedup
- docs หลายเว็บมีเวอร์ชันแปล (`/de/`, `/ja/`) — ต้องมีกลไก exclude (เช่น ตาม `version_label` ของ source)

### 5.3 การ render + extract เนื้อหา

- docs sites เป็น SPA/SSR ผสม → ใช้ Playwright รอ `networkidle` (รอ JS render จบ) ก่อนเก็บ
- **กัน cookie/consent banner** — ทำครั้งเดียวที่ entry URL (หา button "Accept" ผ่าน label patterns หรือ LLM) แล้ว reuse session context ตลอด crawl
- **extract เฉพาะ main content** — nav/header/footer ซ้ำทุกหน้า → pollute embeddings ถ้าไม่ตัด (research อ้างว่าบางหน้า content สั้นมาก nav จะแทรกแซง)
- Node ฝั่ง ใช้ library แยก HTML อย่าง `cheerio` หรือ extraction lib (research อ้างอิงฝั่ง Python คือ trafilatura; ฝั่ง Node มีตัวเลือกเช่น `@mozilla/readability`)
- PDF: ถ้าเจอใน scope ให้ดาวน์โหลด + extract text (lib ภาษาไทยระวัง encoding — ดู research-notes §3)

### 5.4 Concurrency + politeness (สำคัญสำหรับ docs sites จริง)

- **1 worker ต่อ host** เป็น safe default หรือเคารพ `Crawl-delay`
- worker pool จับคู่กับ rate limit (สองอย่างคนละเรื่อง): concurrency cap = งานพร้อมกัน, rate cap = เว้นระยะระหว่าง request
- 429/503 → backoff ตาม `Retry-After`, exponential backoff ต่อ host, 5xx ซ้ำๆ → หยุด host นั้น
- ตั้ง User-Agent ที่ระบุตัว (มี URL ติดต่อ)
- ระวัง `max_concurrency` กับ Playwright: แต่ละ browser context กิน RAM ~150MB — อย่าเปิด 25 context พร้อมกันโดยไม่ cleanup (heap out of memory)

### 5.5 Queue / state

- MVP: queue ในหน่วยความจำ + persisted ผ่าน `crawl_runs`/`documents` ใน DB ก็พอ (resume ได้)
- ถ้าจะ scale: durable queue (Redis/BullMQ) + stateless workers + canonical URL hash เป็น idempotency key
- จบ state machine ของ crawler ตาม `crawl_runs.status` (queued/running/succeeded/partial/failed) ตรง database-plan.md

### 5.6 สิ่งที่ต้องมีเป็น baseline

- URL normalization + dedup (ครบ)
- retry + terminal error (ห้าม loop ไม่รู้จบ)
- ตรวจ `content_hash` — ถ้าเหมือนเดิมไม่ต้อง re-chunk/re-embed (ประหยัด)
- re-crawl: ใช้ `lastmod`/ETag/Last-Modified ตรวจก่อน re-fetch (research อ้างถึง 3-tier change detection)

---

## 6. วิเคราะห์ข้อดีข้อเสียของ research ครั้งก่อน (research-notes.md)

### ข้อดี (ยืนยันแล้วใช้ต่อได้)

1. **Chunk 400/80 + sentence-level** — มีหลักฐาน empirical (production ไทย/ญี่ปุ่น/อังกฤษ) ว่า character-count chunking ทั่วไปพังกับไทย ตัวเลข 400/80 เหมาะเป็นค่าเริ่มต้น
2. **Tokenize ก่อน embed (pythainlp newmm)** — ยืนยันด้วยหลักการ BPE merge ข้าม word boundary + ตัวอย่างผลลัพธ์จริง สมเหตุสมผล และใช้ได้ทั้งตอน ingest และ query
3. **ฟอนต์ IBM Plex Thai + IBM Plex Sans + lang selector** — มีแหล่งอ้างอิงตรง (ThaiGraph + Google Fonts Thai Typography Primer) เลข line-height/font-size เฉพาะเจาะจง นำไปใช้ได้ทันที
4. **i18n: react-i18next + ICU + lazy-load** — เป็น consensus ของ community สอดคล้องกับ stack (Vite React)
5. **Gemini `task_type`** — ตรงกับ official docs ของผู้ให้บริการ

### ข้อเสีย / จุดที่ต้องระวัง

1. **ช่องว่างเรื่อง backend/crawler** — research ครั้งก่อนครอบคลุมเฉพาะ frontend (ฟอนต์/typography/i18n) + ส่วนหนึ่งของ RAG (chunking/tokenize) แต่**ไม่แตะ** เรื่อง auth (JWT/RLS), SSE streaming, pgvector RPC, สถาปัตยกรรม crawler เลย — นี่คือสิ่งที่เอกสารฉบับนี้เติม
2. **ขัดแย้งกับ package ที่มีอยู่** — `server/package.json` ใช้ `@google/generative-ai` (เก่า) แต่ research + official docs แนะนำ `@google/genai` ใหม่ — ต้องตัดสินใจย้าย
3. **chunk 400/80 มาจากโมเดลอื่น** — ตัวเลขมาจาก pipeline ที่ใช้ `multilingual-e5-large` (1024 dims) กับ OpenAI embedding แต่โปรเจกต์ใช้ Gemini embeddings (768 dims) — ต้อง re-test จริงกับ Gemini ไม่อาจเชื่อค่า default เป๊ะ
4. **NitiBench เป็น legal QA ไม่ใช่ docs QA** — อย่า generalize ผล benchmark กฎหมายไทยไปยัง documentation QA ตรงๆ (คนละ domain ต่างกันมาก)
5. **tokenize-before-embed ยังเป็นข้อถกเถียงเล็กน้อย** — บางฝ่ายแย้งว่า separator (`|`) เติม noise เข้า BPE; วิธีที่ robust กว่าคือ space separator และถ้าโมเดล embedding รองรับไทยดีแล้ว (gemini-embedding-2 อ้าง 100+ ภาษา) ผลต่างอาจลดลง — ควร A/B test กับ corpus จริง
6. **i18n วางไว้ในเอกสารแต่ไม่มีใน frontend-plan** — research-notes แนะนำ react-i18next แต่ `docs/frontend-plan.md` ยังเป็น UI-only ไม่ได้วางระบบ TH/ENG — ต้องดึง decision เข้าแผนก่อน implement

### สรุปการใช้

| ประเด็น | คำแนะนำ |
|---|---|
| ฟอนต์/typography | ✅ นำไปใช้ได้ทันที (คัดลอกค่าไป design tokens) |
| chunk 400/80 + pythainlp | ✅ ใช้เป็นค่าเริ่มต้น แต่ re-test กับ Gemini corpus จริง |
| Gemini `task_type` | ✅ ใช้ได้เลย |
| i18n | ⚠️ ต้องเพิ่มเข้า frontend-plan ก่อน implement |
| SDK `@google/genai` | ⚠️ ต้องย้ายจาก `@google/generative-ai` |
| RLS/auth/SSE/crawler | ✅ เป็นไปตามเอกสารฉบับนี้ |

---

## 7. Checklist ก่อน implement

- [ ] อัปเกรด Gemini SDK เป็น `@google/genai` (pin < 3.0.0, Node ≥ 20)
- [ ] middleware `validateJwt` (`getUser()` + 401)
- [ ] เส้นทาง SSE พร้อม `X-Accel-Buffering: no` + abort on close + named events
- [ ] Zod validation ที่ทุก API boundary
- [ ] RPC `match_documentation_chunks` + `ORDER BY distance`
- [ ] crawler: sitemap-first, robots.txt, URL normalization, Playwright networkidle, extract main content
- [ ] chunk 400/80 + tokenize ไทยก่อน embed (ingest + query)
- [ ] กัน `service_role` ออกจาก client 100%
- [ ] ทดสอบ RLS จาก 2 user (บัญชีอื่นต้องมองไม่เห็น chat ของกัน)