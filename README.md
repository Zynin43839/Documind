# DocuMind

AI documentation chatbot ด้วย **RAG (Retrieval-Augmented Generation)** — ถามคำถามภาษาไทย/อังกฤษ แล้วได้คำตอบพร้อมแหล่งอ้างอิงจาก documentation ที่ crawl มา

---

## 🎯 Problem → Solution

**Problem:** Developer documentation กระจายหลายที่ (React, Next.js, Tailwind, TypeScript...) หาคำตอบต้องเปิดหลายแท็บ ค้นหาไม่เจอ — documentation fatigue.

**Solution:** DocuMind ใช้ RAG ตอบคำถามจาก documentation ที่ crawl มา ถามด้วยภาษาธรรมชาติ ได้คำตอบพร้อม source citation ในที่เดียว

(ไม่มี file upload — ใช้ crawled data อย่างเดียว โดย design)

---

## ✨ Features

- 🔐 Register / Login — name + work email + password + **Verify ด้วย OTP 6 หลัก (email)**
- 💬 RAG Chat — ถามคำถาม ได้คำตอบ + citations (SSE streaming)
- 📜 Chat History — ดูประวัติแชตต่อ user
- 🕷️ Auto-Crawl — Crawlee AdaptivePlaywright crawl + index docs
- 🔎 Version search — เลือก version ของ doc (dropdown, default ล่าสุด)
- 🌐 สวิตช์ภาษาแยก 2 ตัว: UI lang + AI lang
- 🎨 SchemaBlue design system

**Not included (by design):** file upload · admin page · dark mode

---

## 📊 Tech Stack (locked 2026-09-02)

| Layer | เทคโนโลยี |
|-------|----------|
| Frontend | Vite React SPA |
| Backend | Express + TypeScript |
| Database | Supabase (PostgreSQL + pgvector, region Singapore) |
| Auth | Express JWT (Bearer + refresh HttpOnly cookie, rotation) |
| LLM | Gemini (@google/genai, pin <3.0.0) |
| Embedding | gemini-embedding-001 (768d, MRL + L2-normalize) |
| Crawler | Crawlee AdaptivePlaywright + Cheerio + Turndown |
| Verify | OTP email (SM provider ยังเปิดให้เลือก) |
| Backend Host | Belmo (free) |
| Frontend Deploy | Vercel Hobby |
| Board | GitHub Projects v2 |

**Total cost: 0 THB** (ทุก service ใช้ free tier)

---

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐
│   React UI  │────▶│  Express API │────▶│    Supabase      │
│  (Vercel)   │     │    (Belmo)   │     │  PostgreSQL      │
└─────────────┘     └──────┬───────┘     │  + pgvector      │
                           │             │  + Auth + RLS    │
                           ▼             └──────────────────┘
                    ┌──────────────┐            ▲
                    │    Gemini    │────────────┘
                    │ LLM + Embed  │
                    └──────────────┘
```

**Data Flow:**
1. **Ingestion:** Documentation → Crawlee → Parse → Chunk → Embed (768d) → pgvector
2. **Query:** User Question → Embed query → pgvector hybrid search (BM25+RRF) → Top-k chunks → Gemini → SSE stream

---

## 🔌 API Endpoints (v1)

**Auth (OTP):** `POST /auth/register`, `/auth/verify`, `/auth/resend-otp`, `/auth/login`, `/auth/refresh`, `/auth/reset-password`, `/auth/logout` · `GET /me`

**Chat:** `POST /chats` (upsert) · `GET /chats` · `GET /chats/:id` · `GET /chats/:id/messages` (cursor) · `POST /chats/:id/turns` (SSE)

**Docs/Crawler:** `GET /docs/:id/versions` · `GET /docs/:id?version=` · `GET /crawler/status`

(แผน tech stack และ API สรุปด่านบน: ตัดสินใจแล้วตาม decision record ภายในทีม — เต็มอยู่ใน `Mydoc/` สำหรับสมาชิกทีมที่ access)

---

## 🗂️ Board / Project Management

จัดการ backlog บน **GitHub Projects v2** — Status: Backlog / Todo / In Progress / In Review / Done / Blocked + Fields: Priority / Epic / Work Type / Sprint / Due Date

คู่มือ: `docs/github-projects-guide.md` · Template card: `docs/task-card-template.md`

---

## 📚 References

- [Gemini API](https://ai.google.dev/gemini-api/docs) · [Supabase](https://supabase.com/docs) · [Crawlee](https://crawlee.dev/) · [Vercel](https://vercel.com)

---

## License

MIT
