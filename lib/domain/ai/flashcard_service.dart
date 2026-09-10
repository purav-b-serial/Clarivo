import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/demo_database.dart';
import 'groq_client.dart';

/// A single study flashcard: a prompt on the front, the answer on the back.
class Flashcard {
  const Flashcard({required this.front, required this.back});

  final String front;
  final String back;

  bool get isValid => front.trim().isNotEmpty && back.trim().isNotEmpty;
}

/// Generates study flashcards from Clarivo's embedded notes.
///
/// Reuses the same [GroqClient] (and the secure /api/clara proxy in
/// production) as Clara's chat and quizzes. Cards are built from the actual
/// note text for the chosen topic, so they stay on-syllabus.
class FlashcardService {
  FlashcardService({required DemoDatabase db, required GroqClient groqClient})
      : _db = db,
        _groq = groqClient;

  final DemoDatabase _db;
  final GroqClient _groq;

  static const int defaultCount = 8;
  static const int minCards = 3;
  static const int maxCards = 12;

  /// Builds [count] flashcards for [subject]/[classNumber]. If [topic] (a
  /// chapter name) is given, cards come from that chapter's notes; otherwise a
  /// spread of the subject's notes is used. Cards are de-duplicated by front.
  Future<List<Flashcard>> generateCards({
    required String subject,
    required int classNumber,
    String? topic,
    int count = defaultCount,
  }) async {
    final n = count.clamp(minCards, maxCards);

    final notes = await _collectNotes(
      subject: subject,
      classNumber: classNumber,
      topic: topic,
    );
    final topicLabel = (topic == null || topic.isEmpty) ? subject : topic;

    final systemPrompt = _buildPrompt(
      subject: subject,
      classNumber: classNumber,
      topicLabel: topicLabel,
      notes: notes,
      count: n,
    );

    // ~90 tokens/card (short front + a couple-sentence back) + headroom.
    final budget = (n * 90 + 250).clamp(950, 2000);

    final raw = await _groq.complete(
      systemPrompt: systemPrompt,
      userMessage:
          'Generate the $n flashcards now as a JSON array only. Each card unique.',
      maxTokens: budget,
    );

    return _dedupe(_parse(raw));
  }

  Future<String> _collectNotes({
    required String subject,
    required int classNumber,
    String? topic,
  }) async {
    final buffer = <String>[];

    if (topic != null && topic.isNotEmpty) {
      final chunks = await _db.getChunksForChapter(subject, topic);
      for (final c in chunks) {
        buffer.add('[$topic]\n${c.chunkText}');
      }
    }

    if (buffer.isEmpty) {
      final chapters =
          await _db.getChaptersForSubject(subject, classNumber: classNumber);
      for (final ch in chapters.take(4)) {
        final chunks = await _db.getChunksForChapter(subject, ch);
        for (final c in chunks.take(2)) {
          buffer.add('[$ch]\n${c.chunkText}');
        }
      }
    }

    final joined = buffer.join('\n\n');
    const maxChars = 6000;
    return joined.length > maxChars ? joined.substring(0, maxChars) : joined;
  }

  String _buildPrompt({
    required String subject,
    required int classNumber,
    required String topicLabel,
    required String notes,
    required int count,
  }) {
    final hasNotes = notes.trim().isNotEmpty;
    final notesSection = hasNotes
        ? 'STUDY NOTES (base every card strictly on these — they are the '
            'student\'s official material):\n---\n$notes\n---'
        : '[No specific notes were found — use accurate CBSE Class '
            '$classNumber $subject knowledge for "$topicLabel".]';

    return 'You are Clara, an expert CBSE Class $classNumber $subject tutor. '
        'Create $count study flashcards on "$topicLabel".\n\n'
        'OUTPUT FORMAT — CRITICAL:\n'
        'Return ONLY a raw JSON array. No prose, no markdown, no code fences, '
        'no commentary before or after. The array MUST have exactly $count '
        'objects, each with this exact shape:\n'
        '{"front": string, "back": string}\n\n'
        'RULES:\n'
        '1. "front" is a short prompt: a term, concept, or question (a few words '
        'to one line).\n'
        '2. "back" is a concise answer/definition (one to three sentences).\n'
        '3. Base cards on the notes below when provided; do not invent facts.\n'
        '4. Keep them exam-appropriate for Class $classNumber.\n'
        '5. Do NOT use LaTeX or markdown inside the strings — plain text only.\n'
        '6. EVERY card must be unique — cover $count different points; no repeats.\n\n'
        '$notesSection';
  }

  List<Flashcard> _dedupe(List<Flashcard> cards) {
    final seen = <String>{};
    final out = <Flashcard>[];
    for (final c in cards) {
      final key = c.front.trim().toLowerCase();
      if (seen.add(key)) out.add(c);
    }
    return out;
  }

  List<Flashcard> _parse(String raw) {
    final jsonText = _extractJsonArray(raw);
    if (jsonText == null) {
      throw const FormatException('Could not find a JSON array in the response.');
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw const FormatException('Flashcard response was not valid JSON.');
    }

    if (decoded is! List) {
      throw const FormatException('Flashcard response was not a JSON array.');
    }

    final cards = <Flashcard>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final front = (item['front'] ?? '').toString();
      final back = (item['back'] ?? '').toString();
      final card = Flashcard(front: front, back: back);
      if (card.isValid) cards.add(card);
    }

    if (cards.isEmpty) {
      throw const FormatException('No valid flashcards were generated.');
    }
    return cards;
  }

  /// Extracts the first balanced JSON array substring from [text].
  String? _extractJsonArray(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t.replaceAll(RegExp(r'```[a-zA-Z]*'), '').replaceAll('```', '').trim();
    }
    final start = t.indexOf('[');
    if (start < 0) return null;

    int depth = 0;
    bool inString = false;
    bool escape = false;
    for (int i = start; i < t.length; i++) {
      final ch = t[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (ch == r'\') {
          escape = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue;
      }
      if (ch == '"') {
        inString = true;
      } else if (ch == '[') {
        depth++;
      } else if (ch == ']') {
        depth--;
        if (depth == 0) {
          return t.substring(start, i + 1);
        }
      }
    }
    return null;
  }
}

final flashcardServiceProvider = Provider<FlashcardService>((ref) {
  return FlashcardService(
    db: ref.watch(demoDatabaseProvider),
    groqClient: ref.watch(groqClientProvider),
  );
});
