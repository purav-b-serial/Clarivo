import 'package:drift/drift.dart';

/// Stores relational metadata for every text chunk in the Content_Corpus.
///
/// Each row corresponds to one chunk produced by the text chunker during
/// document ingestion. The raw embedding vector for this chunk lives in the
/// sqlite-vec virtual table [VecChunks], linked by [id].
///
/// This table lives in corpus.db (separate from app.db) so the corpus can be
/// wiped and rebuilt without touching account or progress data.
class CorpusChunks extends Table {
  /// UUID v4 — also used as the vector ID in the sqlite-vec table.
  TextColumn get id => text()();

  /// Parent document this chunk belongs to.
  TextColumn get documentId => text()();

  /// Content package this chunk belongs to. NULL for user-uploaded content.
  TextColumn get packageId => text().nullable()();

  /// Account that owns this chunk. NULL for pre-installed content.
  TextColumn get accountId => text().nullable()();

  /// Zero-based position of this chunk within its parent document.
  IntColumn get chunkIndex => integer()();

  /// The plain-text content of this chunk (up to ~512 tokens).
  TextColumn get textContent => text()();

  /// Approximate token count for this chunk (used for prompt budget checks).
  IntColumn get tokenCount => integer()();

  /// Human-readable document/package title (denormalised for fast citation display).
  TextColumn get sourceTitle => text()();

  /// Section heading extracted from the source document, if available.
  TextColumn get sourceSection => text().nullable()();

  /// SHA-256 hex digest of [textContent]. Used by the corpus integrity checker
  /// (Requirement 16.3) to detect silent corruption.
  TextColumn get checksum => text()();

  /// Unix timestamp in milliseconds when this chunk was indexed.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
