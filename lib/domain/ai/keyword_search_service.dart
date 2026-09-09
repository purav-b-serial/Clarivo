import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/demo_database.dart';

/// Result of a context search: the formatted notes string plus the distinct
/// chapters (topics) those notes came from, so progress can record exactly
/// which topics were used to answer.
class SearchResult {
  const SearchResult({required this.context, required this.topics});
  final String context;
  final List<String> topics;

  bool get isEmpty => context.isEmpty;
}

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

  /// Extracts meaningful keywords from a question. Keeps letters/digits from
  /// every script (Latin + Devanagari, etc.); drops English stop-words.
  List<String> _keywords(String question) {
    final cleaned = question
        .toLowerCase()
        .replaceAll(
            RegExp(r'''[.,;:!?"'`(){}\[\]<>/\\|@#$%^&*+=~—–\-]'''), ' ');
    final isLatin = RegExp(r'^[a-z0-9]+$');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((w) {
          if (w.isEmpty) return false;
          if (isLatin.hasMatch(w)) {
            return w.length >= 3 && !_stopWords.contains(w);
          }
          return w.length >= 2;
        })
        .toSet()
        .take(10)
        .toList();
  }

  /// Builds a SearchResult from a list of matched chunks.
  SearchResult _toResult(List<ContentChunk> results) {
    if (results.isEmpty) return const SearchResult(context: '', topics: []);
    final topics = <String>[];
    for (final c in results) {
      if (!topics.contains(c.chapter)) topics.add(c.chapter);
    }
    final context = results
        .map((c) => '[Class ${c.classNumber} ${c.subject} — ${c.chapter}]\n${c.chunkText}')
        .join('\n\n');
    return SearchResult(context: context, topics: topics);
  }

  /// Returns the matching notes and the topics (chapters) they came from.
  /// Pass [subject] and/or [classNumber] to restrict the search.
  Future<SearchResult> findContext(String question,
      {String? subject, int? classNumber}) async {
    final words = _keywords(question);
    if (words.isEmpty) return const SearchResult(context: '', topics: []);

    final seen = <int>{};
    final results = <ContentChunk>[];

    for (final word in words) {
      if (results.length >= 5) break;
      final rows = await _db.keywordSearch(word,
          subject: subject, classNumber: classNumber, limit: 3);
      for (final row in rows) {
        if (!seen.contains(row.id)) {
          seen.add(row.id);
          results.add(row);
          if (results.length >= 5) break;
        }
      }
    }

    return _toResult(results);
  }

  /// Multi-scope search for competitive-exam mode (JEE/NEET): searches across
  /// several [subjects] and [classes] at once and merges the best matches.
  /// Retrieves a few more chunks (up to 6) since the syllabus is broader.
  Future<SearchResult> findContextMulti(String question,
      {required List<String> subjects, required List<int> classes}) async {
    final words = _keywords(question);
    if (words.isEmpty) return const SearchResult(context: '', topics: []);

    final seen = <int>{};
    final results = <ContentChunk>[];

    for (final word in words) {
      if (results.length >= 6) break;
      final rows = await _db.keywordSearchMulti(word,
          subjects: subjects, classNumbers: classes, limit: 4);
      for (final row in rows) {
        if (!seen.contains(row.id)) {
          seen.add(row.id);
          results.add(row);
          if (results.length >= 6) break;
        }
      }
    }

    return _toResult(results);
  }
}

final keywordSearchProvider = Provider<KeywordSearchService>((ref) {
  return KeywordSearchService(ref.watch(demoDatabaseProvider));
});
