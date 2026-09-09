import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

import '../../core/providers/subject_provider.dart';
import '../../domain/ai/clara_service.dart';
import '../../domain/ai/groq_client.dart';

class _Message {
  const _Message({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

// ─────────────────────────────────────────────────────────────────────────────
// Subject picker bottom sheet — shown when user taps "Choose Subject"
// ─────────────────────────────────────────────────────────────────────────────

/// Class → Subject picker. Student first picks a class (only classes that
/// actually have notes are shown), then a subject within that class.
/// Subjects without notes are shown as "Coming soon" and are not selectable.
void _showSubjectPicker(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _ClassSubjectPickerSheet(),
  );
}

class _ClassSubjectPickerSheet extends ConsumerStatefulWidget {
  const _ClassSubjectPickerSheet();
  @override
  ConsumerState<_ClassSubjectPickerSheet> createState() =>
      _ClassSubjectPickerSheetState();
}

class _ClassSubjectPickerSheetState
    extends ConsumerState<_ClassSubjectPickerSheet> {
  int? _pickedClass;

  @override
  void initState() {
    super.initState();
    // Start on the subject step if a class is already chosen.
    _pickedClass = ref.read(studyContextProvider).selectedClass;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
          _pickedClass == null
              ? _buildClassStep(theme)
              : _buildSubjectStep(theme, _pickedClass!),
        ],
      ),
    );
  }

  // ── Step 1: choose class ──────────────────────────────────────────────
  Widget _buildClassStep(ThemeData theme) {
    final classesAsync = ref.watch(availableClassesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Choose Your Class',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          'Clara will focus her answers and notes on this class.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        classesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error loading classes: $e',
              style: theme.textTheme.bodySmall),
          data: (classes) {
            if (classes.isEmpty) {
              return Text('No classes available yet.',
                  style: theme.textTheme.bodySmall);
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: classes.map((cls) {
                return InkWell(
                  onTap: () {
                    ref
                        .read(studyContextProvider.notifier)
                        .selectClass(cls.number);
                    setState(() => _pickedClass = cls.number);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                              theme.colorScheme.primary.withOpacity(0.3),
                          width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${cls.number}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary)),
                        Text('Class',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        // ── Competitive exam prep (JEE / NEET) ──────────────────────────
        const SizedBox(height: 22),
        Row(
          children: [
            Icon(Icons.workspace_premium_outlined,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('Competitive Exam Prep',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Clara auto-covers Class 11 & 12 across all exam subjects — no class or subject to pick.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Column(
          children: kExamPreps.map((exam) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () {
                  ref.read(studyContextProvider.notifier).selectExam(exam.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Clara is now in ${exam.fullName} mode — Class 11 & 12, ${exam.subjects.join(", ")}'),
                      duration: const Duration(seconds: 3),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: exam.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: exam.color.withOpacity(0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: exam.color.withOpacity(0.15),
                        child: Icon(exam.icon, color: exam.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exam.fullName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: exam.color)),
                            const SizedBox(height: 2),
                            Text(exam.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: exam.color),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Step 2: choose subject within the class ───────────────────────────
  Widget _buildSubjectStep(ThemeData theme, int classNumber) {
    final subjectsAsync = ref.watch(availableSubjectsProvider(classNumber));
    final current = ref.read(activeSubjectProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => setState(() => _pickedClass = null),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.arrow_back, size: 20),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Class $classNumber — Choose Subject',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Clara will focus on Class $classNumber notes for the subject you pick.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        subjectsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error loading subjects: $e',
              style: theme.textTheme.bodySmall),
          data: (subjects) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
            ),
            itemCount: subjects.length,
            itemBuilder: (_, i) {
              final entry = subjects[i];
              final subject = entry.subject;
              final isSelected = current == subject.name;
              final enabled = entry.hasContent;

              return Opacity(
                opacity: enabled ? 1.0 : 0.45,
                child: InkWell(
                  onTap: enabled
                      ? () {
                          ref
                              .read(studyContextProvider.notifier)
                              .selectSubject(subject.name);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Clara is now focused on Class $classNumber ${subject.name}'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? subject.color.withOpacity(0.15)
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? subject.color
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(subject.icon,
                            size: 18,
                            color: isSelected
                                ? subject.color
                                : theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? subject.color
                                      : theme.colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (!enabled)
                                Text('Coming soon',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: subject.color),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clara screen
// ─────────────────────────────────────────────────────────────────────────────

class ClaraScreen extends ConsumerStatefulWidget {
  const ClaraScreen({super.key});

  @override
  ConsumerState<ClaraScreen> createState() => _ClaraScreenState();
}

class _ClaraScreenState extends ConsumerState<ClaraScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;
    _controller.clear();
    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();
    try {
      final answer = await ref.read(claraServiceProvider).ask(text);
      setState(() => _messages.add(_Message(text: answer, isUser: false)));
    } on GroqApiException catch (e) {
      setState(() => _messages.add(_Message(
            text: 'Sorry, Clara is unavailable right now. ($e)',
            isUser: false,
          )));
    } catch (e) {
      setState(() => _messages.add(_Message(
            text:
                'Something went wrong. Please check your internet connection and try again.',
            isUser: false,
          )));
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studyCtx = ref.watch(studyContextProvider);
    final exam = studyCtx.exam;
    final activeSubject = ref.watch(activeSubjectProvider);
    final subjectInfo = ref.watch(activeSubjectInfoProvider);

    // A context is "active" (Clara ready) when either a subject is chosen OR
    // an exam-prep mode is on. The label/colour adapt to whichever is active.
    final bool hasContext = exam != null || activeSubject != null;
    final String? activeLabel = exam?.fullName ?? activeSubject;
    final Color accentColor =
        exam?.color ?? subjectInfo?.color ?? theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        // ── Title: Clara + active subject/exam label ─────────────────────
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: hasContext
                  ? accentColor.withOpacity(0.2)
                  : theme.colorScheme.primaryContainer,
              child: Icon(Icons.smart_toy_rounded,
                  size: 18, color: accentColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Clara', style: TextStyle(fontSize: 16)),
                if (activeLabel != null)
                  Text(
                    activeLabel,
                    style: TextStyle(
                        fontSize: 11,
                        color: accentColor,
                        fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ],
        ),

        // ── AppBar actions ────────────────────────────────────────────────
        actions: [
          // ALWAYS-VISIBLE "Choose Subject / Change" button
          TextButton.icon(
            onPressed: () => _showSubjectPicker(context, ref),
            icon: Icon(
              hasContext ? Icons.swap_horiz_rounded : Icons.school_outlined,
              size: 16,
              color: accentColor,
            ),
            label: Text(
              hasContext ? 'Change' : 'Subject',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ),

          // Clear conversation
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Clear conversation',
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),

      body: Column(
        children: [
          // ── Active context banner (exam mode OR subject) ────────────────
          if (hasContext)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: accentColor.withOpacity(0.09),
              child: Row(
                children: [
                  Icon(exam?.icon ?? subjectInfo?.icon ?? Icons.school_outlined,
                      size: 13, color: accentColor),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      exam != null
                          ? '${exam.fullName} mode — Class 11 & 12: ${exam.subjects.join(", ")}'
                          : 'Focused on $activeSubject — Clara will prioritise this subject',
                      style: TextStyle(
                          fontSize: 11,
                          color: accentColor,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  // Inline clear button in banner
                  GestureDetector(
                    onTap: () {
                      ref.read(studyContextProvider.notifier).clearAll();
                    },
                    child: Icon(Icons.close_rounded,
                        size: 14, color: accentColor),
                  ),
                ],
              ),
            )
          else
            // ── No subject banner: show a subtle "pick subject" hint ────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              color: theme.colorScheme.surfaceContainerLow,
              child: InkWell(
                onTap: () => _showSubjectPicker(context, ref),
                child: Row(
                  children: [
                    Icon(Icons.school_outlined,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 7),
                    Text(
                      'No subject selected — tap to choose a subject for Clara',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),

          // ── Messages ─────────────────────────────────────────────────────
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(
                    activeSubject: activeLabel,
                    onChooseSubject: () =>
                        _showSubjectPicker(context, ref),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) =>
                        _MessageBubble(message: _messages[i]),
                  ),
          ),

          // ── Thinking indicator ───────────────────────────────────────────
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.smart_toy_rounded,
                        size: 16, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(width: 8),
                  Text('Clara is thinking…',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),

          // ── Input bar ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: exam != null
                            ? 'Ask Clara any ${exam.name} question…'
                            : (activeSubject != null
                                ? 'Ask Clara about $activeSubject…'
                                : 'Ask Clara a question…'),
                        filled: true,
                        fillColor:
                            theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5),
                          ),
                        )
                      : FilledButton(
                          onPressed: _send,
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(14),
                            backgroundColor: accentColor,
                          ),
                          child: const Icon(Icons.send_rounded, size: 20),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

/// Pre-processes Clara's response so it renders cleanly.
///
/// Strategy:
///  - Block math $$...$$ is extracted and rendered as a standalone Math widget
///    BETWEEN markdown sections — this avoids sentence fragmentation.
///  - Inline math $...$ is left as-is inside the markdown string and rendered
///    by MarkdownBody naturally (no fragmentation).
///  - Single-character $ wraps like $p$, $q$, $a$ that appear as prose variables
///    are kept in the markdown stream rather than being split out.
List<_Block> _buildBlocks(String text) {
  final blocks = <_Block>[];
  // Only split on BLOCK math: $$...$$ (multi-char content, own line)
  final blockMath = RegExp(r'\$\$(.+?)\$\$', dotAll: true);
  int last = 0;
  for (final match in blockMath.allMatches(text)) {
    if (match.start > last) {
      final md = text.substring(last, match.start);
      if (md.trim().isNotEmpty) blocks.add(_Block(md, false));
    }
    blocks.add(_Block(match.group(1)!.trim(), true));
    last = match.end;
  }
  if (last < text.length) {
    final md = text.substring(last);
    if (md.trim().isNotEmpty) blocks.add(_Block(md, false));
  }
  return blocks;
}

class _Block {
  const _Block(this.content, this.isBlockMath);
  final String content;
  final bool isBlockMath;
}



class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isUser ? 48 : 8,
            right: isUser ? 8 : 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: isUser
            ? SelectableText(
                message.text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onPrimary),
              )
            : _ClaraMessageContent(text: message.text),
      ),
    );
  }
}

/// Renders Clara responses cleanly:
/// - Block $$...$$ math renders as standalone Math widget (no sentence break)
/// - Inline $...$ math stays inside markdown text — MarkdownBody renders it
///   natively, keeping sentences intact and readable
class _ClaraMessageContent extends StatelessWidget {
  const _ClaraMessageContent({required this.text});
  final String text;

  MarkdownStyleSheet _sheet(BuildContext context, Color textColor) {
    final theme = Theme.of(context);
    return MarkdownStyleSheet(
      p: theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.6),
      strong: theme.textTheme.bodyMedium
          ?.copyWith(color: textColor, fontWeight: FontWeight.bold, height: 1.6),
      em: theme.textTheme.bodyMedium
          ?.copyWith(color: textColor, fontStyle: FontStyle.italic, height: 1.6),
      h1: theme.textTheme.titleMedium
          ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      h2: theme.textTheme.titleSmall
          ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      h3: theme.textTheme.bodyLarge
          ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      h4: theme.textTheme.bodyMedium
          ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      code: TextStyle(
        fontFamily: 'monospace',
        fontSize: 13,
        color: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.22),
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          left: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.5), width: 3),
        ),
      ),
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
        height: 1.55,
      ),
      listBullet:
          theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.6),
      tableBody:
          theme.textTheme.bodySmall?.copyWith(color: textColor),
      tableHead: theme.textTheme.bodySmall
          ?.copyWith(color: textColor, fontWeight: FontWeight.bold),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: theme.colorScheme.outlineVariant, width: 1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;
    final blocks = _buildBlocks(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks.map((block) {
        if (block.isBlockMath) {
          // Standalone block equation — centred, with spacing
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Math.tex(
                block.content,
                textStyle: theme.textTheme.bodyLarge
                        ?.copyWith(color: textColor) ??
                    TextStyle(color: textColor),
                onErrorFallback: (_) => SelectableText(
                  r'$$' + block.content + r'$$',
                  style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: theme.colorScheme.error),
                ),
              ),
            ),
          );
        }
        // Markdown text block. Inline $...$ math is rendered via a custom
        // inline syntax + element builder so bullets/bold/headings still work
        // AND formulas render as real math instead of raw LaTeX.
        return MarkdownBody(
          data: block.content,
          // selectable must be false: mixing custom WidgetSpan math builders
          // with SelectableText.rich (selectable:true) breaks inline rendering.
          selectable: false,
          styleSheet: _sheet(context, textColor),
          inlineSyntaxes: [InlineMathSyntax()],
          builders: {
            'inlineMath': InlineMathBuilder(textColor: textColor),
          },
        );
      }).toList(),
    );
  }
}

// ── Inline math support for flutter_markdown ────────────────────────────────
// Parses $...$ within markdown text and emits a custom 'inlineMath' element,
// which InlineMathBuilder renders using Math.tex. Preserves all other markdown.

class InlineMathSyntax extends md.InlineSyntax {
  // Match $...$ where the content has no $ or newline and isn't a bare number
  // (so real currency like "$5" is not treated as math).
  InlineMathSyntax() : super(r'\$([^\$\n]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)!;
    final looksMath =
        RegExp(r'[\\^_{}=+\-*/()]|[A-Za-z]').hasMatch(content) &&
            !RegExp(r'^\s*\d[\d,.\s]*$').hasMatch(content);
    if (!looksMath) {
      // Treat as plain text (e.g. "$5") — emit the original literal.
      parser.addNode(md.Text(match.group(0)!));
      return true;
    }
    final el = md.Element.text('inlineMath', content.trim());
    parser.addNode(el);
    return true;
  }
}

class InlineMathBuilder extends MarkdownElementBuilder {
  InlineMathBuilder({required this.textColor});
  final Color textColor;

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final tex = element.textContent;
    return Math.tex(
      tex,
      mathStyle: MathStyle.text,
      textStyle: (preferredStyle ?? const TextStyle()).copyWith(color: textColor),
      onErrorFallback: (_) => Text(
        '\$$tex\$',
        style: TextStyle(
            fontFamily: 'monospace', fontSize: 13, color: textColor),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.activeSubject, required this.onChooseSubject});
  final String? activeSubject;
  final VoidCallback onChooseSubject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = activeSubject != null
        ? _suggestionsFor(activeSubject!)
        : _defaultSuggestions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/clara_mascot.png',
            width: 96,
            height: 96,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.smart_toy_rounded,
              size: 76,
              color: theme.colorScheme.primary.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Hi! I\'m Clara 👋',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            activeSubject != null
                ? 'Ask me anything about $activeSubject. I\'ll answer using your notes.'
                : 'Select a subject so I can focus my answers on your study material.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // ── PROMINENT "Choose Subject" button ─────────────────────────
          if (activeSubject == null)
            FilledButton.icon(
              onPressed: onChooseSubject,
              icon: const Icon(Icons.school_outlined, size: 18),
              label: const Text('Choose a Subject'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onChooseSubject,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text('Change Subject (currently: $activeSubject)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

          const SizedBox(height: 20),

          // ── Suggestion chips ─────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: suggestions.map((s) => _SuggestionChip(s)).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const _defaultSuggestions = [
    'What is a combination reaction?',
    'Explain Ohm\'s law',
    'What is the reactivity series?',
    'How does photosynthesis work?',
  ];

  static List<String> _suggestionsFor(String subject) {
    switch (subject) {
      case 'Mathematics':
        return [
          'What is the quadratic formula?',
          'Explain Pythagoras theorem',
          'What are arithmetic progressions?',
          'How to find HCF using Euclid algorithm?',
        ];
      case 'Social Science':
        return [
          'What caused the Non-Cooperation Movement?',
          'Explain federalism in India',
          'What is the water cycle?',
          'What is globalisation?',
        ];
      case 'English':
        return [
          'Summarise A Letter to God',
          'What is the theme of Fire and Ice?',
          'Explain Footprints Without Feet',
          'What are the rules for reported speech?',
        ];
      case 'Hindi':
        return [
          'सूरदास के पद का भाव',
          'बालगोबिन भगत का चरित्र',
          'नेताजी का चश्मा का सारांश',
          'वाच्य के प्रकार',
        ];
      case 'Sanskrit':
        return [
          'शुचिपर्यावरणम् का सारांश',
          'संधि के प्रकार',
          'बुद्धिर्बलवती का सारांश',
          'लट् लकार के रूप',
        ];
      default:
        return [
          'What is a combination reaction?',
          'Explain the pH scale',
          'What is the reactivity series?',
          'How does photosynthesis work?',
        ];
    }
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        final state =
            context.findAncestorStateOfType<_ClaraScreenState>();
        if (state != null) {
          state._controller.text = text;
          state._send();
        }
      },
    );
  }
}
