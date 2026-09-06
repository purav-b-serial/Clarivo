# Implementation Plan: Clarivo — Hackathon Demo (September 10)

## Overview

Wire together the existing Flutter shell into a working demo. The app opens directly to the Clara AI chat screen (no auth), backed by Groq API (llama-3.3-70b-versatile), with pre-seeded CBSE Class 10 Science content in a local Drift SQLite database. A web landing page at `/` lets visitors try Clara online and download the APK.

The existing project already has: Flutter shell running on Chrome, a Drift schema (full prod schema), an auth service (bypassed for demo), a router with 5-tab nav, and a `.env` file for secrets.

---

## Tasks

- [ ] 1. Phase 1 — Simplify & wire database

  - [ ] 1.1 Add `http` package to `pubspec.yaml`
    - Open `pubspec.yaml` at `c:\Hackathon Kiro AI\Clarivo\pubspec.yaml`
    - Add `http: ^1.2.2` under the `dependencies` section (alongside the existing packages)
    - Run `flutter pub get` to resolve
    - _Requirements: 4 (Groq API integration requires HTTP)_

  - [ ] 1.2 Simplify the router — remove auth guards, splash goes directly to `/home/tutor`
    - Open `c:\Hackathon Kiro AI\Clarivo\lib\core\router.dart`
    - Remove the `_RouterRefreshNotifier` class and `refreshListenable` from `GoRouter`
    - Remove the entire `redirect:` block (the auth-guard lambda)
    - Remove the `GoRoute` entries for `/login` and `/register`
    - Remove imports for `auth_state.dart`, `auth_state_notifier.dart`, `login_screen.dart`, `register_screen.dart`
    - Change the `_SplashScreen` `build` method to navigate to `AppRoutes.tutor` after a 1-second delay using `Future.delayed(const Duration(seconds: 1), () => context.go(AppRoutes.tutor))` inside `initState` — convert `_SplashScreen` to a `StatefulWidget` to do this
    - Keep `AppRoutes`, `_HomeShell`, `_Placeholder`, and all ShellRoute children unchanged
    - Keep the `_SettingsPlaceholder` but remove the logout `ListTile` (no auth in demo)
    - _Requirements: 1 (direct app entry, no login screen)_

  - [ ] 1.3 Create `DemoDatabase` — simplified Drift database with 3 tables
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\data\database\demo_database.dart`
    - Define three Drift table classes:
      ```
      class Users — columns: id (INTEGER PRIMARY KEY AUTOINCREMENT), name (TEXT NOT NULL), createdAt (DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)
      class ContentChunks — columns: id (INTEGER PRIMARY KEY AUTOINCREMENT), chapter (TEXT NOT NULL), chunkText (TEXT NOT NULL)
      class ChatHistoryTable — columns: id (INTEGER PRIMARY KEY AUTOINCREMENT), question (TEXT NOT NULL), answer (TEXT NOT NULL), timestamp (DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)
      ```
    - Annotate with `@DriftDatabase(tables: [Users, ContentChunks, ChatHistoryTable])`
    - Use `driftDatabase(name: 'clarivo_demo.db')` as the `QueryExecutor`
    - Run `dart run build_runner build --delete-conflicting-outputs` to generate `.g.dart` file
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\core\providers\demo_database_provider.dart`
    - Export a `demoDatabaseProvider` as a Riverpod `Provider<DemoDatabase>` (lazy singleton, never disposed)
    - _Requirements: 2 (local database), 3 (chat history persistence)_

  - [ ] 1.4 Write `ContentSeeder` — inserts ~25 plain-text chunks on first run
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\data\seeder\content_seeder.dart`
    - Define class `ContentSeeder` with a single static method: `static Future<void> seedIfEmpty(DemoDatabase db)`
    - Inside `seedIfEmpty`: query `SELECT COUNT(*) FROM content_chunks`; if count > 0, return immediately (idempotent)
    - If empty, insert the following chunks using `db.batch(...)`:
      - **Chemical Reactions and Equations** (~10 chunks): definitions of chemical reactions, types (combination, decomposition, displacement, double displacement), balancing equations, exothermic/endothermic reactions, oxidation/reduction, corrosion, rancidity
      - **Acids, Bases and Salts** (~8 chunks): properties of acids/bases, pH scale, neutralisation, common acids and bases (HCl, H₂SO₄, NaOH), salts and their uses, water of crystallisation
      - **Metals and Non-metals** (~8 chunks): physical/chemical properties of metals and non-metals, reactivity series, extraction of metals, ionic bonding, corrosion prevention
    - Each chunk row: `chapter` = chapter name (one of the three above), `chunkText` = 3–6 sentence plain English description
    - Call `ContentSeeder.seedIfEmpty(db)` in `main.dart` after `ProviderScope` initialises, before `runApp`
    - _Requirements: 2.1 (CBSE Class 10 Science content seeded at first run)_

- [ ] 2. Phase 2 — Clara AI (core feature)

  - [ ] 2.1 Write `GroqClient` — HTTP wrapper for Groq chat completions
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\domain\ai\groq_client.dart`
    - Import `package:http/http.dart` and `package:flutter_dotenv/flutter_dotenv.dart`
    - Define class `GroqClient` with a single async method: `Future<String> complete(String systemPrompt, String userMessage)`
    - Implementation:
      - Read API key: `final apiKey = dotenv.env['GROQ_API_KEY'] ?? ''`; throw `StateError` if empty
      - POST to `https://api.groq.com/openai/v1/chat/completions`
      - Headers: `Content-Type: application/json`, `Authorization: Bearer $apiKey`
      - Body (JSON):
        ```json
        {
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {"role": "system", "content": "<systemPrompt>"},
            {"role": "user", "content": "<userMessage>"}
          ],
          "max_tokens": 512,
          "temperature": 0.7
        }
        ```
      - On HTTP 200: parse `choices[0].message.content` from response JSON and return it
      - On non-200: throw `Exception('Groq API error ${response.statusCode}: ${response.body}')` 
    - _Requirements: 4.1 (Groq API integration), 4.2 (llama-3.3-70b-versatile model)_

  - [ ] 2.2 Write `KeywordSearchService` — retrieves relevant content chunks from SQLite
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\domain\ai\keyword_search_service.dart`
    - Define class `KeywordSearchService` with constructor `KeywordSearchService(this._db)` where `_db` is `DemoDatabase`
    - Implement `Future<String> findContext(String question)`:
      - Tokenise `question` to lowercase words by splitting on `RegExp(r'\W+')`
      - Filter out stop words: `{'a','an','the','is','are','was','were','what','how','why','when','where','which','who','in','on','at','of','to','for','and','or','but','not','it','its','be','do','does','did','has','have','had','will','can','could','would','should','me','my','i','we','you','they','their','there','this','that','these','those'}`
      - Keep only words with `length >= 3`; take first 5 keywords
      - For each keyword, query: `SELECT id, chapter, chunk_text FROM content_chunks WHERE chunk_text LIKE '%keyword%' LIMIT 3`
      - Deduplicate results by `id`; keep at most 5 unique chunks total
      - Return joined string: `chunk.chapter + ': ' + chunk.chunkText` separated by `'\n\n'`
      - If no chunks found, return empty string `''`
    - _Requirements: 2.2 (keyword-based retrieval from content table)_

  - [ ] 2.3 Write `ClaraService` — orchestrates search + Groq + history persistence
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\domain\ai\clara_service.dart`
    - Define class `ClaraService` with constructor `ClaraService(this._db, this._groqClient, this._searchService)`
    - Implement `Future<String> ask(String question)`:
      1. Call `_searchService.findContext(question)` → `context`
      2. Build system prompt:
         ```
         You are Clara, a friendly AI tutor helping CBSE Class 10 students.
         Answer only based on the context provided. If the context does not contain
         enough information, say "I don't have enough information on that topic yet."
         Keep answers concise and student-friendly (3–5 sentences).
         
         Context:
         <context>
         ```
         (Use `'(No context found — answer from general knowledge.)'` when context is empty)
      3. Call `_groqClient.complete(systemPrompt, question)` → `answer`
      4. Insert into `chat_history`: `db.into(db.chatHistoryTable).insert(ChatHistoryTableCompanion.insert(question: question, answer: answer, timestamp: Value(DateTime.now())))`
      5. Return `answer`
    - Export a `claraServiceProvider` Riverpod `Provider<ClaraService>` in `c:\Hackathon Kiro AI\Clarivo\lib\core\providers\clara_service_provider.dart` that reads `demoDatabaseProvider`
    - _Requirements: 3 (chat history saved), 4 (Groq-powered answers), 2.2 (context injected into prompt)_

