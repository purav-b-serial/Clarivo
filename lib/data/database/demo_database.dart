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

/// Content chunks with class + subject + chapter grouping.
/// Schema version 2 adds the [subject] column.
/// Schema version 3 adds the [classNumber] column.
class ContentChunks extends Table {
  IntColumn get id => integer().autoIncrement()();
  /// CBSE class number this chunk belongs to (e.g. 10, 12).
  IntColumn get classNumber => integer().withDefault(const Constant(10))();
  /// e.g. 'Mathematics', 'Social Science', 'Science', 'English', 'Hindi', 'Sanskrit', 'Physics'
  TextColumn get subject => text().withDefault(const Constant('Science'))();
  TextColumn get chapter => text()();
  TextColumn get chunkText => text()();
}

/// Simple key-value store for app metadata (e.g. content seed version).
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class ChatHistoryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  IntColumn get timestamp => integer()();
  /// Subject context active when question was asked (nullable = no filter)
  TextColumn get subject => text().nullable()();
  /// Class context active when question was asked (nullable = no filter)
  IntColumn get classNumber => integer().nullable()();
  /// Chapters/topics actually used from the notes to answer, joined by " | ".
  /// Empty string means the answer came from general knowledge (no notes matched).
  TextColumn get topicsUsed => text().withDefault(const Constant(''))();
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Users, ContentChunks, ChatHistoryItems, AppMeta])
class DemoDatabase extends _$DemoDatabase {
  DemoDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

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
          if (from < 3) {
            // Add class + topic tracking columns
            await m.addColumn(contentChunks, contentChunks.classNumber);
            await m.addColumn(chatHistoryItems, chatHistoryItems.classNumber);
            await m.addColumn(chatHistoryItems, chatHistoryItems.topicsUsed);
          }
          if (from < 4) {
            // Add app metadata table (stores content seed version)
            await m.createTable(appMeta);
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

  /// Reads the stored seed version (0 if never seeded).
  Future<int> getSeedVersion() async {
    final row = await (select(appMeta)
          ..where((t) => t.key.equals('seed_version')))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '0') ?? 0;
  }

  /// Persists the seed version after (re)seeding.
  Future<void> setSeedVersion(int version) async {
    await into(appMeta).insertOnConflictUpdate(
      AppMetaCompanion.insert(key: 'seed_version', value: '$version'),
    );
  }

  Future<void> clearContent() async {
    await delete(contentChunks).go();
  }

  /// Returns distinct CBSE class numbers that have content, ascending.
  Future<List<int>> getAvailableClasses() async {
    final query = selectOnly(contentChunks, distinct: true)
      ..addColumns([contentChunks.classNumber]);
    final rows =
        await query.map((r) => r.read(contentChunks.classNumber)!).get();
    return rows..sort();
  }

  /// Returns distinct subject names present, optionally filtered by class.
  Future<List<String>> getSubjects({int? classNumber}) async {
    final query = selectOnly(contentChunks, distinct: true)
      ..addColumns([contentChunks.subject]);
    if (classNumber != null) {
      query.where(contentChunks.classNumber.equals(classNumber));
    }
    final rows = await query.map((r) => r.read(contentChunks.subject)!).get();
    return rows..sort();
  }

  /// Returns distinct chapter names for a given subject (optionally class-filtered).
  Future<List<String>> getChaptersForSubject(String subject,
      {int? classNumber}) async {
    final query = selectOnly(contentChunks, distinct: true)
      ..addColumns([contentChunks.chapter])
      ..where(contentChunks.subject.equals(subject));
    if (classNumber != null) {
      query.where(contentChunks.classNumber.equals(classNumber));
    }
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

  /// Keyword search optionally filtered to a subject and/or class.
  Future<List<ContentChunk>> keywordSearch(String keyword,
      {String? subject, int? classNumber, int limit = 3}) async {
    final query = select(contentChunks)
      ..where((c) {
        var cond = c.chunkText.lower().like('%${keyword.toLowerCase()}%');
        if (subject != null) {
          cond = cond & c.subject.equals(subject);
        }
        if (classNumber != null) {
          cond = cond & c.classNumber.equals(classNumber);
        }
        return cond;
      })
      ..limit(limit);
    return query.get();
  }

  /// Keyword search across MULTIPLE subjects and classes at once (used by
  /// competitive-exam mode, e.g. JEE/NEET which span Class 11 & 12 and
  /// several subjects simultaneously). Empty lists mean "no filter" for that
  /// dimension.
  Future<List<ContentChunk>> keywordSearchMulti(String keyword,
      {List<String> subjects = const [],
      List<int> classNumbers = const [],
      int limit = 4}) async {
    final query = select(contentChunks)
      ..where((c) {
        var cond = c.chunkText.lower().like('%${keyword.toLowerCase()}%');
        if (subjects.isNotEmpty) {
          cond = cond & c.subject.isIn(subjects);
        }
        if (classNumbers.isNotEmpty) {
          cond = cond & c.classNumber.isIn(classNumbers);
        }
        return cond;
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
