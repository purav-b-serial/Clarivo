import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/subject_provider.dart';
import '../../data/database/demo_database.dart';
import '../../domain/ai/groq_client.dart';
import '../../domain/ai/quiz_service.dart';

/// Opens the Quiz mode bottom sheet. Requires a subject + class to be selected
/// (single mode). In exam mode there is no single subject, so the caller
/// should guide the student to pick a subject first.
void showQuizSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _QuizSheet(),
  );
}

class _QuizSheet extends ConsumerStatefulWidget {
  const _QuizSheet();
  @override
  ConsumerState<_QuizSheet> createState() => _QuizSheetState();
}

enum _Stage { pickTopic, generating, quiz, error }

class _QuizSheetState extends ConsumerState<_QuizSheet> {
  _Stage _stage = _Stage.pickTopic;
  String? _errorMsg;
  List<QuizQuestion> _questions = const [];
  String _topicLabel = '';

  // Per-question selected answer index (null = unanswered).
  final Map<int, int> _selected = {};

  Future<void> _startQuiz(String subject, int classNumber, String? topic) async {
    setState(() {
      _stage = _Stage.generating;
      _topicLabel = (topic == null || topic.isEmpty) ? subject : topic;
    });
    try {
      final questions = await ref.read(quizServiceProvider).generateQuiz(
            subject: subject,
            classNumber: classNumber,
            topic: topic,
          );
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _selected.clear();
        _stage = _Stage.quiz;
      });
    } on GroqApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Clara could not build the quiz right now. ($e)';
        _stage = _Stage.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg =
            'Something went wrong building the quiz. Please try again.';
        _stage = _Stage.error;
      });
    }
  }

  int get _score {
    var s = 0;
    for (var i = 0; i < _questions.length; i++) {
      if (_selected[i] == _questions[i].correctIndex) s++;
    }
    return s;
  }

  int get _answeredCount => _selected.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctx = ref.watch(studyContextProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(child: _buildStage(theme, ctx)),
        ],
      ),
    );
  }

  Widget _buildStage(ThemeData theme, StudyContext ctx) {
    switch (_stage) {
      case _Stage.pickTopic:
        return _buildTopicPicker(theme, ctx);
      case _Stage.generating:
        return _buildGenerating(theme);
      case _Stage.quiz:
        return _buildQuiz(theme);
      case _Stage.error:
        return _buildError(theme);
    }
  }

  // ── Topic picker ────────────────────────────────────────────────────────
  Widget _buildTopicPicker(ThemeData theme, StudyContext ctx) {
    final subject = ctx.selectedSubject;
    final classNumber = ctx.selectedClass;

    if (subject == null || classNumber == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Quiz Me',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ctx.isExamMode
                ? 'Quiz mode works on a single subject. Pick a class and subject first (exit exam mode), then tap "Quiz me".'
                : 'Pick a class and subject first, then tap "Quiz me" to test yourself.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ),
        ],
      );
    }

    final chaptersFuture =
        ref.watch(_chaptersProvider((subject: subject, classNumber: classNumber)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.quiz_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Quiz Me — Class $classNumber $subject',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Choose a topic. Clara will make ${QuizService.questionCount} '
          'questions from your notes.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        chaptersFuture.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) =>
              Text('Could not load topics: $e', style: theme.textTheme.bodySmall),
          data: (chapters) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // "Whole subject" option first.
                    _TopicTile(
                      label: 'Whole subject (mixed)',
                      icon: Icons.shuffle_rounded,
                      onTap: () => _startQuiz(subject, classNumber, null),
                    ),
                    const SizedBox(height: 8),
                    if (chapters.isEmpty)
                      Text('No topics found for this subject.',
                          style: theme.textTheme.bodySmall)
                    else
                      ...chapters.map((ch) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _TopicTile(
                              label: ch,
                              icon: Icons.menu_book_outlined,
                              onTap: () => _startQuiz(subject, classNumber, ch),
                            ),
                          )),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Generating ──────────────────────────────────────────────────────────
  Widget _buildGenerating(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Building your quiz on "$_topicLabel"…',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('Clara is writing questions from your notes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────
  Widget _buildError(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Text('Quiz unavailable',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Text(_errorMsg ?? 'Please try again.',
            style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => setState(() => _stage = _Stage.pickTopic),
            child: const Text('Back'),
          ),
        ),
      ],
    );
  }

  // ── Quiz runner ─────────────────────────────────────────────────────────
  Widget _buildQuiz(ThemeData theme) {
    final allAnswered = _answeredCount == _questions.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.quiz_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Quiz — $_topicLabel',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            if (allAnswered)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Score: $_score / ${_questions.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < _questions.length; i++)
                  _QuestionCard(
                    index: i,
                    question: _questions[i],
                    selected: _selected[i],
                    onSelect: (opt) => setState(() => _selected[i] = opt),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() {
                _stage = _Stage.pickTopic;
                _questions = const [];
                _selected.clear();
              }),
              child: const Text('New quiz'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Chapters (topics) for a given subject + class, from the embedded notes.
final _chaptersProvider = FutureProvider.family
    .autoDispose<List<String>, ({String subject, int classNumber})>(
        (ref, args) async {
  final db = ref.watch(demoDatabaseProvider);
  return db.getChaptersForSubject(args.subject, classNumber: args.classNumber);
});

class _TopicTile extends StatelessWidget {
  const _TopicTile(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  final int index;
  final QuizQuestion question;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = selected != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q${index + 1}. ${question.question}',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          for (var o = 0; o < question.options.length; o++)
            _OptionTile(
              text: question.options[o],
              state: _optionState(o),
              onTap: answered ? null : () => onSelect(o),
            ),
          if (answered) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (selected == question.correctIndex
                        ? Colors.green
                        : theme.colorScheme.error)
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    selected == question.correctIndex
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 16,
                    color: selected == question.correctIndex
                        ? Colors.green
                        : theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected == question.correctIndex
                          ? 'Correct! ${question.explanation}'
                          : 'Not quite. ${question.explanation}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  _OptState _optionState(int optionIndex) {
    if (selected == null) return _OptState.idle;
    if (optionIndex == question.correctIndex) return _OptState.correct;
    if (optionIndex == selected) return _OptState.wrong;
    return _OptState.dimmed;
  }
}

enum _OptState { idle, correct, wrong, dimmed }

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.text, required this.state, required this.onTap});
  final String text;
  final _OptState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color border = theme.colorScheme.outlineVariant;
    Color? bg;
    IconData? trailing;
    Color? trailingColor;

    switch (state) {
      case _OptState.idle:
        break;
      case _OptState.correct:
        border = Colors.green;
        bg = Colors.green.withOpacity(0.08);
        trailing = Icons.check_circle_rounded;
        trailingColor = Colors.green;
        break;
      case _OptState.wrong:
        border = theme.colorScheme.error;
        bg = theme.colorScheme.error.withOpacity(0.08);
        trailing = Icons.cancel_rounded;
        trailingColor = theme.colorScheme.error;
        break;
      case _OptState.dimmed:
        break;
    }

    return Opacity(
      opacity: state == _OptState.dimmed ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Expanded(
                    child: Text(text, style: theme.textTheme.bodyMedium)),
                if (trailing != null)
                  Icon(trailing, size: 18, color: trailingColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
