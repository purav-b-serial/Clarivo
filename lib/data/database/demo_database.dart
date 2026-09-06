import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'demo_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

class Users extends Table {
  IntColumn get id => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Content chunks with subject + chapter grouping.
/// Schema version 2 adds the [subject] column.
class ContentChunks extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// e.g. 'Mathematics', 'Social Science', 'Science', 'English', 'Hindi', 'Sanskrit'
  TextColumn get subject => text().withDefault(const Constant('Science'))();
  TextColumn get chapter => text()();
  TextColumn get chunkText => text()();
}

class ChatHistoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  IntColumn get timestamp => integer()();
  /// Subject context active when question was asked (nullable = no filter)
  TextColumn get subject => text().nullable()();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Users, ContentChunks, ChatHistoryItems])
class DemoDatabase extends _$DemoDatabase {
  DemoDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          if (!kIsWeb) {
            await customStatement('PRAGMA journal_mode=WAL');
          }
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Add subject column to content_chunks
            await m.addColumn(contentChunks, contentChunks.subject);
            // Add subject column to chat_history_items
            await m.addColumn(chatHistoryItems, chatHistoryItems.subject);
          }
        },
      );

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<int> contentCount() async {
    final countExpr = contentChunks.id.count();
    final query = selectOnly(contentChunks)..addColumns([countExpr]);
    final result = await query.map((row) => row.read(countExpr)).getSingle();
    return result ?? 0;
  }

  Future<void> clearContent() async {
    await delete(contentChunks).go();
  }

  /// Returns distinct subject names present in the content table.
  Future<List<String>> getSubjects() async {
    final query = selectOnly(contentChunks, distinct: true)
      ..addColumns([contentChunks.subject]);
    final rows = await query.map((r) => r.read(contentChunks.subject)!).get();
    return rows..sort();
  }

  /// Returns distinct chapter names for a given subject.
  Future<List<String>> getChaptersForSubject(String subject) async {
    final query = selectOnly(contentChunks, distinct: true)
      ..addColumns([contentChunks.chapter])
      ..where(contentChunks.subject.equals(subject));
    final rows =
        await query.map((r) => r.read(contentChunks.chapter)!).get();
    return rows;
  }

  /// Returns all chunks for a given chapter.
  Future<List<ContentChunk>> getChunksForChapter(
      String subject, String chapter) async {
    return (select(contentChunks)
          ..where((c) =>
              c.subject.equals(subject) & c.chapter.equals(chapter)))
        .get();
  }

  /// Keyword search optionally filtered to a subject.
  Future<List<ContentChunk>> keywordSearch(String keyword,
      {String? subject, int limit = 3}) async {
    final query = select(contentChunks)
      ..where((c) {
        final textMatch = c.chunkText.lower().like('%${keyword.toLowerCase()}%');
        if (subject != null) {
          return textMatch & c.subject.equals(subject);
        }
        return textMatch;
      })
      ..limit(limit);
    return query.get();
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'clarivo_demo',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        if (result.missingFeatures.isNotEmpty) {
          // ignore: avoid_print
          print(
            'Drift web: using ${result.chosenImplementation} '
            '(missing: ${result.missingFeatures})',
          );
        }
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final demoDatabaseProvider = Provider<DemoDatabase>((ref) {
  return DemoDatabase();
});
