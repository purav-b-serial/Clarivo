import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Route name constants ────────────────────────────────────────────────────

/// Named route constants. Use these everywhere instead of raw path strings
/// so that rename refactors stay in one place.
abstract class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String tutor = '/tutor';
  static const String content = '/content';
  static const String progress = '/progress';
  static const String storage = '/storage';
  static const String settings = '/settings';
  static const String supervisor = '/supervisor';
}

// ─── Placeholder screens (replaced in later tasks) ──────────────────────────

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}

// ─── Router provider ─────────────────────────────────────────────────────────

/// A Riverpod [Provider] that exposes the [GoRouter] instance to the widget tree.
/// Consuming this provider (rather than constructing GoRouter inline in main.dart)
/// allows tests to substitute a custom router and enables redirect logic that
/// reads other Riverpod providers (e.g., auth state).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    routes: [
      // ── Splash / entry point ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Clarivo'),
      ),

      // ── Authentication ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Login'),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Register'),
      ),

      // ── Main shell ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Home'),
      ),

      // ── AI Tutor ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.tutor,
        name: 'tutor',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'AI Tutor'),
      ),

      // ── Content Browser ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.content,
        name: 'content',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Content Library'),
      ),

      // ── Progress Dashboard ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.progress,
        name: 'progress',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'My Progress'),
      ),

      // ── Storage Management ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.storage,
        name: 'storage',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Storage'),
      ),

      // ── Settings ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Settings'),
      ),

      // ── Supervisor Dashboard ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.supervisor,
        name: 'supervisor',
        builder: (context, state) =>
            const _PlaceholderScreen(title: 'Supervisor Dashboard'),
      ),
    ],

    // ── Global error page ─────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
