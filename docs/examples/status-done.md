# Backend: Fix tsconfig (outDir/rootDir) for build

## 🎯 User Story
ในฐานะ dev ฉันอยากให้ build ไปที่ dist/ เพื่อให้ node dist/index.js รันบน Belmo ได้

## 📋 Tasks (What)
- [ ] uncomment outDir/rootDir ใน tsconfig
- [ ] rebuild + ทดสอบรัน

## ✅ Acceptance Criteria (DoD) — ต้องผ่านครบ
- [ ] npm run build ได้ dist/index.js
- [ ] npm start รัน health endpoint ผ่าน

## 📦 Metadata
- Owner: [BE]
- Type: Backend
- Estimate: 1
- Priority: High
- Epic: BE
- Status: Done
- Depends on: -
