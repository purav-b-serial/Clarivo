# Clarivo — AI-Powered Study Companion

> **Learn Smarter. Go Further.**

Clarivo is a free AI study assistant for CBSE Class 10 students, built for the AI Hackathon (September 2026). It runs in the browser — no installation required.

---

## What Clarivo Can Do Right Now

### Clara — AI Tutor
- Ask questions about CBSE Class 10 topics and get clear, detailed answers
- Clara is powered by the Groq API (Qwen3 27B model)
- Answers are grounded in seeded study notes where available
- When answering from general knowledge (not from notes), Clara displays a disclaimer
- Full markdown rendering — **bold**, headings, bullet points, numbered steps
- LaTeX math rendering — equations like `$$x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$$` display as proper math

### Subject + Class Selection
- Select your class (currently Class 10) before starting
- Choose a subject — Clara focuses her search and answers on that subject
- Active subject shown in the AppBar with a coloured banner
- Switch subject anytime via the "Change" button or the subject picker sheet
- Subject selection persists during the session

### Content Library
- Browse all 6 subjects organised by chapter
- Tap any chapter to read the full study notes
- Notes are stored locally in the browser (IndexedDB) — no internet needed to read them

### 6 Subjects Covered (CBSE Class 10)
- **Science** — Chemical Reactions, Acids/Bases/Salts, Metals/Non-metals, Life Processes, Control & Coordination, Reproduction, Light, Electricity, Magnetic Effects
- **Mathematics** — Real Numbers, Polynomials, Linear Equations, Quadratic Equations, Arithmetic Progressions, Triangles, Coordinate Geometry, Trigonometry, Circles, Areas, Surface Areas & Volumes, Statistics, Probability
- **Social Science** — History (Nationalism in Europe, Indo-China, India), Geography (Resources, Agriculture, Minerals, Manufacturing, Transport), Civics (Power Sharing, Federalism, Democracy), Economics (Development, Sectors, Money & Credit, Globalisation)
- **English** — First Flight (prose + poetry), Footprints Without Feet, Grammar (reported speech, active/passive, tenses)
- **Hindi** — Kshitij (poems + prose), Kritika, Vyakaran overview
- **Sanskrit** — Shemushi (10 lessons), Vyakaranavithi (grammar)

### Progress Tracker
- View all questions you have asked Clara
- Expandable cards showing each question and Clara's full answer
- Shows when each question was asked

### Storage Screen
- See what content is currently installed (106 study chunks, 9 chapters per subject)
- Shows the AI model in use (Groq Cloud)
- Lists planned future storage features

### Settings Screen
- View app version and current AI model
- See what content is active
- Lists planned future features

### Landing Page (Web)
- Clean landing page at the root URL
- "Try Clara Online" button goes straight into the app
- Download buttons for Android and Windows (links to be updated after APK build)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.47 (Dart) — single codebase for Web, Android, Windows |
| State Management | Riverpod |
| Navigation | GoRouter |
| Local Database | Drift (SQLite + WASM for web via IndexedDB) |
| AI | Groq API — qwen/qwen3.8-27b |
| Content | 106 study note chunks across 6 subjects (JSON assets seeded on first load) |
| Markdown | flutter_markdown |
| Math Rendering | flutter_math_fork (LaTeX via `$$...$$`) |
| Hosting | Netlify |

---

## Running Locally

### Prerequisites
- Flutter SDK 3.47+
- Free Groq API key from [console.groq.com](https://console.groq.com)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/purav-b-serial/Clarivo.git
cd Clarivo

# 2. Install dependencies
flutter pub get

# 3. Run on Chrome
flutter run -d chrome --dart-define=GROQ_API_KEY=your_key_here

# 4. Release build
flutter build web --release --dart-define=GROQ_API_KEY=your_key_here
```

> The API key is injected at build time via `--dart-define`. It is never committed to git. Copy `.env.example` to `.env` for local reference.

---

## Planned Future Features

These are not available in the current demo but are planned for future development:

- **On-device AI** — local LLM (Qwen2.5-3B GGUF via llama.cpp) for fully offline answers, no Groq needed
- **Full CBSE content matrix** — Classes 6–12 for all subjects, plus JEE, NEET, UPSC, SSC/Banking tracks
- **PDF and file upload** — ingest your own notes; Clara answers from them
- **Vector search** — semantic similarity search replacing the current keyword search
- **Student accounts** — login, profiles, progress sync across devices
- **6-language UI** — Hindi, Tamil, Telugu, Kannada, Bengali alongside English
- **OCR / image input** — photograph a question and ask Clara
- **Push notifications** — daily study reminders and tips
- **Supervisor dashboard** — parent/teacher read-only view of student progress
- **iOS build** — App Store and TestFlight distribution
- **Offline-first** — all features work without internet when on-device AI is integrated

See `FUTURE_UPDATES.md` for the full roadmap.

---

## Hackathon Spec Documents

Located in `.kiro/specs/`:
- `requirements.md` — core requirements for the hackathon demo scope
- `design.md` — architecture, data model, AI pipeline, component design
- `tasks.md` — 5-phase implementation plan

---

## Project Structure

```
Clarivo/
├── lib/
│   ├── core/              # Router, providers (subject, language)
│   ├── data/              # Database (Drift), seed content (JSON), keyword search
│   ├── domain/            # Services: Clara AI, Groq client, keyword search
│   └── features/          # UI: tutor (Clara), content, progress, storage, settings, landing
├── assets/
│   ├── content/           # Subject JSON files (science, maths, sst, english, hindi, sanskrit)
│   └── i18n/              # Localisation ARB files
├── .kiro/specs/           # Hackathon spec documents
├── web/                   # Flutter web files + _redirects for SPA routing
└── .env.example           # API key template — never commit .env
```
