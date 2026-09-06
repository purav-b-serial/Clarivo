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
                      _Stat('3', 'Topics Covered', Icons.topic_outlined),
                    ]),
                  ),
                  Expanded(child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      final item = _history[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: CircleAvatar(radius: 18, backgroundColor: theme.colorScheme.secondaryContainer, child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSecondaryContainer))),
                          title: Text(item.question, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                          subtitle: Text(_ago(item.timestamp), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          children: [Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(10)), child: SelectableText(item.answer, style: theme.textTheme.bodySmall)),
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
