# Clarivo - Future Updates

Features deliberately deferred from the hackathon demo (September 2026).
All are planned for the full Clarivo product.

---

## Authentication and Accounts
- Full auth system: email/phone registration, login, session restore, PBKDF2-SHA256 password hashing
- Multi-account support: up to 10 accounts per device with isolated data
- Account switching without data loss
- Supervisor/parent dashboard: read-only progress view, PIN-protected

## AI Pipeline - On-Device (Offline)
- Local LLM via fllama/llama.cpp: Qwen2.5-3B Q4_K_M, fully offline, no Groq needed
- ONNX embeddings: all-MiniLM-L6-v2 (384-dim) via flutter_onnxruntime
- sqlite-vec vector store: KNN cosine search replacing keyword LIKE queries
- Full RAG pipeline: chunk -> embed -> index -> retrieve -> prompt -> generate

## Content
- Full CBSE matrix: all subjects, Classes 6-12 (Mathematics, Science, Social Science, English, Hindi)
- Competitive exam tracks: JEE, NEET, UPSC, SSC/Banking
- Content package management: per-subject download, delete, re-download to free storage
- User content upload: PDF and plain-text ingested into personal corpus for any exam track

## Input
- OCR / image input: photograph questions via ML Kit (Android/iOS) or Tesseract (Windows)
- Mathematical expression recognition: LaTeX-like extraction for Physics/Maths questions

## Progress and Engagement
- Progress tracker: study time, question count, topic breakdown; weekly and overall summaries
- Push/local notifications: daily study reminders and rotating study tips (365 entries, works offline)

## Localisation
- 6-language UI: Hindi, Tamil, Telugu, Kannada, Bengali + English
- Multilingual Clara responses: Clara replies in the same language the student asks in

## Platforms
- iOS build: App Store and TestFlight distribution
- Production-signed Windows installer (MSIX/EXE)
- Offline-first: all features work without internet once on-device LLM is integrated

## Website and Distribution
- Custom domain (clarivo.app)
- Direct APK and Windows installer download links (production-hosted)
- Backend sync: optional cloud backup so progress syncs across devices

---

## Notes for Implementors

The full production schema is already written and preserved in the codebase:
- lib/data/database/app_database.dart: 8-table schema (accounts, progress, content packages, etc.)
- lib/data/database/corpus_database.dart: corpus chunks + sqlite-vec virtual table
- lib/domain/auth/: AuthenticationService with PBKDF2 hashing
- lib/data/vector/vec_chunks_helper.dart: KNN search SQL helpers

The hackathon demo uses DemoDatabase (lib/data/database/demo_database.dart)
as a simplified overlay so the production schema is preserved without conflict.
When implementing future features, wire the full schema providers and remove
the DemoDatabase override in main.dart.
