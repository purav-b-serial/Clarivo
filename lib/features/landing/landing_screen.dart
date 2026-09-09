import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../shared/widgets/clarivo_logo.dart';

// JS interop bindings to the install helpers defined in web/index.html.
@JS('clarivoCanInstall')
external JSBoolean? _jsCanInstall();

@JS('clarivoInstall')
external JSBoolean? _jsInstall();

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

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
                      'Clara helps CBSE students understand any subject using AI-powered explanations grounded in your textbook. Pick your class and subject, then ask any question and get a clear, student-friendly answer instantly.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                    children: const [
                      _Pill(icon: Icons.bolt_rounded, label: 'Powered by Groq'),
                      _Pill(icon: Icons.menu_book_outlined, label: 'All CBSE Classes'),
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
                        _DownloadBtn(
                          icon: Icons.android,
                          label: 'Install on Android',
                          onPressed: () => _installApp(context),
                        ),
                        const SizedBox(height: 10),
                        _DownloadBtn(
                          icon: Icons.desktop_windows_rounded,
                          label: 'Install for Windows',
                          onPressed: () => _installOnWindows(context),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _DownloadBtn(
                            icon: Icons.android,
                            label: 'Install on Android',
                            onPressed: () => _installApp(context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DownloadBtn(
                            icon: Icons.desktop_windows_rounded,
                            label: 'Install for Windows',
                            onPressed: () => _installOnWindows(context),
                          ),
                        ),
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

  /// Android install: if the browser has captured an install prompt, trigger the
  /// native "Add to Home Screen". Otherwise show clear manual instructions.
  void _installApp(BuildContext context) {
    bool triggered = false;
    try {
      final canInstall = _jsCanInstall()?.toDart ?? false;
      if (canInstall) {
        triggered = _jsInstall()?.toDart ?? false;
      }
    } catch (_) {
      triggered = false;
    }

    if (!triggered) {
      _showInstallInstructions(context);
    }
  }

  void _showInstallInstructions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.install_mobile_rounded),
            SizedBox(width: 10),
            Expanded(child: Text('Install Clarivo')),
          ],
        ),
        content: const Text(
          'Clarivo installs as an app straight from your browser — no store needed.\n\n'
          'On Android (Chrome):\n'
          '1. Tap the ⋮ menu (top-right).\n'
          '2. Choose "Add to Home screen" / "Install app".\n'
          '3. Confirm — the Clarivo icon appears on your home screen.\n\n'
          'It then opens full-screen like a normal app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Windows: install Clarivo as a desktop app. Chrome/Edge capture a native
  /// install prompt (beforeinstallprompt); triggering it adds a Start Menu /
  /// desktop shortcut and launches Clarivo in its own standalone window — a
  /// real "installed app" feel. If no prompt is available, show manual steps.
  void _installOnWindows(BuildContext context) {
    bool triggered = false;
    try {
      final canInstall = _jsCanInstall()?.toDart ?? false;
      if (canInstall) {
        triggered = _jsInstall()?.toDart ?? false;
      }
    } catch (_) {
      triggered = false;
    }

    if (!triggered) {
      _showWindowsInstallInstructions(context);
    }
  }

  void _showWindowsInstallInstructions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.install_desktop_rounded),
            SizedBox(width: 10),
            Expanded(child: Text('Install Clarivo for Windows')),
          ],
        ),
        content: const Text(
          'Clarivo installs as a desktop app straight from your browser — no store, no download file needed.\n\n'
          'On Chrome or Edge (Windows):\n'
          '1. Click the install icon (a monitor with a down-arrow) in the address bar, or open the ⋮ menu.\n'
          '2. Choose "Install Clarivo" / "Apps → Install this site as an app".\n'
          '3. Confirm — Clarivo gets a desktop and Start Menu shortcut.\n\n'
          'It then opens in its own window, just like a normal installed app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
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
  const _DownloadBtn({required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
