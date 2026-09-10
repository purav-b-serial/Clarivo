import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/demo_database.dart';
import '../../core/providers/subject_provider.dart';
import 'groq_client.dart';
import 'keyword_search_service.dart';

class ClaraService {
  ClaraService({
    required DemoDatabase db,
    required GroqClient groqClient,
    required KeywordSearchService searchService,
    this.activeSubject,
    this.activeClass,
    this.exam,
    this.socratic = false,
  })  : _db = db,
        _groq = groqClient,
        _search = searchService;

  final DemoDatabase _db;
  final GroqClient _groq;
  final KeywordSearchService _search;
  final String? activeSubject;
  final int? activeClass;

  /// When set, Clara is in competitive-exam mode (JEE/NEET) and searches
  /// across multiple classes and subjects at once.
  final ExamPrep? exam;

  /// When true, Clara guides the student with hints and leading questions
  /// (Socratic method) instead of giving the full answer outright.
  final bool socratic;

  Future<String> ask(String question) async {
    final isExam = exam != null;

    final search = isExam
        ? await _search.findContextMulti(question,
            subjects: exam!.subjects, classes: exam!.classes)
        : await _search.findContext(question,
            subject: activeSubject, classNumber: activeClass);

    // Label used in the prompt and stored with history.
    final classLabel = isExam
        ? '${exam!.name} (Class ${exam!.classes.join(" & ")})'
        : (activeClass != null ? 'Class $activeClass' : 'the selected class');

    final hasNotes = !search.isEmpty;

    final contextSection = hasNotes
        ? '\n\n---\nREFERENCE NOTES (these ARE from the student\'s official study material — treat them as authoritative and answer FROM them):\n${search.context}\n---'
        : '\n\n[No matching study notes were found for this question.]';

    // The disclaimer is driven purely by whether notes were actually retrieved
    // from the database — not by subject or class. It appears ONLY when Clara
    // must fall back to its own general knowledge.
    final sourceRule = hasNotes
        ? '2. ANSWER FROM THE NOTES. Reference notes were found for this question '
            '(shown below). Base your answer on them and treat them as the correct, '
            'authoritative source. Do NOT add any disclaimer or verification warning '
            '— the content is from the student\'s own study material.\n'
        : '2. GENERAL KNOWLEDGE FALLBACK. No study notes were found for this '
            'question, so you must answer from your own general knowledge. In this '
            'case ONLY, you MUST begin your answer with exactly this line:\n'
            '"⚠️ General knowledge answer — please verify with your textbook."\n'
            'Then give the best accurate answer you can.\n';

    final intro = isExam
        ? 'You are Clara, a precise and helpful ${exam!.fullName} preparation '
            'assistant. You cover the full CBSE Class 11 and 12 syllabus for '
            '${exam!.subjects.join(", ")}, and answer ${exam!.name} exam-style '
            'questions across these subjects.'
        : 'You are Clara, a precise and helpful CBSE $classLabel study assistant'
            '${activeSubject != null ? " specialising in $activeSubject" : ""}.';

    // In Socratic mode, Clara coaches the student toward the answer with hints
    // and leading questions instead of stating the full answer directly.
    final socraticRule = socratic
        ? '\n\nSOCRATIC TUTOR MODE — IMPORTANT: Do NOT give the full answer '
            'outright. Instead, guide the student to discover it themselves:\n'
            '- Start with one short encouraging line.\n'
            '- Give 1-2 helpful HINTS or ask 1-2 leading questions that nudge '
            'their thinking, grounded in the reference notes.\n'
            '- Point out the key concept or formula to consider, but let them '
            'take the final step.\n'
            '- Keep it brief (under ~120 words). End by inviting them to try, '
            'e.g. "What do you think the next step is?"\n'
            '- Only if the student explicitly says they give up or asks '
            'directly for the answer should you reveal it fully.'
        : '';

    final systemPrompt =
        '$intro'
        '$socraticRule\n\n'

        'CRITICAL OUTPUT RULES — follow these exactly:\n'
        '1. OUTPUT ONLY THE FINAL ANSWER. Never show thinking, reasoning steps, '
        'draft attempts, self-corrections, or intermediate work. If you realise '
        'an example is wrong mid-response, silently correct it — do not tell the '
        'student you made an error or are correcting yourself.\n'
        '$sourceRule'
        '3. NO FABRICATION. Never invent grammar rules, example words, chemical '
        'formulas, dates, or facts. If unsure, say so in one sentence.\n'
        '4. FIT THE ANSWER IN ONE RESPONSE — this is critical. You have a hard '
        'limit of about 900 output tokens (~550 words). PLAN the answer to '
        'finish completely within this budget. Prefer crisp points over long '
        'prose. For big topics, cover the most important sub-points concisely '
        'and STOP with a proper concluding sentence — never begin a long list '
        'or derivation you cannot finish. It is far better to give a shorter, '
        'fully complete answer than a longer one that gets cut off. NEVER end '
        'mid-sentence or mid-word.\n\n'

        'FORMATTING RULES:\n'
        '- Use markdown: **bold** key terms, ## headings for sections, '
        '- numbered lists for steps, bullet points for items.\n'
        '- Mathematics: write ALL formulas and equations as LaTeX. '
        'Use \$\$formula\$\$ for standalone equations on their own line. '
        'Use \$formula\$ for inline math within a sentence. '
        'Example: "The quadratic formula is \$\$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$\$". '
        'IMPORTANT: do NOT write variables as plain text when they are part of math — '
        'use LaTeX. Write \$x = 3\$ not "x = 3".\n'
        '- Keep the response focused and exam-relevant for CBSE $classLabel.'
        '$contextSection';

    final answer = await _groq.complete(
      systemPrompt: systemPrompt,
      userMessage: question,
    );

    await _db.into(_db.chatHistoryItems).insert(
          ChatHistoryItemsCompanion.insert(
            question: question,
            answer: answer,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            // In exam mode, record the exam name as the "subject" for progress.
            subject: Value(isExam ? exam!.name : activeSubject),
            // Exam mode spans multiple classes, so leave class null there.
            classNumber: Value(isExam ? null : activeClass),
            topicsUsed: Value(search.topics.join(' | ')),
          ),
        );

    return answer;
  }
}

/// When true, Clara answers in Socratic (hint-based) mode. Toggled from the
/// Clara chat screen.
class SocraticModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final socraticModeProvider =
    NotifierProvider<SocraticModeNotifier, bool>(SocraticModeNotifier.new);

final claraServiceProvider = Provider<ClaraService>((ref) {
  final ctx = ref.watch(studyContextProvider);
  return ClaraService(
    db: ref.watch(demoDatabaseProvider),
    groqClient: ref.watch(groqClientProvider),
    searchService: ref.watch(keywordSearchProvider),
    activeSubject: ctx.selectedSubject,
    activeClass: ctx.selectedClass,
    exam: ctx.exam,
    socratic: ref.watch(socraticModeProvider),
  );
});
