import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/demo_database.dart';

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});
  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  int _chunks = 0, _history = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final db = ref.read(demoDatabaseProvider);
    final c = await db.contentCount();
    final h = await (db.select(db.chatHistoryItems)).get();
    if (mounted) setState(() { _chunks = c; _history = h.length; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Installed', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _Item(Icons.menu_book_rounded, 'CBSE Class 10 Science', '$_chunks chunks, 9 chapters', 'Installed', Colors.green, theme),
          const SizedBox(height: 6),
          _Item(Icons.chat_bubble_outline, 'Chat History', '$_history conversations', 'Active', Colors.green, theme),
          const SizedBox(height: 6),
          _Item(Icons.bolt_rounded, 'Groq AI (Cloud)', 'qwen/qwen3.8-27b - no local storage', 'Cloud', Colors.blue, theme),
          const SizedBox(height: 20),
          Text('Coming Soon', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _SoonItem(Icons.download_outlined, 'Download More Content', 'Physics, Biology - Classes 6-12', theme),
          const SizedBox(height: 6),
          _SoonItem(Icons.memory_outlined, 'On-device AI Model', 'Qwen2.5-3B (~1.9 GB) for offline use', theme),
          const SizedBox(height: 6),
          _SoonItem(Icons.upload_file_outlined, 'Upload Your Notes', 'PDF and text files', theme),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon; final String title, sub, status; final Color color; final ThemeData theme;
  const _Item(this.icon, this.title, this.sub, this.status, this.color, this.theme);
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
    CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color, size: 20)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      Text(sub, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ])),
    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold))),
  ])));
}

class _SoonItem extends StatelessWidget {
  final IconData icon; final String title, sub; final ThemeData theme;
  const _SoonItem(this.icon, this.title, this.sub, this.theme);
  @override
  Widget build(BuildContext context) => Card(child: ListTile(
    leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
    title: Text(title, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
    subtitle: Text(sub, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
    trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: const Text('Soon', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold))),
  ));
}
