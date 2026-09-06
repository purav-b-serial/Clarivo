import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/corpus_chunks_table.dart';
import '../../core/constants.dart';
import '../../data/vector/vec_chunks_helper.dart';

part 'corpus_database.g.dart';

/// Content Corpus database.
///
/// Stores chunk metadata and hosts the sqlite-vec virtual table for KNN
/// vector search. Kept separate from [AppDatabase] so the corpus can be
/// fully deleted and rebuilt (e.g. after a package re-download) without
/// touching account or progress data.
///
/// The sqlite-vec virtual table ([VecChunks]) is not a standard Drift table
/// and is created via raw SQL in [beforeOpen].
@DriftDatabase(tables: [
  CorpusChunks,
])
class CorpusDatabase extends _$CorpusDatabase {
  CorpusDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Create the sqlite-vec virtual table after standard tables.
          await customStatement(VecChunksHelper.createTableSql);
        },
        onUpgrade: (m, from, to) async {
          // Future corpus schema migrations go here.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA foreign_keys=ON');
          // Ensure vec_chunks always exists (e.g. on first open after
          // an app update that wiped build artefacts).
          await customStatement(VecChunksHelper.createTableSql);
        },
      );

  // ---------------------------------------------------------------------------
  // Corpus integrity helper
  // ---------------------------------------------------------------------------

  /// Returns all chunks for [documentId] so the checksum verifier can
  /// re-compute and compare SHA-256 digests.
  Future<List<CorpusChunk>> chunksForDocument(String documentId) =>
      (select(corpusChunks)
            ..where((c) => c.documentId.equals(documentId))
            ..orderBy([(c) => OrderingTerm.asc(c.chunkIndex)]))
          .get();

  /// Deletes all chunks for [documentId] from [corpusChunks].
  /// The caller is responsible for deleting matching rows from vec_chunks
  /// via [VecChunksHelper.deleteByDocumentSql].
  Future<int> deleteChunksForDocument(String documentId) =>
      (delete(corpusChunks)
            ..where((c) => c.documentId.equals(documentId)))
          .go();

  /// Deletes all chunks for [packageId].
  Future<int> deleteChunksForPackage(String packageId) =>
      (delete(corpusChunks)
            ..where((c) => c.packageId.equals(packageId)))
          .go();
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

/// Provides the singleton [CorpusDatabase] instance.
final corpusDatabaseProvider = Provider<CorpusDatabase>((ref) {
  final db = CorpusDatabase(driftDatabase(name: kCorpusDbName));
  ref.onDispose(db.close);
  return db;
});
