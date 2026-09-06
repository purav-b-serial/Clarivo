import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../shared/widgets/clarivo_logo.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});
  static const _apkUrl = 'https://clarivo.netlify.app/downloads/clarivo-demo.apk';
  static const _windowsUrl = 'https://clarivo.netlify.app/downloads/clarivo-demo-windows.zip';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isNarrow ? 24 : 48, vertical: 60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ClarivoLogo(size: 120),
                  const SizedBox(height: 28),
                  Text('Clarivo',
                      style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text('Your personal AI study companion',
                      style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Clara helps CBSE Class 10 students understand Science topics using AI-powered explanations grounded in your textbook. Ask any question about Chemical Reactions, Acids and Bases, or Metals and Non-metals and get a clear, student-friendly answer instantly.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                    children: const [
                      _Pill(icon: Icons.bolt_rounded, label: 'Powered by Groq'),
                      _Pill(icon: Icons.menu_book_outlined, label: 'CBSE Class 10'),
                      _Pill(icon: Icons.lock_outline, label: 'Private and Free'),
                    ],
                  ),
                  const SizedBox(height: 44),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.tutor),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text('Try Clara Online', style: TextStyle(fontSize: 16)),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isNarrow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DownloadBtn(icon: Icons.android, label: 'Download for Android', url: _apkUrl),
                        const SizedBox(height: 10),
                        _DownloadBtn(icon: Icons.desktop_windows_rounded, label: 'Download for Windows', url: _windowsUrl),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: _DownloadBtn(icon: Icons.android, label: 'Download for Android', url: _apkUrl)),
                        const SizedBox(width: 12),
                        Expanded(child: _DownloadBtn(icon: Icons.desktop_windows_rounded, label: 'Download for Windows', url: _windowsUrl)),
                      ],
                    ),
                  const SizedBox(height: 60),
                  Text('Built for the AI Hackathon - September 2026',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: theme.colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
        ],
      ),
    );
  }
}

class _DownloadBtn extends StatelessWidget {
  const _DownloadBtn({required this.icon, required this.label, required this.url});
  final IconData icon;
  final String label;
  final String url;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => debugPrint('Download: $url'),
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
