# Design Document: Clarivo — Hackathon Demo

## Overview

Clarivo is a Flutter app + Flutter Web landing page for the hackathon demo. It opens straight to a chat screen where a student can ask questions about CBSE Class 10 Science. Questions are answered by the Groq API (llama-3.3-70b-versatile) using relevant text chunks retrieved from a local SQLite database via keyword search.

No auth. No multi-account. Single implicit profile. Internet required for Groq API calls.

---

## 1. Architecture Overview

```
┌────────────────────────────────────────────────┐
│               Flutter UI Layer                  │
│  LandingScreen (web only)  │  ChatScreen        │
│  GoRouter: /  → landing    │  /chat → chat      │
└──────────────┬─────────────────────┬────────────┘
               │                     │
               ▼                     ▼
┌─────────────────────┐   ┌────────────────────────┐
│   KeywordSearch     │   │      GroqClient         │
│  (pure Dart fn)     │   │  (http POST to Groq)    │
└──────────┬──────────┘   └───────────┬────────────┘
           │                          │
           ▼                          │
┌─────────────────────┐               │
│   AppDatabase       │               │
│   (Drift + SQLite)  │◄──────────────┘
│   ┌─────────────┐   │  saves chat_history rows
│   │ users       │   │
│   │ content     │   │
│   │ chat_history│   │
│   └─────────────┘   │
└─────────────────────┘
```

Data flows on every question:
1. User types question → `ChatScreen`
2. `KeywordSearch.retrieve(question)` → up to 5 `content` rows from SQLite
3. `GroqClient.ask(question, chunks)` → HTTP POST to Groq API
4. Response displayed → saved to `chat_history`

---

## 2. Simplified Data Model

Three tables managed by Drift. Defined as a single `AppDatabase`.

### `users` — single-row implicit profile

```sql
CREATE TABLE users (
  id         INTEGER PRIMARY KEY,
  created_at INTEGER NOT NULL   -- Unix ms, set on first run
);
-- Always contains exactly one row (id = 1).
```

### `content` — seeded text chunks

```sql
CREATE TABLE content (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  chapter_name TEXT    NOT NULL,  -- e.g. 'Chemical Reactions and Equations'
  chunk_text   TEXT    NOT NULL   -- plain-text paragraph/section chunk
);
```

### `chat_history` — question/answer log

```sql
CREATE TABLE chat_history (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  question     TEXT    NOT NULL,
  answer       TEXT    NOT NULL,
  timestamp    INTEGER NOT NULL   -- Unix ms
);
```

### Drift table classes (abbreviated)

```dart
class Users extends Table {
  IntColumn get id => integer()();
  IntColumn get createdAt => integer()();
  @override
  Set<Column> get primaryKey => {id};
}

class Content extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get chapterName => text()();
  TextColumn get chunkText => text()();
}

class ChatHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  IntColumn get timestamp => integer()();
}

@DriftDatabase(tables: [Users, Content, ChatHistory])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'clarivo.db'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedContentIfEmpty();
      await into(users).insert(UsersCompanion.insert(
        id: const Value(1),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    },
  );
}
```

---

## 3. Content Seeding Strategy

Seeding happens once, inside `MigrationStrategy.onCreate`, before the UI is shown.

### Seed data source

Plain-text chunks are stored as a Dart `const List<Map<String, String>>` in `lib/data/seed/seed_content.dart`. Each entry has `chapter` and `text` keys. Content is hand-curated paragraph-level excerpts from CBSE Class 10 Science NCERT:

- **Chemical Reactions and Equations** — ~15 chunks covering: definition of chemical change, balancing equations, types of reactions (combination, decomposition, displacement, double displacement, redox), corrosion, rancidity.
- **Acids, Bases and Salts** — ~15 chunks covering: properties, indicators, neutralisation, pH scale, salts and their uses, common salt preparations.
- **Metals and Non-metals** — ~15 chunks covering: physical/chemical properties, reactivity series, ionic bond formation, extraction of metals, corrosion prevention.

~45 chunks total, each 150–300 words.

### Seeding function

```dart
Future<void> _seedContentIfEmpty() async {
  final count = await (selectOnly(content)
    ..addColumns([content.id.count()])
  ).map((row) => row.read(content.id.count())).getSingle();

  if (count != null && count > 0) return; // already seeded

  await batch((b) {
    b.insertAll(content, seedChunks.map((c) => ContentCompanion.insert(
      chapterName: Value(c['chapter']!),
      chunkText: Value(c['text']!),
    )));
  });
}
```

The `seedChunks` list lives in `lib/data/seed/seed_content.dart` as a top-level `const`.

---

## 4. Keyword Search Algorithm

Pure Dart function — no dependencies beyond `dart:core` and the Drift database.

```
Input:  question string
Output: List<ContentRow>  (max 5, deduplicated by id)

Steps:
1. Normalise: lowercase, strip punctuation.
2. Split on whitespace → raw words.
3. Remove stop words (a, an, the, is, are, was, were, in, on, of, to, and, or, …).
4. Deduplicate words → Set<String> keywords.
5. For each keyword:
     SELECT * FROM content WHERE LOWER(chunk_text) LIKE '%<keyword>%'
6. Collect all results, deduplicate by chunk id (LinkedHashMap preserves order).
7. Return first 5 unique chunks.
```

