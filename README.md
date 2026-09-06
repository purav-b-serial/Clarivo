# Clarivo — AI-Powered Study Companion

> **Learn Smarter. Go Further.**

Clarivo is a free, cross-platform AI study assistant for CBSE Class 10 students built for the AI Hackathon (September 2026).

## Live Demo

**[Try Clarivo Online →](https://clarivo.netlify.app)**  
*(No installation required — works in any browser)*

---

## Features

- **Clara** — AI tutor powered by Groq (qwen3.8-27b), answers questions from seeded CBSE Class 10 content
- **6 Subjects** — Science, Mathematics, Social Science, English, Hindi, Sanskrit
- **Class + Subject Selection** — Clara focuses answers on your selected class and subject
- **Content Library** — Browse all chapters and read study notes offline
- **Progress Tracker** — View your question history and study stats
- **Markdown + LaTeX Rendering** — Formulas and equations display correctly
- **Offline-capable** — Content is stored locally in the browser (IndexedDB)
- **100% Free** — No ads, no subscriptions, no account required to try

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart) — single codebase for Web, Android, Windows |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Database | Drift (SQLite via sqlite-vec + WASM for web) |
| AI | Groq API — qwen/qwen3.8-27b |
| Content | CBSE Class 10 study notes (seeded JSON assets, 106 chunks across 6 subjects) |
| Markdown | flutter_markdown + flutter_math_fork (LaTeX rendering) |
| Hosting | Netlify |

---

## Project Structure

```
Clarivo/
├── lib/
│   ├── core/              # Router, providers, constants
│   ├── data/              # Database, seed content (JSON), vector search
│   ├── domain/            # Services: Clara AI, Groq client, keyword search
│   ├── features/          # UI screens: tutor, content, progress, storage, settings, landing
│   └── shared/            # Shared widgets
├── assets/
│   ├── content/           # Subject JSON files (science, maths, sst, english, hindi, sanskrit)
│   ├── i18n/              # Localisation ARB files (en, hi, ta, te, kn, bn)
│   └── models/            # (Reserved for future on-device AI model)
├── .kiro/specs/           # Hackathon spec documents (requirements, design, tasks)
├── web/                   # Flutter web entrypoint + _redirects for SPA routing
└── .env.example           # API key template — never commit .env
```

---

## Running Locally

### Prerequisites
- Flutter SDK 3.47+
- A free Groq API key from [console.groq.com](https://console.groq.com)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/Clarivo.git
cd Clarivo

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome (API key passed at runtime)
flutter run -d chrome --dart-define=GROQ_API_KEY=your_key_here

# 4. Build release
flutter build web --release --dart-define=GROQ_API_KEY=your_key_here
```

### Notes
- The GROQ_API_KEY is **never** stored in source code or committed to git
- It is injected at build time via `--dart-define=GROQ_API_KEY=...`
- Copy `.env.example` to `.env` for local dev reference (`.env` is gitignored)

---

## Hackathon Spec Documents

Located in `.kiro/specs/`:
- `requirements.md` — 9 core requirements for the hackathon demo
- `design.md` — Architecture, data model, AI pipeline, component design
- `tasks.md` — 5-phase implementation plan

---

## Future Updates

See `FUTURE_UPDATES.md` for the full roadmap including:
- On-device LLM (offline AI, no Groq needed)
- Full CBSE content matrix (Classes 6–12, JEE, NEET, UPSC)
- Multi-account authentication
- 6-language UI support
- OCR image input
- Android APK + iOS build

---

## License

Built for the AI Hackathon — September 2026.
