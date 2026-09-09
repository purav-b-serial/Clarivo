import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/demo_database.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  List<ChatHistoryItem> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = ref.read(demoDatabaseProvider);
    final rows = await (db.select(db.chatHistoryItems)..orderBy([(t) => OrderingTerm.desc(t.timestamp)])).get();
    if (mounted) setState(() { _history = rows; _loading = false; });
  }

  String _ago(int ms) {
    final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  /// Distinct topics (chapters) actually used across all answered questions.
  int _topicsCovered() {
    final topics = <String>{};
    for (final item in _history) {
      if (item.topicsUsed.isEmpty) continue;
      for (final t in item.topicsUsed.split(' | ')) {
        if (t.trim().isNotEmpty) topics.add(t.trim());
      }
    }
    return topics.length;
  }

  /// Distinct subjects the student has asked questions in.
  int _subjectsCovered() {
    final subjects = <String>{};
    for (final item in _history) {
      final s = item.subject;
      if (s != null && s.isNotEmpty) subjects.add(s);
    }
    return subjects.length;
  }

  /// Builds a "Class N · Subject" label for a history item.
  String _contextLabel(ChatHistoryItem item) {
    final parts = <String>[];
    if (item.classNumber != null) parts.add('Class ${item.classNumber}');
    if (item.subject != null && item.subject!.isNotEmpty) parts.add(item.subject!);
    return parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => _loading = true); _load(); })],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bar_chart_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No questions yet', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Ask Clara a question to start tracking progress.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                ]))
              : Column(children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(16)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                      _Stat('${_history.length}', 'Questions Asked', Icons.help_outline),
                      Container(width: 1, height: 40, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2)),
                      _Stat('${_topicsCovered()}', 'Topics Covered', Icons.topic_outlined),
                      Container(width: 1, height: 40, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.2)),
                      _Stat('${_subjectsCovered()}', 'Subjects', Icons.category_outlined),
                    ]),
                  ),
                  Expanded(child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      final item = _history[i];
                      final ctxLabel = _contextLabel(item);
                      final topics = item.topicsUsed.isEmpty
                          ? <String>[]
                          : item.topicsUsed
                              .split(' | ')
                              .where((t) => t.trim().isNotEmpty)
                              .toList();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(radius: 18, backgroundColor: theme.colorScheme.secondaryContainer, child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSecondaryContainer))),
                          title: Text(item.question, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                if (ctxLabel.isNotEmpty) ...[
                                  Icon(Icons.menu_book_rounded, size: 12, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(ctxLabel, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600))),
                                  const SizedBox(width: 8),
                                ],
                                Text(_ago(item.timestamp), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          children: [Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Topics used to answer
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(Icons.lightbulb_outline, size: 13, color: theme.colorScheme.primary),
                                        const SizedBox(width: 5),
                                        Text('Topics used to answer', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                                      ]),
                                      const SizedBox(height: 6),
                                      if (topics.isEmpty)
                                        Text('Answered from general knowledge (no matching notes).', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic))
                                      else
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: topics.map((t) => Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3))),
                                            child: Text(t, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                                          )).toList(),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(10)), child: SelectableText(item.answer, style: theme.textTheme.bodySmall)),
                              ],
                            ),
                          )],
                        ),
                      );
                    },
                  )),
                ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _Stat(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Icon(icon, color: theme.colorScheme.onPrimaryContainer),
      const SizedBox(height: 4),
      Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer)),
      Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
    ]);
  }
}