Implementation lives in `lib/data/search/keyword_search.dart`:

```dart
class KeywordSearch {
  final AppDatabase _db;
  KeywordSearch(this._db);

  static const _stopWords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or',
    'but', 'with', 'from', 'by', 'this', 'that', 'it', 'what',
    'how', 'why', 'when', 'which', 'does', 'do', 'did', 'not',
    'i', 'me', 'my', 'you', 'your', 'we', 'our',
  };

  Future<List<ContentRow>> retrieve(String question) async {
    final words = question
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !_stopWords.contains(w))
        .toSet();

    if (words.isEmpty) return [];

    final seen = <int>{};
    final results = <ContentRow>[];

    for (final word in words) {
      if (results.length >= 5) break;
      final rows = await (select(content)
        ..where((c) => c.chunkText.lower().like('%$word%'))
      ).get();
      for (final row in rows) {
        if (!seen.contains(row.id)) {
          seen.add(row.id);
          results.add(row);
          if (results.length >= 5) break;
        }
      }
    }
    return results;
  }
}
```

If `retrieve` returns an empty list, the prompt is sent to Groq without context (still valid per Requirement 4.3).

---

## 5. Groq API Client Design

### HTTP endpoint

```
POST https://api.groq.com/openai/v1/chat/completions
Content-Type: application/json
Authorization: Bearer <GROQ_API_KEY from .env>
```

### Dependencies

- `http` package (add to `pubspec.yaml`)
- `flutter_dotenv` (already installed) — loads `.env` at startup

### Request body

```dart
{
  "model": "llama-3.3-70b-versatile",
  "messages": [
    { "role": "system",  "content": systemPrompt },
    { "role": "user",    "content": userPrompt }
  ],
  "temperature": 0.3,
  "max_tokens": 512
}
```

### Prompt construction

```dart
String buildSystemPrompt(List<ContentRow> chunks) {
  final context = chunks.isEmpty
      ? ''
      : '\n\nReference material from CBSE Class 10 Science:\n' +
        chunks.mapIndexed((i, c) =>
          '[${i + 1}] (${c.chapterName})\n${c.chunkText}'
        ).join('\n\n');

  return '''You are Clara, a friendly AI study assistant for CBSE Class 10 students.
Answer the student\'s question clearly and concisely using the reference material below when available.
If the reference material doesn\'t cover the topic, answer from your knowledge but keep the answer appropriate for Class 10.
$context''';
}
```

### GroqClient class

```dart
// lib/data/groq/groq_client.dart

class GroqClient {
  static const _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  final http.Client _http;
  GroqClient({http.Client? client}) : _http = client ?? http.Client();

  Future<String> ask({
    required String question,
    required List<ContentRow> context,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final response = await _http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {'role': 'system', 'content': buildSystemPrompt(context)},
              {'role': 'user',   'content': question},
            ],
            'temperature': 0.3,
            'max_tokens': 512,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['choices'][0]['message']['content'] as String;
    } else {
      throw GroqApiException(response.statusCode, response.body);
    }
  }
}

class GroqApiException implements Exception {
  final int statusCode;
  final String body;
  GroqApiException(this.statusCode, this.body);

  @override
  String toString() =>
      'Groq API error $statusCode: ${jsonDecode(body)['error']?['message'] ?? body}';
}
```

### Riverpod providers

```dart
@riverpod
GroqClient groqClient(Ref ref) => GroqClient();

@riverpod
KeywordSearch keywordSearch(Ref ref) =>
    KeywordSearch(ref.watch(appDatabaseProvider));
```

---

## 6. Chat Screen Widget Design

Single `StatefulWidget`, consumed through a `ConsumerStatefulWidget` to access Riverpod providers.

### State

```dart
class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
}
```

`ChatMessage` is a simple value class:

```dart
class ChatMessage {
  final String text;
  final bool isUser;   // true = student, false = Clara
  const ChatMessage({required this.text, required this.isUser});
}
```

### Layout

```
Scaffold
└── Column
    ├── Expanded
    │   └── ListView.builder          ← scrollable message list
    │         items: _messages
    │         each item: _MessageBubble(message)
    └── SafeArea
        └── Padding
            └── Row
                ├── Expanded
                │   └── TextField      ← inputController, multiline
                └── IconButton(send)   ← disabled when _isLoading
```

### Send flow

```dart
Future<void> _onSend() async {
  final text = _inputController.text.trim();
  if (text.isEmpty || _isLoading) return;

  _inputController.clear();
  setState(() {
    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
  });
  _scrollToBottom();

  try {
    final chunks = await ref.read(keywordSearchProvider).retrieve(text);
    final answer = await ref.read(groqClientProvider).ask(
      question: text,
      context: chunks,
    );
    final db = ref.read(appDatabaseProvider);
    await db.into(db.chatHistory).insert(ChatHistoryCompanion.insert(
      question: text,
      answer: answer,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    setState(() => _messages.add(ChatMessage(text: answer, isUser: false)));
  } on GroqApiException catch (e) {
    setState(() => _messages.add(ChatMessage(
      text: 'Sorry, Clara is unavailable right now. ($e)',
      isUser: false,
    )));
  } catch (e) {
    setState(() => _messages.add(ChatMessage(
      text: 'Something went wrong. Please try again.',
      isUser: false,
    )));
  } finally {
    setState(() => _isLoading = false);
    _scrollToBottom();
  }
}

void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}
```

