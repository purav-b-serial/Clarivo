import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/demo_database.dart';
import 'groq_client.dart';

/// A single multiple-choice quiz question generated from the student's notes.
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;

  /// Exactly 4 answer options.
  final List<String> options;

  /// Index (0-3) of the correct option in [options].
  final int correctIndex;

  /// Short explanation of why the correct answer is right.
  final String explanation;

  bool get isValid =>
      question.trim().isNotEmpty &&
      options.length == 4 &&
      options.every((o) => o.trim().isNotEmpty) &&
      correctIndex >= 0 &&
      correctIndex < 4;
}

/// Generates grounded multiple-choice quizzes from Clarivo's embedded notes.
///
/// Reuses the same [GroqClient] (and therefore the same secure /api/clara
/// proxy in production) as Clara's chat. The quiz is built from the actual
/// note text for the chosen topic (chapter), so questions stay on-syllabus.
class QuizService {
  QuizService({required DemoDatabase db, required GroqClient groqClient})
      : _db = db,
        _groq = groqClient;

  final DemoDatabase _db;
  final GroqClient _groq;

  /// Default number of questions per quiz.
  static const int questionCount = 5;

  /// Minimum and maximum questions a student can request in one go.
  static const int minQuestions = 1;
  static const int maxQuestions = 10;

  /// Builds a quiz for [subject]/[classNumber]. If [topic] (a chapter name) is
  /// given, questions are drawn from that chapter's notes; otherwise a spread
  /// of the subject's notes is used.
  ///
  /// [count] is the number of questions requested (clamped to 1-10). Questions
  /// are de-duplicated so the same question never appears twice in one quiz.
  Future<List<QuizQuestion>> generateQuiz({
    required String subject,
    required int classNumber,
    String? topic,
    int count = questionCount,
  }) async {
    final n = count.clamp(minQuestions, maxQuestions);

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

    // Give the response enough room: ~170 tokens per question (question +
    // 4 options + short explanation), plus headroom, capped at the proxy's
    // hard limit (2000). A 10-question quiz needs well above the 950 default.
    final budget = (n * 170 + 300).clamp(950, 2000);

    final raw = await _groq.complete(
      systemPrompt: systemPrompt,
      userMessage:
          'Generate the $n-question multiple-choice quiz now as a JSON array only. '
          'Every question must be distinct — no repeats.',
      maxTokens: budget,
    );

    // Parse, then drop any duplicate questions so a quiz never repeats.
    return _dedupe(_parse(raw));
  }

  /// Removes questions with identical (case-insensitive, trimmed) text so the
  /// same question can't appear twice in one quiz.
  List<QuizQuestion> _dedupe(List<QuizQuestion> questions) {
    final seen = <String>{};
    final out = <QuizQuestion>[];
    for (final q in questions) {
      final key = q.question.trim().toLowerCase();
      if (seen.add(key)) out.add(q);
    }
    return out;
  }

  /// Gathers note text for the quiz. Prefers a specific chapter's chunks; if no
  /// topic is given (or the chapter has none), falls back to a sample of the
  /// subject's chapters so the quiz still has grounding.
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
      // Fallback: pull a few chapters' worth of notes for the subject/class.
      final chapters =
          await _db.getChaptersForSubject(subject, classNumber: classNumber);
      for (final ch in chapters.take(4)) {
        final chunks = await _db.getChunksForChapter(subject, ch);
        for (final c in chunks.take(2)) {
          buffer.add('[$ch]\n${c.chunkText}');
        }
      }
    }

    // Keep the prompt within a safe size for the token budget.
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
        ? 'STUDY NOTES (base every question strictly on these — they are the '
            'student\'s official material):\n---\n$notes\n---'
        : '[No specific notes were found — use accurate CBSE Class '
            '$classNumber $subject knowledge for "$topicLabel".]';

    return 'You are Clara, an expert CBSE Class $classNumber $subject examiner. '
        'Create a $count-question multiple-choice quiz on "$topicLabel".\n\n'
        'OUTPUT FORMAT — CRITICAL:\n'
        'Return ONLY a raw JSON array. No prose, no markdown, no code fences, '
        'no commentary before or after. The array MUST have exactly '
        '$count objects, each with this exact shape:\n'
        '{"question": string, "options": [string, string, string, string], '
        '"correctIndex": integer 0-3, "explanation": string}\n\n'
        'RULES:\n'
        '1. Exactly 4 options per question; exactly one correct.\n'
        '2. "correctIndex" is the 0-based index of the correct option.\n'
        '3. Base questions on the notes below when provided; do not invent facts.\n'
        '4. Keep questions clear and exam-appropriate for Class $classNumber.\n'
        '5. Keep each "explanation" to one or two sentences.\n'
        '6. Do NOT use LaTeX or markdown inside the strings — plain text only.\n'
        '7. Vary difficulty across the $count questions.\n'
        '8. EVERY question must be unique — do NOT repeat or lightly reword the '
        'same question. Cover $count different concepts/facts from the topic.\n\n'
        '$notesSection';
  }

  /// Defensively parses the model output into questions. Handles stray prose,
  /// code fences, and trailing text by extracting the first JSON array.
  List<QuizQuestion> _parse(String raw) {
    final jsonText = _extractJsonArray(raw);
    if (jsonText == null) {
      throw const FormatException('Could not find a JSON array in the response.');
    }

    late final dynamic decoded;
    try {
      decoded = jsonDecode(jsonText);
    } catch (_) {
      throw const FormatException('Quiz response was not valid JSON.');
    }

    if (decoded is! List) {
      throw const FormatException('Quiz response was not a JSON array.');
    }

    final questions = <QuizQuestion>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final q = (item['question'] ?? '').toString();
      final rawOptions = item['options'];
      final options = <String>[];
      if (rawOptions is List) {
        for (final o in rawOptions) {
          options.add(o.toString());
        }
      }
      final ci = _asInt(item['correctIndex']);
      final expl = (item['explanation'] ?? '').toString();

      final question = QuizQuestion(
        question: q,
        options: options,
        correctIndex: ci,
        explanation: expl,
      );
      if (question.isValid) questions.add(question);
    }

    if (questions.isEmpty) {
      throw const FormatException('No valid questions were generated.');
    }
    return questions;
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? -1;
  }

  /// Extracts the first balanced JSON array substring from [text].
  String? _extractJsonArray(String text) {
    // Strip common code-fence wrappers first.
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

final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService(
    db: ref.watch(demoDatabaseProvider),
    groqClient: ref.watch(groqClientProvider),
  );
});
