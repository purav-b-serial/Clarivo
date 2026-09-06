import 'package:drift/drift.dart';

/// Metadata for every document ingested into the Content_Corpus — both
/// pre-installed package content and user-uploaded files.
///
/// The actual file bytes live on the filesystem under the app's support
/// directory. This table holds the metadata and ingestion status only.
class Documents extends Table {
  /// UUID v4.
  TextColumn get id => text()();

  /// Owning account ID. NULL for pre-installed content (shared across accounts).
  TextColumn get accountId => text().nullable()();

  /// Parent content package ID. NULL for user-uploaded documents.
  TextColumn get packageId => text().nullable()();

  /// Original file name as provided by the user or package manifest.
  TextColumn get fileName => text()();

  /// Absolute path to the file on the device filesystem.
  TextColumn get filePath => text()();

  /// File size in bytes.
  IntColumn get fileSizeBytes => integer()();

  /// MIME type: 'application/pdf' | 'text/plain'.
  TextColumn get mimeType => text()();

  /// SHA-256 hex digest of the original file bytes. Used to detect corruption.
  TextColumn get checksum => text()();

  /// Ingestion pipeline state: 'pending' | 'indexing' | 'complete' | 'failed'.
  TextColumn get ingestionStatus => text()();

  /// Competitive exam track association, if any.
  TextColumn get examTrack => text().nullable()();

  /// Unix timestamp in milliseconds when ingestion completed successfully.
  IntColumn get ingestedAt => integer().nullable()();

  /// Unix timestamp in milliseconds when the document record was created.
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