### Message bubble widget

```dart
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
```

---

## 7. Website Landing Page Design

Flutter Web build served as a static site. Two screens, two GoRouter routes.

### Routes

```
/          → LandingScreen
/chat      → ChatScreen  (same widget as native)
```

### LandingScreen layout

```dart
// lib/features/landing/landing_screen.dart

class LandingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon / logo
                Icon(Icons.school_rounded, size: 80,
                     color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),

                // App name
                Text('Clarivo',
                     style: Theme.of(context).textTheme.displayMedium
                       ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Tagline
                Text('Your personal AI study companion for CBSE Class 10',
                     style: Theme.of(context).textTheme.titleLarge,
                     textAlign: TextAlign.center),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Ask Clara anything about Chemical Reactions, Acids & Bases, '
                  'or Metals & Non-metals. Get instant, accurate answers grounded '
                  'in your CBSE Science textbook.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Try Online (primary CTA)
                FilledButton.icon(
                  onPressed: () => context.go('/chat'),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Try Online'),
                ),
                const SizedBox(height: 16),

                // Download row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(_apkUrl)),
                      icon: const Icon(Icons.android),
                      label: const Text('Download for Android'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(_windowsUrl)),
                      icon: const Icon(Icons.desktop_windows_rounded),
                      label: const Text('Download for Windows'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

`_apkUrl` and `_windowsUrl` are `const String` values pointing to the hosted APK/installer (e.g. a GitHub release or Firebase hosting URL). `launchUrl` comes from the `url_launcher` package (add to `pubspec.yaml`).

### Simplified GoRouter for demo

The demo replaces the existing auth-guarded router with a minimal two-route version:

```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  final isWeb = kIsWeb;
  return GoRouter(
    initialLocation: isWeb ? '/' : '/chat',
    routes: [
      GoRoute(path: '/',     builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    ],
  );
});
```

On native (Android/Windows), the initial location bypasses the landing page and goes straight to `/chat`.

---

## 8. Build and Deployment

### Adding the `http` package

```yaml
# pubspec.yaml — add under dependencies:
http: ^1.2.2
url_launcher: ^6.3.1   # for download buttons on landing page
```

### Flutter Web build

```bash
flutter build web --release
# Output: build/web/
```

Host `build/web/` as a static site on Firebase Hosting, GitHub Pages, or Netlify.

Firebase Hosting quick deploy:
```bash
firebase init hosting   # public dir: build/web, single-page app: yes
firebase deploy
```

The web build includes the `.env` file (declared in `pubspec.yaml` assets). The Groq API key is readable in the browser bundle — acceptable for a hackathon demo. For production, proxy calls through a backend.

### Android APK build

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

`minSdkVersion` must be 28 in `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 28
    targetSdkVersion 34
}
```

Upload `app-debug.apk` to a file host (Google Drive, Firebase Hosting, GitHub release) and link from the landing page download button.

### Environment setup for build

```bash
# .env (already declared as asset in pubspec.yaml)
GROQ_API_KEY=gsk_...
```

`flutter_dotenv` loads this in `main.dart`:
```dart
await dotenv.load(fileName: '.env');
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — formally, a universally quantified statement about what the system must do.*

### Property 1: Content table rows are well-formed

*For any* row in the `content` table, the row SHALL have a non-null unique `id`, a non-empty `chapter_name`, and a non-empty `chunk_text`.

**Validates: Requirements 2.3**

### Property 2: Keyword search result count is bounded

*For any* question string submitted to `KeywordSearch.retrieve`, the number of returned chunks SHALL be between 0 and 5 inclusive.

**Validates: Requirements 4.2**

### Property 3: Keyword search results are relevant

*For any* non-empty question string where `KeywordSearch.retrieve` returns a non-empty list, every returned chunk SHALL contain at least one non-stop-word token from the question in its `chunk_text` (case-insensitive).

**Validates: Requirements 4.1**

### Property 4: Groq prompt contains question and context

*For any* question string and any list of context chunks, the HTTP request body assembled by `GroqClient.ask` SHALL contain the question text and the `chunk_text` of every chunk in the context list.

**Validates: Requirements 5.1**

### Property 5: Chat history persistence round-trip

*For any* question/answer pair submitted through the chat send flow, a row SHALL exist in the `chat_history` table with matching `question`, `answer`, and a `timestamp` greater than zero.

**Validates: Requirements 5.5**

### Property 6: Send button disabled during in-flight request

*For any* non-empty input string, immediately after the send button is tapped, the send button SHALL be disabled and remain disabled until a response (success or error) is received.

**Validates: Requirements 6.3, 6.4**