- [ ] 3. Phase 3 — Clara UI (chat screen)

  - [ ] 3.1 Build `ClaraScreen` — the main chat UI, replaces `/home/tutor` placeholder
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\features\tutor\clara_screen.dart`
    - `ClaraScreen` is a `ConsumerStatefulWidget`
    - State holds: `List<_Message> _messages`, `bool _isLoading`, `TextEditingController _controller`, `ScrollController _scrollController`
    - `_Message` is a local data class with `String text` and `bool isUser`
    - Layout (Column):
      1. `Expanded` → `ListView.builder` of `_MessageBubble` widgets, controller = `_scrollController`
      2. `_InputBar` at the bottom (text field + send button)
    - `_MessageBubble` widget:
      - User messages: right-aligned, blue background (`colorScheme.primary`), white text, rounded corners (`BorderRadius.circular(16)`)
      - Clara messages: left-aligned, grey background (`colorScheme.surfaceVariant`), default text colour
      - Max width 75% of screen
    - Send button behaviour:
      - Disabled when `_isLoading == true` or text field is empty
      - On tap: add user message to `_messages`, set `_isLoading = true`, call `claraService.ask(question)`, add Clara's response to `_messages`, set `_isLoading = false`, scroll to bottom
      - While loading: show `CircularProgressIndicator` in place of the send icon
    - Handle errors: catch exceptions from `ClaraService.ask`, add an error message bubble ("Sorry, I couldn't reach Clara. Please check your internet connection.")
    - Auto-scroll to bottom after each new message using `_scrollController.animateTo(_scrollController.position.maxScrollExtent, ...)`
    - Wire `ClaraScreen` into `router.dart` at `AppRoutes.tutor` (replace `_Placeholder`)
    - _Requirements: 5 (chat UI), 5.1 (user bubbles), 5.2 (Clara bubbles), 5.3 (send button), 5.4 (loading state), 6 (error handling)_

  - [ ] 3.2 Checkpoint — test the full Clara flow end-to-end
    - Run the app in Chrome (`flutter run -d chrome`)
    - Type a question about Chemical Reactions (e.g. "What is a combination reaction?")
    - Verify: question appears as a user bubble, loading spinner shows, Groq returns an answer, answer appears as a Clara bubble
    - Type a question about Acids and Bases; verify context is found and answer is relevant
    - Verify chat history is persisted by hot-restarting and checking that previous messages are not shown (history display is not required for demo — persistence is backend-only)
    - Fix any issues before proceeding to Phase 4
    - _Requirements: 2 (content retrieval works), 4 (Groq API works), 5 (UI renders correctly)_

- [ ] 4. Phase 4 — Website landing page

  - [ ] 4.1 Build `LandingScreen` — Flutter Web landing page at `/`
    - Create `c:\Hackathon Kiro AI\Clarivo\lib\features\landing\landing_screen.dart`
    - `LandingScreen` is a `StatelessWidget`
    - Layout: centred `Column` inside a `SingleChildScrollView`, max width 600px, padding 32px
    - Sections (top to bottom):
      1. **Logo + name**: `Icon(Icons.school_rounded, size: 80)` + `Text('Clarivo')` in `headlineLarge` bold
      2. **Tagline**: `Text('Your personal AI study companion')` in `titleMedium`, muted colour
      3. **Description**: 2-sentence paragraph — "Clara helps CBSE Class 10 students understand Science topics using AI-powered explanations. Ask any question about Chemical Reactions, Acids & Bases, or Metals & Non-metals and get a clear, student-friendly answer."
      4. **Try Online button**: `FilledButton` labelled "Try Clara Online →", calls `context.go(AppRoutes.tutor)` on tap
      5. **Download section** (row of two `OutlinedButton`s):
         - "Download for Android" — opens URL `https://clarivo.app/download/clarivo-demo.apk` (placeholder) using `url_launcher` or a simple `html.window.open` call for web
         - "Download for Windows" — opens URL `https://clarivo.app/download/clarivo-demo-windows.zip` (placeholder)
      6. **Footer**: small muted text — "Built for the AI Hackathon · September 2025"
    - For the URL launch on web: use `dart:html` `window.open(url, '_blank')` wrapped in a `kIsWeb` check — no additional package needed
    - _Requirements: 7 (landing page), 7.1 (logo + tagline), 7.2 (Try Clara button), 7.3 (download buttons)_

  - [ ] 4.2 Update router — `/` shows `LandingScreen`, remove remaining auth routes
    - Open `c:\Hackathon Kiro AI\Clarivo\lib\core\router.dart`
    - Replace the `_SplashScreen` `GoRoute` builder at `/` with `LandingScreen`
    - Remove the `_SplashScreen` class entirely (no longer needed)
    - Ensure `AppRoutes.tutor` (`/home/tutor`) routes to `ClaraScreen` (already done in 3.1)
    - Remove `_SettingsPlaceholder` reference to `authStateProvider` / `currentAccountProvider` if still present — replace with a simple `Scaffold` with `AppBar(title: Text('Settings'))` and a `ListTile` saying "Full settings coming soon"
    - Verify the app opens to the landing page and "Try Clara Online →" navigates to the chat
    - _Requirements: 1 (direct entry — landing page for web, chat for app), 7 (landing page at root)_

