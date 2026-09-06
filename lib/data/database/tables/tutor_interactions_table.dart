import 'package:drift/drift.dart';

/// Immutable record of every Clara Q&A interaction.
///
/// This table is the source of truth for the Progress Tracker. Rows are
/// written atomically inside a transaction that also updates the session
/// heartbeat in [KeyValueStore].
class TutorInteractions extends Table {
  /// UUID v4.
  TextColumn get id => text()();

  /// Account that asked the question.
  TextColumn get accountId => text()();

  /// Groups interactions that belong to the same app session.
  TextColumn get sessionId => text()();

  /// The question text submitted by the student (up to 1000 chars).
  TextColumn get questionText => text()();

  /// Clara's answer text.
  TextColumn get answerText => text()();

  /// JSON-encoded list of corpus_chunk IDs cited in the answer.
  TextColumn get sourceChunkIds => text()();

  /// Human-readable title of the primary source document.
  TextColumn get sourceTitle => text()();

  /// Chapter / section heading of the source passage, if available.
  TextColumn get sourceSection => text().nullable()();

  /// Competitive exam track context active when the question was asked.
  TextColumn get examTrack => text().nullable()();

  /// 1 if the question was submitted via image (OCR), 0 otherwise.
  IntColumn get imageUsed => integer().withDefault(const Constant(0))();

  /// Unix timestamp in milliseconds when the answer was delivered.
  IntColumn get timestamp => integer()();

  /// Wall-clock time in milliseconds from question submission to first token.
  IntColumn get responseTimeMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
