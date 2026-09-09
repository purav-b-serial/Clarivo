# Clarivo — AI-Powered Study Companion

> **Learn Smarter. Go Further.**

Clarivo is a free AI study assistant for CBSE students, built for the AI Hackathon (September 2026). It runs entirely in the browser and installs as a Progressive Web App (PWA) — no app store, no APK, no installer.

**Live:** https://superb-licorice-8c14a1.netlify.app

---

## What Clarivo Can Do Right Now

### Clara — AI Tutor
- Ask questions about CBSE topics and get clear, detailed answers
- Powered by the Groq API (`qwen/qwen3.8-27b`)
- Answers are grounded in seeded study notes when relevant material is found
- When answering from general knowledge (no matching notes), Clara prefixes a clear disclaimer
- Full markdown rendering — **bold**, headings, bullet points, numbered steps
- LaTeX math rendering — equations like `$$x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$$` display as proper math

### Class + Subject Selection
- Two-step picker: choose your class (only classes with content appear), then a subject
- Clara scopes her retrieval and answers to the selected class and subject
- Subjects without notes are shown as "Coming soon" and are not selectable
- Active class/subject shown in the AppBar; switch anytime via the picker
- Selection persists during the session

### Competitive Exam Prep (JEE / NEET)
- One-tap **JEE** or **NEET** mode — no need to pick a single class or subject
- Clara auto-scopes across **Class 11 and 12** and multiple subjects at once:
  - **JEE** → Physics, Chemistry, Mathematics
  - **NEET** → Physics, Chemistry, Biology
- Retrieval searches the whole exam syllabus; answers are framed for exam-style questions

### Content Covered (CBSE Classes 10, 11, 12)
- **Class 10** — Science, Mathematics, Social Science, English, Hindi, Sanskrit
- **Class 11** — Physics, Chemistry, Biology, Mathematics, Computer Science, English
- **Class 12** — Physics, Chemistry, Mathematics, Biology, Computer Science, English

### Content Library
- Browse seeded content organised by class → subject → chapter
- Tap any chapter to read the full study notes
- Notes are stored locally in the browser (SQLite via `sqlite3.wasm`), so reading them needs no network

### Progress Tracker
- Summary stats: questions asked, distinct topics covered, distinct subjects
- Expandable per-question cards showing the topics used to answer (or a note when answered from general knowledge) and Clara's full answer

### Storage & Settings
- Storage screen shows installed content, chat history, and the AI model in use (Groq Cloud)
- Settings shows app info and a short list of planned features

### Landing Page (Web / PWA)
- Clean landing page at the root URL
- "Try Clara Online" opens the app instantly
- **Install on Android** and **Install for Windows** buttons trigger the browser's native PWA install (Add to Home screen / Install as desktop app) with a manual-instructions fallback

---

## How the AI Key Stays Secure

Clarivo never ships the Groq API key to the browser. Two modes, chosen automatically:

- **Production (default):** the web app calls its own serverless proxy at `/api/clara` (a Netlify function). The function holds the real key in the `GROQ_API_KEY` Netlify environment variable and forwards the request to Groq. **The key never reaches the client bundle.**
- **Local development:** if you build/run with `--dart-define=GROQ_API_KEY=...`, Clara calls Groq directly using that key (convenient for local work).

Groq request parameters are identical in both modes, so answers are unchanged.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart), delivered as a PWA |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Database | Drift (SQLite; `sqlite3.wasm` + `drift_worker.js` on web) |
| AI | Groq API — `qwen/qwen3.8-27b` |
| AI transport | Netlify serverless function proxy (`/api/clara`) in production |
| Content | 18 subject content packs across Classes 10–12 (JSON assets seeded on first load) |
| Markdown | flutter_markdown |
| Math Rendering | flutter_math_fork (LaTeX via `$$...$$`) |
| Hosting | Netlify (Git-connected continuous deploy) |

---

## Running Locally

### Prerequisites
- Flutter SDK (stable)
- Free Groq API key from [console.groq.com](https://console.groq.com)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/purav-b-serial/Clarivo.git
cd Clarivo

# 2. Install dependencies
flutter pub get

# 3. Generate Drift/Riverpod code
dart run build_runner build --delete-conflicting-outputs

# 4. Run on Chrome (local dev — key passed via --dart-define)
flutter run -d chrome --dart-define=GROQ_API_KEY=your_key_here
```

> Locally, the key is passed via `--dart-define` and is never committed to git. In production, the key is **not** in the build at all — it lives only in the Netlify `GROQ_API_KEY` environment variable and is used server-side by the `/api/clara` function.

---

## Deployment (Netlify, Git-connected)

Deployment is automatic: every push to `main` triggers a Netlify build that installs Flutter, runs `build_runner`, builds the web release (with **no** key baked in), and deploys the `clara` function. See `DEPLOY.md` for the full guide, including the required Netlify environment variable and routing notes.

---

## Planned Future Features

Not in the current build, planned for later:

- **Full CBSE content matrix** — Classes 6–12 across all subjects, plus UPSC and SSC/Banking tracks
- **PDF and file upload** — ingest your own notes; Clara answers from them
- **Vector search** — semantic similarity search replacing the current keyword search
- **Student accounts** — login, profiles, progress sync across devices
- **6-language UI** — Hindi, Tamil, Telugu, Kannada, Bengali alongside English (localization is scaffolded)
- **OCR / image input** — photograph a question and ask Clara
- **Push notifications** — daily study reminders and tips
- **Supervisor dashboard** — parent/teacher read-only view of student progress
- **Server-side rate limiting** — throttle the proxy to protect the Groq quota

See `FUTURE_UPDATES.md` for the full roadmap.

---

## Spec Documents

Located in `.kiro/specs/AI/clarivo/`:
- `requirements.md` — product requirements for the shipped app
- `design.md` — architecture, data model, AI pipeline, component design
- `tasks.md` — implementation record

---

## Project Structure

```
Clarivo/
├── lib/
│   ├── core/              # Router, providers (subject/exam, language)
│   ├── data/              # Database (Drift), seed content (JSON), keyword search
│   ├── domain/            # Services: Clara AI, Groq client, keyword search
│   └── features/          # UI: tutor (Clara), content, progress, storage, settings, landing
├── assets/
│   ├── content/           # 18 subject JSON packs (Classes 10–12)
│   └── i18n/              # Localisation ARB files
├── netlify/
│   └── functions/         # clara.js — serverless Groq proxy (holds the key server-side)
├── web/                   # Flutter web files + _redirects (routes /api/clara + SPA fallback)
├── netlify.toml           # Build command, functions dir, redirects, security headers
├── package.json           # Node engine for the Netlify function
├── .kiro/specs/AI/clarivo/ # Spec documents
└── .env.example           # Local-only key template — never commit a real key
```