- [ ] 5. Phase 5 — Build deliverables

  - [ ] 5.1 Build Flutter Web release
    - Run: `flutter build web --release --web-renderer canvaskit` from `c:\Hackathon Kiro AI\Clarivo`
    - Verify `build/web/index.html` exists and the `build/web/` directory is non-empty
    - If build fails, check for import errors (especially removed auth imports) and fix them
    - _Requirements: 8.1 (web build for landing page and online demo)_

  - [ ] 5.2 Build Android debug APK
    - Run: `flutter build apk --debug` from `c:\Hackathon Kiro AI\Clarivo`
    - Verify APK exists at `build/app/outputs/flutter-apk/app-debug.apk`
    - _Requirements: 8.2 (Android APK for hackathon distribution)_

  - [ ] 5.3 Document deployment steps for GitHub Pages / Netlify
    - Create `c:\Hackathon Kiro AI\Clarivo\DEPLOY.md` with the following steps:
      ```
      ## Deploy to Netlify (recommended)
      1. Build: flutter build web --release --web-renderer canvaskit
      2. Drag-and-drop the build/web/ folder to app.netlify.com/drop
      3. Note the generated URL (e.g. https://xyz.netlify.app)
      4. Update the download button URLs in landing_screen.dart to point to the APK hosted on the same Netlify site or a GitHub release asset
      5. Rebuild and redeploy

      ## Deploy to GitHub Pages (alternative)
      1. Push the repo to GitHub
      2. Build: flutter build web --release --base-href /clarivo/ --web-renderer canvaskit
      3. Copy build/web/ contents to the gh-pages branch (or use the gh-pages npm package)
      4. Enable GitHub Pages in repo Settings → Pages → Source: gh-pages branch
      ```
    - _Requirements: 8.3 (website publicly accessible for demo)_

