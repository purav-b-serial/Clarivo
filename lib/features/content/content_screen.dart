import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/subject_provider.dart';
import '../../data/database/demo_database.dart';

// =============================================================================
// Root: routes between Class Picker / Subject Picker / Chapter List
// =============================================================================

class ContentScreen extends ConsumerWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = ref.watch(studyContextProvider);

    if (!ctx.hasClass) return const _ClassPickerScreen();
    if (!ctx.hasSubject) return _SubjectPickerScreen(selectedClass: ctx.selectedClass!);

    final subjectInfo = kCbseSubjects.firstWhere(
      (s) => s.name == ctx.selectedSubject,
      orElse: () => kCbseSubjects.first,
    );

    return _ChapterListScreen(
      selectedClass: ctx.selectedClass!,
      subject: subjectInfo,
    );
  }
}

// =============================================================================
// Step 1 — Class Picker
// Shows only classes that actually have content in the database
// =============================================================================

class _ClassPickerScreen extends ConsumerWidget {
  const _ClassPickerScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final availableAsync = ref.watch(availableClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Library'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select your class. Clara will focus her answers and notes on that class.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Available Classes',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Dynamic class grid
            Expanded(
              child: availableAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text('Error loading classes: $e',
                      style: theme.textTheme.bodySmall),
                ),
                data: (classes) {
                  if (classes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty_rounded,
                              size: 48,
                              color: theme.colorScheme.primary.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text('Loading content…',
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Clear your browser IndexedDB if this persists.',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemCount: classes.length,
                    itemBuilder: (context, i) {
                      final cls = classes[i];
                      return _ClassCard(
                        cls: cls,
                        onTap: () => ref
                            .read(studyContextProvider.notifier)
                            .selectClass(cls.number),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.cls, required this.onTap});
  final CbseClass cls;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${cls.number}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Class',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Step 2 — Subject Picker
// =============================================================================

class _SubjectPickerScreen extends ConsumerWidget {
  const _SubjectPickerScreen({required this.selectedClass});
  final int selectedClass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Class $selectedClass'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Change class',
          onPressed: () =>
              ref.read(studyContextProvider.notifier).clearAll(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Context banner
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Select a subject. Clara will focus on Class $selectedClass notes for that subject.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Subjects',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemCount: kCbseSubjects.length,
                itemBuilder: (context, i) {
                  final subject = kCbseSubjects[i];
                  return _SubjectCard(
                    subject: subject,
                    onTap: () => ref
                        .read(studyContextProvider.notifier)
                        .selectSubject(subject.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});
  final CbseSubject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = subject.color;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(subject.icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              subject.name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subject.description,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Step 3 — Chapter List
// =============================================================================

class _ChapterListScreen extends ConsumerStatefulWidget {
  const _ChapterListScreen({
    required this.selectedClass,
    required this.subject,
  });
  final int selectedClass;
  final CbseSubject subject;

  @override
  ConsumerState<_ChapterListScreen> createState() =>
      _ChapterListScreenState();
}

class _ChapterListScreenState extends ConsumerState<_ChapterListScreen> {
  List<String> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(demoDatabaseProvider);
    final chapters = await db.getChaptersForSubject(widget.subject.name);
    if (mounted) setState(() { _chapters = chapters; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.subject.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Change subject',
          onPressed: () =>
              ref.read(studyContextProvider.notifier).clearSubject(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Class ${widget.selectedClass}  ·  ${_chapters.length} chapters',
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                ref.read(studyContextProvider.notifier).clearAll(),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Change Class',
                style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chapters.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.subject.icon,
                            size: 56,
                            color: color.withOpacity(0.25)),
                        const SizedBox(height: 16),
                        Text('No chapters found',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Notes for ${widget.subject.name} Class ${widget.selectedClass} are not available yet. '
                          'If you just installed, try clearing IndexedDB in Chrome DevTools and refreshing.',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _chapters.length,
                  itemBuilder: (context, i) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: color.withOpacity(0.12),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        _chapters[i],
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _ChapterDetailScreen(
                            subject: widget.subject,
                            chapter: _chapters[i],
                            selectedClass: widget.selectedClass,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

// =============================================================================
// Step 4 — Chapter Detail (Notes Viewer)
// =============================================================================

class _ChapterDetailScreen extends ConsumerStatefulWidget {
  const _ChapterDetailScreen({
    required this.subject,
    required this.chapter,
    required this.selectedClass,
  });
  final CbseSubject subject;
  final String chapter;
  final int selectedClass;

  @override
  ConsumerState<_ChapterDetailScreen> createState() =>
      _ChapterDetailScreenState();
}

class _ChapterDetailScreenState
    extends ConsumerState<_ChapterDetailScreen> {
  List<ContentChunk> _chunks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(demoDatabaseProvider);
    final chunks =
        await db.getChunksForChapter(widget.subject.name, widget.chapter);
    if (mounted) setState(() { _chunks = chunks; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.subject.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chapter,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${widget.subject.name}  ·  Class ${widget.selectedClass}  ·  ${_chunks.length} notes',
              style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chunks.isEmpty
              ? const Center(child: Text('No notes available for this chapter.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  itemCount: _chunks.length,
                  itemBuilder: (context, i) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: color.withOpacity(0.2), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Note header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 14, color: color),
                              const SizedBox(width: 6),
                              Text(
                                'Note ${i + 1} of ${_chunks.length}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Note content
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: SelectableText(
                            _chunks[i].chunkText,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
