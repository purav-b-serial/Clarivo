# Clarivo - Future Updates

Features planned for the full Clarivo product, beyond what currently ships.

> Note: Clarivo is delivered as a **Progressive Web App (PWA)** and requires an
> internet connection (Clara uses the Groq cloud API through a serverless
> proxy). There is no offline/on-device AI and no downloadable APK or Windows
> installer — installation is via the browser's PWA "install" flow.

---

## Already Shipped (for reference)
- Multi-class content: CBSE Classes 10, 11, and 12 across their core subjects
- Competitive exam prep: **JEE** (PCM) and **NEET** (PCB), auto-scoped across Class 11 & 12
- Markdown + LaTeX rendering, progress tracking, class/subject picker
- PWA install for Android and Windows
- Server-side Groq key via the `/api/clara` Netlify function proxy

---

## Authentication and Accounts
- Full auth system: email/phone registration, login, session restore, PBKDF2-SHA256 password hashing
- Multi-account support with isolated per-account data
- Supervisor/parent dashboard: read-only progress view, PIN-protected

## AI Pipeline Improvements
- ONNX embeddings: all-MiniLM-L6-v2 (384-dim) via flutter_onnxruntime
- sqlite-vec vector store: KNN cosine search replacing keyword LIKE queries
- Full RAG pipeline: chunk -> embed -> index -> retrieve -> prompt -> generate
- Server-side rate limiting on the proxy to protect the Groq quota

## Content
- Full CBSE matrix: remaining classes (6-9) across all subjects
- Additional competitive tracks: UPSC, SSC/Banking
- Content package management: per-subject organisation and refresh
- User content upload: PDF and plain-text ingested into a personal corpus

## Input
- OCR / image input: photograph questions and extract text
- Mathematical expression recognition: LaTeX-like extraction for Physics/Maths questions

## Progress and Engagement
- Richer progress tracker: study time, weekly and overall summaries
- Study reminders and rotating study tips

## Localisation
- 6-language UI: Hindi, Tamil, Telugu, Kannada, Bengali + English (delegates are scaffolded)
- Multilingual Clara responses: reply in the language the student asks in

## Platforms
- iOS support (as a PWA / added to home screen)

## Website and Distribution
- Custom domain (e.g. clarivo.app)
- Backend sync: optional cloud backup so progress syncs across devices

---

## Notes for Implementors

A fuller production schema exists in the codebase and is preserved without conflict:
- lib/data/database/app_database.dart: multi-table schema (accounts, progress, content packages, etc.)
- lib/data/database/corpus_database.dart: corpus chunks + vector table
- lib/domain/auth/: AuthenticationService with PBKDF2 hashing

The shipped app uses DemoDatabase (lib/data/database/demo_database.dart) as a
simplified overlay. When implementing future features, wire the full schema
providers and remove the DemoDatabase override in main.dart.