---

## Future Updates (deferred — not for hackathon)

These features are planned for the full Clarivo product and are deliberately out of scope for the September 10 demo:

- Full authentication system (register, login, session restore, secure credential storage)
- Multi-account support and account switching
- 6-language support (Hindi, Tamil, Telugu, Kannada, Bengali + English)
- On-device LLM (fllama/llama.cpp with qwen2.5-3b GGUF) — offline AI
- Vector search with all-MiniLM-L6-v2 embeddings (replace keyword search)
- OCR input (camera/gallery → question text via ML Kit / Tesseract)
- PDF ingestion and custom content package upload
- Content package management (CBSE Class 6–12 full matrix, competitive tracks)
- Progress tracker (session time, question count, topic breakdown dashboard)
- Push notifications (study reminders, daily tips)
- Supervisor/parent dashboard
- iOS build and App Store distribution
- Full CBSE content matrix (all subjects, Classes 6–12)
- Windows desktop build with Tesseract OCR
- Storage management UI (package delete / re-download)

---

## Notes

- Tasks marked `*` are optional and can be skipped for a faster build — there are none in this hackathon plan; all tasks are required
- The `.env` file at `c:\Hackathon Kiro AI\Clarivo\.env` must contain `GROQ_API_KEY=<your_key>` before running
- The `http` package (Task 1.1) is the only new dependency — everything else already exists in `pubspec.yaml`
- The existing full-prod Drift schema (`app_database.dart`, `corpus_database.dart`) can remain in `lib/data/database/` — `DemoDatabase` is a separate, simpler file that coexists with it
- Build runner in Task 1.3 only needs to generate `demo_database.g.dart`; the existing generated files are unaffected if `--delete-conflicting-outputs` is omitted

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["1.3"] },
    { "id": 2, "tasks": ["1.4", "2.1", "2.2"] },
    { "id": 3, "tasks": ["2.3"] },
    { "id": 4, "tasks": ["3.1"] },
    { "id": 5, "tasks": ["3.2"] },
    { "id": 6, "tasks": ["4.1"] },
    { "id": 7, "tasks": ["4.2"] },
    { "id": 8, "tasks": ["5.1", "5.2"] },
    { "id": 9, "tasks": ["5.3"] }
  ]
}
```
