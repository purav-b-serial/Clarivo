import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const SizedBox(height: 8),
        _Header('About'),
        ListTile(leading: Icon(Icons.school_rounded, color: theme.colorScheme.primary), title: const Text('Clarivo'), subtitle: const Text('AI study companion for all CBSE students')),
        ListTile(leading: Icon(Icons.info_outline, color: theme.colorScheme.primary), title: const Text('Version'), trailing: const Text('1.0.0 Demo', style: TextStyle(fontSize: 12))),
        const Divider(),
        _Header('AI & Content'),
        ListTile(
          leading: Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
          title: const Text('AI Model'),
          subtitle: const Text('Groq API - Qwen3 27B'),
          trailing: _Badge('Cloud', Colors.blue),
        ),
        ListTile(
          leading: Icon(Icons.menu_book_outlined, color: theme.colorScheme.primary),
          title: const Text('Content'),
          subtitle: const Text('CBSE notes across multiple classes and subjects'),
          trailing: _Badge('Active', Colors.green),
        ),
        const Divider(),
        _Header('Coming Soon'),
        _Soon(Icons.translate_outlined, 'Multi-language Support', 'Hindi, Tamil, Telugu, Kannada, Bengali'),
        _Soon(Icons.account_circle_outlined, 'Student Accounts', 'Login, profiles, sync across devices'),
        _Soon(Icons.library_books_outlined, 'Full CBSE Content', 'Classes 6-12, JEE, NEET, UPSC'),
        _Soon(Icons.camera_alt_outlined, 'Image Input', 'Photograph questions for Clara'),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}

class _Soon extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const _Soon(this.icon, this.title, this.sub);
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(title, style: TextStyle(color: c)),
      subtitle: Text(sub, style: TextStyle(color: c, fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
        child: const Text('Soon', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
