import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/accounts_table.dart';
import 'tables/content_packages_table.dart';
import 'tables/documents_table.dart';
import 'tables/key_value_store_table.dart';
import 'tables/notification_schedules_table.dart';
import 'tables/session_segments_table.dart';
import 'tables/supervisor_relationships_table.dart';
import 'tables/tutor_interactions_table.dart';
import '../../core/constants.dart';

part 'app_database.g.dart';

/// Primary application database.
///
/// Stores all relational data except the Content_Corpus vector index.
/// Kept separate from [CorpusDatabase] so the corpus can be wiped and
/// rebuilt without touching account or progress data.
///
/// WAL mode is enabled at open time for crash-safe writes.
@DriftDatabase(tables: [
  Accounts,
  SupervisorRelationships,
  ContentPackages,
  Documents,
  TutorInteractions,
  SessionSegments,
  NotificationSchedules,
  KeyValueStore,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Schema version. Increment whenever tables change and provide a migration.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Future migrations go here.
        },
        beforeOpen: (details) async {
          // Enable WAL mode for crash-safe, concurrent reads.
          await customStatement('PRAGMA journal_mode=WAL');
          // Enforce foreign key constraints.
          await customStatement('PRAGMA foreign_keys=ON');
        },
      );

  // ---------------------------------------------------------------------------
  // KeyValueStore helpers
  // ---------------------------------------------------------------------------

  /// Reads a single setting by [key]. Returns null if not found.
  Future<String?> getSetting(String key) async {
    final row = await (select(keyValueStore)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Upserts a setting row. Creates it if absent, replaces if present.
  Future<void> setSetting(String key, String value) =>
      into(keyValueStore).insertOnConflictUpdate(
        KeyValueStoreCompanion(
          key: Value(key),
          value: Value(value),
        ),
      );

  /// Deletes a setting by [key].
  Future<void> deleteSetting(String key) =>
      (delete(keyValueStore)..where((t) => t.key.equals(key))).go();
}

// ---------------------------------------------------------------------------
// Drift connection factory
// ---------------------------------------------------------------------------

/// Opens (or creates) the [AppDatabase] file in the platform's application
/// support directory. Uses [driftDatabase] from drift_flutter which handles
/// the correct path on all three platforms.
QueryExecutor _openAppDatabase() {
  return driftDatabase(name: kAppDbName);
}

// ---------------------------------------------------------------------------
// Riverpod providers
// ---------------------------------------------------------------------------

/// Provides the singleton [AppDatabase] instance.
///
/// Disposed when the ProviderScope is destroyed (tests can override this).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(_openAppDatabase());
  ref.onDispose(db.close);
  return db;
});
