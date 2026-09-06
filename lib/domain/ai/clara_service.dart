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
  })  : _db = db,
        _groq = groqClient,
        _search = searchService;

  final DemoDatabase _db;
  final GroqClient _groq;
  final KeywordSearchService _search;
  final String? activeSubject;
  final int? activeClass;

  Future<String> ask(String question) async {
    final context =
        await _search.findContext(question, subject: activeSubject);

    final classLabel =
        activeClass != null ? 'Class $activeClass' : 'Class 10';

    final contextSection = context.isEmpty
        ? '\n\n[No matching study notes found for this topic.]'
        : '\n\n---\nREFERENCE NOTES:\n$context\n---';

    final systemPrompt =
        'You are Clara, a precise and helpful CBSE $classLabel study assistant'
        '${activeSubject != null ? " specialising in $activeSubject" : ""}.\n\n'

        'CRITICAL OUTPUT RULES — follow these exactly:\n'
        '1. OUTPUT ONLY THE FINAL ANSWER. Never show thinking, reasoning steps, '
        'draft attempts, self-corrections, or intermediate work. If you realise '
        'an example is wrong mid-response, silently correct it — do not tell the '
        'student you made an error or are correcting yourself.\n'
        '2. VERIFIED CONTENT ONLY. For Hindi, Sanskrit, and English grammar: if '
        'the exact rule or example is not in the reference notes, you MUST start '
        'with: "⚠️ General knowledge answer — please verify with your textbook."\n'
        '3. NO FABRICATION. Never invent grammar rules, example words, chemical '
        'formulas, dates, or facts. If unsure, say so in one sentence.\n'
        '4. COMPLETE ANSWERS. Never cut off mid-sentence. Give the full answer.\n\n'

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
            subject: Value(activeSubject),
          ),
        );

    return answer;
  }
}

final claraServiceProvider = Provider<ClaraService>((ref) {
  final ctx = ref.watch(studyContextProvider);
  return ClaraService(
    db: ref.watch(demoDatabaseProvider),
    groqClient: ref.watch(groqClientProvider),
    searchService: ref.watch(keywordSearchProvider),
    activeSubject: ctx.selectedSubject,
    activeClass: ctx.selectedClass,
  );
});
