# Requirements Document

## Introduction

Clarivo is an AI-powered study companion for CBSE Class 10 students. This document covers the hackathon demo scope only (presentation: 10 September). The app opens directly to a chat interface powered by the Groq API (llama-3.3-70b-versatile), with pre-seeded CBSE Class 10 Science content stored in a local SQLite database. A companion website provides a landing page and an online trial of the chat. No authentication, no multi-account support, and no offline AI — the hackathon build requires an internet connection to use Clara.

---

## Glossary

- **App**: The Clarivo Flutter application (Android APK + Windows desktop build).
- **Clara**: The AI chat assistant feature of the App, powered by the Groq API.
- **Chat_Screen**: The UI screen presenting the message input field, send button, and scrollable message history.
- **Content_DB**: The local SQLite database containing the single users table, content table (seeded text chunks), and chat_history table.
- **Groq_Client**: The component responsible for sending prompts to the Groq API and receiving responses.
- **Keyword_Search**: The retrieval mechanism that searches the content table for chunks whose text contains one or more keywords from the student's question.
- **Seeded_Content**: Plain-text chunks from CBSE Class 10 Science — chapters: Chemical Reactions and Equations; Acids, Bases and Salts; Metals and Non-metals — stored in the content table at first run.
- **Website**: The Flutter Web build serving the landing page and the online Clara chat trial.

---

## Requirements

### Requirement 1: Direct App Entry

**User Story:** As a student, I want the app to open straight to the Clara chat screen so that I can start asking questions immediately without signing in.

#### Acceptance Criteria

1. WHEN the App is launched, THE App SHALL navigate directly to the Chat_Screen without presenting any login, registration, or account-selection screen.
2. THE App SHALL operate with a single implicit local profile stored in the Content_DB; THE App SHALL NOT require the student to create or select a profile.

---

### Requirement 2: Local SQLite Database

**User Story:** As a developer, I want a minimal SQLite schema so that the demo stores only what it needs.

#### Acceptance Criteria

1. WHEN the App runs for the first time, THE Content_DB SHALL create three tables: `users` (single-row profile), `content` (seeded text chunks), and `chat_history` (question/answer pairs with timestamps).
2. WHEN the App runs for the first time, THE Content_DB SHALL seed the `content` table with plain-text chunks from the three Seeded_Content chapters before the Chat_Screen is shown.
3. THE Content_DB SHALL store each content chunk as a row containing at minimum: a unique ID, a chapter name, and the chunk text.

---

### Requirement 3: Seeded CBSE Class 10 Science Content

**User Story:** As a student, I want the app to already contain Class 10 Science material so that I can ask questions without uploading anything.

#### Acceptance Criteria

1. THE Content_DB SHALL contain Seeded_Content for exactly three CBSE Class 10 Science chapters: Chemical Reactions and Equations; Acids, Bases and Salts; Metals and Non-metals.
2. THE App SHALL NOT require any download or internet connection to read the Seeded_Content once the database has been seeded.

---

### Requirement 4: Keyword-Based Context Retrieval

**User Story:** As a student, I want Clara to find the most relevant parts of the textbook so that her answers are grounded in the seeded content.

#### Acceptance Criteria

1. WHEN a student submits a question, THE Keyword_Search SHALL query the `content` table for chunks whose text contains one or more keywords extracted from the question.
2. THE Keyword_Search SHALL return up to 5 matching chunks to be included as context in the Groq API prompt.
3. IF no chunks match the student's keywords, THEN THE Groq_Client SHALL send the question to the Groq API without retrieved context, and THE Chat_Screen SHALL display Clara's response without modification.

---

### Requirement 5: Clara AI Chat via Groq API

**User Story:** As a student, I want to type a question and receive a clear answer from Clara so that I can resolve doubts quickly.

#### Acceptance Criteria

1. WHEN a student submits a question, THE Groq_Client SHALL send a prompt containing the retrieved context chunks and the student's question to the Groq API using the `llama-3.3-70b-versatile` model.
2. THE Groq_Client SHALL read the Groq API key exclusively from the `.env` file at runtime and SHALL NOT hard-code the key in source code.
3. WHEN the Groq API returns a response, THE Chat_Screen SHALL display the response as Clara's message in the message list.
4. IF the Groq API returns an error or the request times out, THEN THE Chat_Screen SHALL display a descriptive error message to the student and SHALL NOT crash.
5. THE Chat_Screen SHALL save each question and Clara's response as a row in the `chat_history` table, including a timestamp.

---

### Requirement 6: Chat Screen UI

**User Story:** As a student, I want a simple, usable chat interface so that asking questions feels natural.

#### Acceptance Criteria

1. THE Chat_Screen SHALL display a scrollable list of messages showing the student's questions and Clara's answers in chronological order.
2. THE Chat_Screen SHALL provide a text input field and a send button.
3. WHEN a student taps the send button or submits the input field, THE Chat_Screen SHALL add the student's question to the message list immediately and disable the send button until Clara's response is received.
4. WHEN Clara's response is received, THE Chat_Screen SHALL append the response to the message list and re-enable the send button.
5. WHEN a new message is added to the message list, THE Chat_Screen SHALL automatically scroll to the most recent message.

---

### Requirement 7: Official Website — Landing Page

**User Story:** As a visitor, I want to see what Clarivo is on the website so that I can understand the app and find the download links.

#### Acceptance Criteria

1. THE Website SHALL display a landing page containing: the app name "Clarivo", a tagline, a brief description of the app, a download button for the Android APK, and a download button for the Windows installer.
2. THE Website SHALL display a "Try Online" button on the landing page that navigates the visitor to the online Clara chat.
3. THE Website landing page SHALL be accessible at the root URL of the hosted Flutter Web build.

---

### Requirement 8: Official Website — Online Clara Chat

**User Story:** As a visitor, I want to try Clara in the browser without installing anything so that I can see the demo live.

#### Acceptance Criteria

1. WHEN a visitor clicks "Try Online" on the landing page, THE Website SHALL navigate to the Chat_Screen within the same Flutter Web app.
2. THE Chat_Screen on the Website SHALL provide the same question-input, send-button, and message-list experience as the native App.
3. THE Website Clara chat SHALL use the same Groq API integration and Keyword_Search logic as the native App.

---

### Requirement 9: Android APK Build

**User Story:** As a hackathon judge, I want to install the app from an APK link so that I can test it on an Android device.

#### Acceptance Criteria

1. THE App SHALL produce a functional debug-signed APK via `flutter build apk`.
2. THE APK SHALL target Android 9.0 (API level 28) and later.
3. THE Website download button for Android SHALL link to the generated APK file.

---

## Future Updates (Deferred — Not for Hackathon)

The following features are explicitly out of scope for the September 10 demo and are tracked for future development:

- **Multi-account authentication** — login/register screens, password hashing, session tokens
- **6-language UI support** — Hindi, Tamil, Telugu, Kannada, Bengali
- **Supervisor Dashboard** — parent/teacher progress monitoring
- **Full content matrix** — CBSE Class 6–12 all subjects + JEE / NEET / UPSC / SSC tracks
- **On-device LLM** — llama.cpp / fllama integration for offline AI inference
- **Vector search** — ONNX embeddings + sqlite-vec semantic retrieval
- **OCR / image input** — photograph a question and extract text
- **Content package management** — download, delete, re-download subject packs
- **Progress tracker** — study time, topic coverage, question history dashboard
- **Push / local notifications** — study reminders and daily tips
- **Offline-first AI** — the hackathon build requires an internet connection for Groq API calls
- **iOS build** — not targeted for the hackathon demo
