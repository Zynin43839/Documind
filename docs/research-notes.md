# Research Notes — DocuMind

> เอกสารสรุปผลการวิจัยเพื่อช่วยทีมตัดสินใจ (อัปเดต: 17 ส.ค. 2026)
> เกี่ยวข้องกับวาระ: ฟอนต์ไทย, ระบบ TH/ENG, ความแม่นยำของคำตอบภาษาไทย (RAG)

## 1. ฟอนต์ไทย: เลือกอะไรดี

### ตัวเลือกหลัก (4 ตัวที่เทียบใน mockups/font-logo-preview.html)
| ฟอนต์ | จุดเด่น | ข้อควรระวัง |
| --- | --- | --- |
| IBM Plex Sans Thai | open-source, neutral/friendly Grotesque, เป็น family เดียวกับ IBM Plex Sans (จับคู่ Latin ได้สมบูรณ์) | ไฟล์ 40-80KB ต่อน้ำหนัก ต้อง subset |
| Prompt | loopless Thai, ทันสมัย | glyph คล้ายกันทำให้อ่านสั้นๆ สับสน (ก/ถ/ภ/ฤ/ฦ, ฎ/ฏ, บ/ป, ข/ช) |
| Sarabun | อ่านง่ายแม้ขนาดเล็ก, ไฟล์เบา, DGA ใช้เป็นมาตรฐานหน่วยงานรัฐ | ตัวมี loop เหมาะงานราชการมากกว่าคอนซูเมอร์ |
| Noto Sans Thai | ครอบคลุมครบทุก weight (100-900) + variable font, ปลอดภัยสุด | กลางๆ ไม่มีบุคลิก |

### ข้อแนะนำจากการวิจัย
- ฟอนต์ไทยควรจับคู่กับฟอนต์ Latin ที่ x-height ตรงกัน (ภายใน 5%):
  - IBM Plex Thai + IBM Plex Sans = ออกแบบมาเป็นครอบครัวเดียวกัน (corporate default)
  - Noto Sans Thai + Noto Sans = Google matched pair (web default)
  - Sarabun + Inter = default สำหรับ UI body
- ใช้ฟอนต์สูงสุด 2 ตัว (1 heading + 1 body)
- ควรมี Regular + Bold (อย่าให้ browser ทำ faux bold)
- เลี่ยง letter-spacing (tracking) กับข้อความไทย — ทำลาย vowel-consonant binding

## 2. การตั้งค่า Thai Typography ในเว็บ (CSS)

### Line-height
- ไทยต้องสูงกว่า Latin 10-15% เสมอ เพราะไทยมีสระ/วรรณยุกต์ซ้อน 4 ระดับ (ต่ำกว่า baseline, ตัว consonant, สระบน, วรรณยุกต์)
- ตัวเลขที่แนะนำ:
  - Latin body 1.4-1.5 ไปเป็น Thai body 1.55-1.8 (ต่ำสุด 1.55)
  - Display: Latin 1.17 ไปเป็น Thai 1.5
- WCAG 1.4.13 ยังระบุว่า Thai ต้องการ line-height มากกว่า English

### Font-size
- ตัวไทย optically เล็กกว่า Latin ไปเพิ่มขนาด 5-10%
  - Latin 16px ไปเป็น Thai 17-18px
  - Latin 14px ไปเป็น Thai 15px

### การตัดบรรทัด (word-break)
- word-break: normal + overflow-wrap: break-word — ให้ browser ตัดตาม ICU/ไทยถูกต้อง
- ห้าม word-break: break-all
- ไทยไม่มี space ระหว่างคำ แต่ browser ตัดที่ word boundary ได้เอง (มี wpt test รองรับ)

### Pattern ที่แนะนำ (ใช้กับระบบ TH/ENG ได้เลย)
```css
html[lang="th"] body { line-height: 1.625; font-size: 17px; }
html[lang="en"] body { line-height: 1.5;  font-size: 16px; }
```

### การโหลดฟอนต์
- Self-host ดีกว่า Google Fonts CDN สำหรับไทย-primary (บันทึก DNS/connect)
- subset เฉพาะ Thai + Latin (ลดไฟล์ 60-80%)
- font-display: swap + preload ไฟล์ Thai
- ใช้ unicode-range แยกไฟล์ Thai/Latin

## 3. Thai RAG Pipeline: tokenization + chunking

