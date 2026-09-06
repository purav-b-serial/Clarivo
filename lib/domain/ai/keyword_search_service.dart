import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/demo_database.dart';

/// Retrieves up to 5 content chunks relevant to a question via keyword matching.
/// Optionally filters to a specific subject when [subject] is provided.
class KeywordSearchService {
  KeywordSearchService(this._db);

  final DemoDatabase _db;

  static const _stopWords = {
    'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'but', 'with',
    'from', 'by', 'this', 'that', 'it', 'what', 'how', 'why', 'when',
    'which', 'does', 'do', 'did', 'not', 'i', 'me', 'my', 'you', 'your',
    'we', 'our', 'they', 'their', 'its', 'has', 'have', 'had', 'will',
    'can', 'could', 'would', 'should', 'there', 'here', 'where',
    'who', 'us', 'him', 'her', 'she', 'he', 'all', 'each', 'both',
    'some', 'any', 'just', 'also', 'then', 'than', 'about', 'give',
    'tell', 'explain', 'describe', 'define', 'means',
  };

  /// Returns formatted context string of up to 5 matching chunks.
  /// Pass [subject] to restrict search to that subject only.
  Future<String> findContext(String question, {String? subject}) async {
    final words = question
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && !_stopWords.contains(w))
        .toSet()
        .take(8)
        .toList();

    if (words.isEmpty) return '';

    final seen = <int>{};
    final results = <ContentChunk>[];

    for (final word in words) {
      if (results.length >= 5) break;
      final rows = await _db.keywordSearch(word, subject: subject, limit: 3);
      for (final row in rows) {
        if (!seen.contains(row.id)) {
          seen.add(row.id);
          results.add(row);
          if (results.length >= 5) break;
        }
      }
    }

    if (results.isEmpty) return '';

    return results
        .map((c) => '[${c.subject} — ${c.chapter}]\n${c.chunkText}')
        .join('\n\n');
  }
}

final keywordSearchProvider = Provider<KeywordSearchService>((ref) {
  return KeywordSearchService(ref.watch(demoDatabaseProvider));
});
