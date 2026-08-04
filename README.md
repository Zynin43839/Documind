# DocuMind

AI-powered documentation chatbot with RAG (Retrieval-Augmented Generation)

---

## 🎯 Problem → Solution

**Problem:**
Developer documentation is scattered across multiple sites — React docs, Next.js docs, Tailwind docs, TypeScript docs. Finding a specific answer means opening multiple tabs, searching through pages, and often not finding what you need. Documentation fatigue is real.

**Solution:**
DocuMind uses RAG to answer questions from crawled developer documentation. Ask a question in natural language, get an answer with source citations — all in one place.

---

## ✨ Features

- 🔐 Login / Register (Supabase Auth)
- 💬 RAG-powered Chat — ask questions, get answers from docs
- 📜 Chat History — view previous conversations per user session
- 👤 Profile Management — change display name
- 🕷️ Auto-Crawl — crawl and index documentation automatically
- 🎨 SchemaBlue design system

**Not included (by design):**
- ❌ File upload — documentation is crawled, not uploaded
- ❌ Profile pictures — focus on functionality, not appearance

---

## 📊 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18 |
| Backend | Express.js |
| Database | Supabase (PostgreSQL + pgvector) |
| Auth | Express (JWT) |
| LLM | Gemini 1.5 Flash |
| Embedding | Gemini text-embedding-004 |
| Crawler | Playwright |
| Design | SchemaBlue |
| Deploy | Vercel + Docker + GitHub Actions |

**Total cost: 0 THB** — all services use free tier

---

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐
│   React UI  │────▶│  Express API │────▶│    Supabase      │
│  (Vercel)   │     │   (Docker)   │     │  PostgreSQL      │
└─────────────┘     └──────┬───────┘     │  + pgvector      │
                           │             │  + Auth + RLS    │
                           ▼             └──────────────────┘
                    ┌──────────────┐            ▲
                    │    Gemini    │────────────┘
                    │ LLM + Embed  │
                    └──────────────┘
```

**Data Flow:**

1. **Ingestion:** Documentation → Playwright → Parse → Chunk → Embed (768 dims) → pgvector
2. **Query:** User Question → Embed query → pgvector cosine search → Top-5 chunks → Gemini Flash → Stream response

---

## 📚 References

- [Stack Overflow Survey 2025](https://survey.stackoverflow.co/2025/technology)
- [Gemini API](https://ai.google.dev/gemini-api/docs)
- [Supabase](https://supabase.com/docs)
- [Playwright](https://playwright.dev/)
- [SchemaBlue Design](https://designmd.ai/chef/schemablue)

---

MIT License