### ปัญหาหลัก
- ไทยเป็น scriptio continua (ไม่มี space ระหว่างคำ) ไป naive chunker เห็นเป็นก้อนยาวๆ แยกไม่ออก
- BPE ของ embedding model จะ merge ข้าม word boundary ไป embedding เบลอความหมาย

### วิธีแก้: tokenize ก่อน embed เสมอ
- ใช้ pythainlp engine newmm (dictionary-based, default, เร็ว เหมาะ production)
- attacut (neural) แม่นพอๆ กัน แต่ช้ากว่า
- ต้อง tokenize ทั้งตอน ingest และตอน query
- แทรก separator (pipe หรือ space) เพื่อกัน BPE merge ข้ามคำ — หลักสำคัญคือ boundary signal ไม่ใช่ตัว separator เอง
- Embed จาก tokenized text แต่เก็บ original text ไว้ตอบ user (แยก field กัน)

### Chunking
- Sentence-level ดีกว่า character-level (ไม่อยู่กลางคำ)
- ประสบการณ์ production (LlamaIndex + pgvector): 400 chars / overlap 80 (20%) ดีสุดสำหรับไทย
  - 256/50: เล็กเกิน ไทยตัดกลาง clause
  - 512/100: ไทยยัง fragment
  - 400/80: ดีที่สุด
- เอกสารไทยที่จบด้วย line break (ไม่ใช่ .) ไปใช้ sent_tokenize ของ pythainlp แทน split('. ')

### อื่นๆ
- PDF ไทยใช้ pdfplumber แทน PyPDF2 (encoding ไทยพังบ่อย)
- cosine similarity ดีกว่า euclidean สำหรับ semantic search ไทย
- เพิ่ม threshold (เช่น 0.72) + reranking ลด chunk ไร้สาระ

### Benchmark อ้างอิง
- NitiBench (EMNLP 2025): benchmark QA กฎหมายไทย; hierarchy-aware chunking ดีกว่า naive เล็กน้อย; retrieval model ปัจจุบันยังสู้คำถามไทยซับซ้อนได้ไม่ดี

## 4. i18n TH/ENG

### ทางเลือก library
| Library | เหมาะกับ | จุดเด่น |
| --- | --- | --- |
| react-i18next | React ทั่วไป (Vite ได้) | นิยมสุด, plugin เยอะ, dynamic language switching |
| react-intl (FormatJS) | ICU-heavy | มาตรฐาน ICU |
| next-intl | Next.js App Router | — |
| Lingui | compile-time, bundle เล็ก | — |

ข้อแนะนำ: react-i18next เหมาะกับโปรเจกต์ Vite React แบบเรา

### หลักการ
- ใช้ ICU message format (มือใหม่กับ react-i18next ใช้ format ของมันเองได้ แต่ ICU เข้ากับ translation platform + AI มากกว่า)
- Lazy-load เฉพาะ locale ที่ใช้ (dynamic import) — ไม่ bundle ทั้ง th + en
- Fallback chain: th ไป en
- เก็บ locale ที่เลือกไว้ (localStorage/cookie)
- เลี่ยง string concatenation (เช่น t('delete') + t('item')) — แปลทั้งประโยคเป็นหน่วยเดียว
- รองรับ HTML lang attribute ตามหัวข้อ 2 (html[lang="th"])

## 5. Gemini embeddings (ข้อมูลสนับสนุนจากผู้ให้บริการ)

- gemini-embedding-2: multimodal, รองรับ 100+ ภาษา (รวมไทย)
- ระบุ task_type (RETRIEVAL_DOCUMENT, RETRIEVAL_QUERY, SEMANTIC_SIMILARITY ฯลฯ) ช่วยให้ผล retrieval ดีขึ้น
- ใส่ task instruction/prefix ใน prompt ด้วย

---

## สรุปข้อแนะนำที่ใช้ตัดสินใจได้เลย
1. ฟอนต์: IBM Plex Sans Thai (ฟอนต์ไทย) + IBM Plex Sans (Latin) — เป็น family เดียวกัน จับคู่สมบูรณ์
2. Typography: ใช้ lang selector ไทย 17px/1.625, อังกฤษ 16px/1.5; word-break: normal
3. RAG ไทย: pythainlp newmm + separator ก่อน embed; chunk 400/80; เก็บ original text
4. i18n: react-i18next + lazy-load locale + fallback th ไป en