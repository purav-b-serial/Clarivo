import 'package:drift/drift.dart';

/// Tracks every content package known to the app — both pre-installed CBSE
/// packages and competitive exam tracks.
///
/// The [state] column drives the Storage Manager UI and the RAG retrieval
/// filter: only packages in state 'installed' are included in corpus queries.
class ContentPackages extends Table {
  /// Stable identifier, e.g. "cbse_class9_maths" or "jee".
  TextColumn get id => text()();

  /// Human-readable title, e.g. "Class 9 — Mathematics".
  TextColumn get title => text()();

  /// Content track: 'cbse' | 'jee' | 'neet' | 'upsc' | 'ssc'.
  TextColumn get track => text()();

  /// CBSE class level (6–12). NULL for competitive exam tracks.
  IntColumn get classLevel => integer().nullable()();

  /// Subject name for CBSE packages (e.g. "Mathematics"). NULL for competitive.
  TextColumn get subject => text().nullable()();

  /// Semantic version string, e.g. "1.0.0".
  TextColumn get version => text()();

  /// HTTPS URL to download the package archive. NULL for packages that ship
  /// with the installer and are never re-downloaded.
  TextColumn get downloadUrl => text().nullable()();

  /// Compressed download size in bytes.
  IntColumn get downloadSizeBytes => integer().nullable()();

  /// Installed (uncompressed) size in bytes on disk.
  IntColumn get installedSizeBytes => integer().nullable()();

  /// Lifecycle state: 'installed' | 'deleted' | 'downloading' | 'error'.
  TextColumn get state =>
      text().withDefault(const Constant('installed'))();

  /// Download progress in range 0.0–1.0. Only relevant while state = 'downloading'.
  RealColumn get downloadProgress =>
      real().withDefault(const Constant(0.0))();

  /// Unix timestamp in milliseconds when the package was first installed.
  IntColumn get installedAt => integer().nullable()();

  /// Unix timestamp in milliseconds when the package was last deleted.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
