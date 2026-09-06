import 'package:drift/drift.dart';

/// Helper that creates and manages the sqlite-vec virtual table for
/// storing and querying 384-dimensional embedding vectors.
///
/// sqlite-vec uses a non-standard DDL that Drift's code generator cannot
/// produce automatically, so we manage it via raw SQL in the migration.
///
/// The virtual table schema is:
///
/// ```sql
/// CREATE VIRTUAL TABLE vec_chunks USING vec0(
///   chunk_id TEXT,
///   embedding float[384]
/// );
/// ```
///
/// Queries use the sqlite-vec KNN operator:
///
/// ```sql
/// SELECT chunk_id, distance
/// FROM vec_chunks
/// WHERE embedding MATCH ?   -- serialised query vector
/// ORDER BY distance
/// LIMIT 5;
/// ```
///
/// This class exposes the raw SQL strings needed for migrations and queries
/// so they stay in one place.
class VecChunksHelper {
  VecChunksHelper._();

  /// DDL to create the sqlite-vec virtual table.
  static const String createTableSql = '''
    CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks
    USING vec0(
      chunk_id TEXT,
      embedding float[384]
    )
  ''';

  /// DDL to drop the virtual table (used during corpus reset).
  static const String dropTableSql =
      'DROP TABLE IF EXISTS vec_chunks';

  /// Insert a vector row.
  /// Parameters: (chunkId TEXT, embedding BLOB)
  static const String insertSql =
      'INSERT INTO vec_chunks(chunk_id, embedding) VALUES (?, ?)';

  /// Delete a single vector row by chunk ID.
  static const String deleteByChunkIdSql =
      'DELETE FROM vec_chunks WHERE chunk_id = ?';

  /// Delete all vector rows whose chunk_id appears in a sub-select by document.
  /// Used when removing all chunks for a document.
  /// Parameters: (documentId TEXT)
  static const String deleteByDocumentSql = '''
    DELETE FROM vec_chunks
    WHERE chunk_id IN (
      SELECT id FROM corpus_chunks WHERE document_id = ?
    )
  ''';

  /// Delete all vector rows whose chunk_id appears in a sub-select by package.
  /// Parameters: (packageId TEXT)
  static const String deleteByPackageSql = '''
    DELETE FROM vec_chunks
    WHERE chunk_id IN (
      SELECT id FROM corpus_chunks WHERE package_id = ?
    )
  ''';

  /// KNN search returning the top-k most similar vectors.
  /// Parameters: (queryEmbeddingBlob BLOB, k INTEGER)
  static const String knnSearchSql = '''
    SELECT chunk_id, distance
    FROM vec_chunks
    WHERE embedding MATCH ?
    ORDER BY distance
    LIMIT ?
  ''';

  /// KNN search filtered to a specific package (for exam-track prioritisation).
  /// Parameters: (queryEmbeddingBlob BLOB, packageId TEXT, k INTEGER)
  static const String knnSearchByPackageSql = '''
    SELECT v.chunk_id, v.distance
    FROM vec_chunks v
    INNER JOIN corpus_chunks c ON c.id = v.chunk_id
    WHERE v.embedding MATCH ?
      AND c.package_id = ?
    ORDER BY v.distance
    LIMIT ?
  ''';
}
