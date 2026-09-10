import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/subject_provider.dart';
import '../../data/database/demo_database.dart';
import '../../domain/ai/flashcard_service.dart';
import '../../domain/ai/groq_client.dart';

/// Opens the Flashcards bottom sheet. Requires a subject + class (single mode).
void showFlashcardSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _FlashcardSheet(),
  );
}

class _FlashcardSheet extends ConsumerStatefulWidget {
  const _FlashcardSheet();
  @override
  ConsumerState<_FlashcardSheet> createState() => _FlashcardSheetState();
}

enum _Stage { pickTopic, generating, cards, error }

class _FlashcardSheetState extends ConsumerState<_FlashcardSheet> {
  _Stage _stage = _Stage.pickTopic;
  String? _errorMsg;
  List<Flashcard> _cards = const [];
  String _topicLabel = '';

  int _index = 0;
  bool _showBack = false;

  Future<void> _start(String subject, int classNumber, String? topic) async {
    setState(() {
      _stage = _Stage.generating;
      _topicLabel = (topic == null || topic.isEmpty) ? subject : topic;
    });
    try {
      final cards = await ref.read(flashcardServiceProvider).generateCards(
            subject: subject,
            classNumber: classNumber,
            topic: topic,
          );
      if (!mounted) return;
      setState(() {
        _cards = cards;
        _index = 0;
        _showBack = false;
        _stage = _Stage.cards;
      });
    } on GroqApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Clara could not build flashcards right now. ($e)';
        _stage = _Stage.error;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Something went wrong building flashcards. Please try again.';
        _stage = _Stage.error;
      });
    }
  }

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
      case _Stage.cards:
        return _buildCards(theme);
      case _Stage.error:
        return _buildError(theme);
    }
  }

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
              Icon(Icons.style_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Flashcards',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ctx.isExamMode
                ? 'Flashcards work on a single subject. Pick a class and subject first (exit exam mode), then tap "Flashcards".'
                : 'Pick a class and subject first, then tap "Flashcards".',
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

    final chaptersFuture = ref
        .watch(_fcChaptersProvider((subject: subject, classNumber: classNumber)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.style_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Flashcards — Class $classNumber $subject',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Choose a topic. Clara makes flashcards from your notes.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
                    _TopicTile(
                      label: 'Whole subject (mixed)',
                      icon: Icons.shuffle_rounded,
                      onTap: () => _start(subject, classNumber, null),
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
                              onTap: () => _start(subject, classNumber, ch),
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

  Widget _buildGenerating(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Making flashcards on "$_topicLabel"…',
              textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('Clara is pulling key points from your notes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Text('Flashcards unavailable',
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

  Widget _buildCards(ThemeData theme) {
    final card = _cards[_index];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.style_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Flashcards — $_topicLabel',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Text('${_index + 1} / ${_cards.length}',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 12),
        // The flip card.
        GestureDetector(
          onTap: () => setState(() => _showBack = !_showBack),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Container(
              key: ValueKey('${_index}_$_showBack'),
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 190),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _showBack
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_showBack ? 'ANSWER' : 'PROMPT',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(
                    _showBack ? card.back : card.front,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight:
                            _showBack ? FontWeight.normal : FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.touch_app_outlined,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(_showBack ? 'Tap to see prompt' : 'Tap to reveal answer',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _index > 0
                  ? () => setState(() {
                        _index--;
                        _showBack = false;
                      })
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Prev'),
            ),
            const Spacer(),
            _index < _cards.length - 1
                ? FilledButton.icon(
                    onPressed: () => setState(() {
                      _index++;
                      _showBack = false;
                    }),
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Next'),
                  )
                : FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _stage = _Stage.pickTopic;
              _cards = const [];
            }),
            child: const Text('New set'),
          ),
        ),
      ],
    );
  }
}

/// Chapters (topics) for a given subject + class, from the embedded notes.
final _fcChaptersProvider = FutureProvider.family
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
