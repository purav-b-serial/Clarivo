import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/providers/language_provider.dart';
import 'data/database/demo_database.dart';
import 'data/seed/content_seeder.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AI transport mode:
  //  - build-time key present  -> direct Groq calls (local dev, --dart-define)
  //  - no key                  -> server-side proxy at /api/clara (production;
  //                               the key lives only in the Netlify env var)
  const apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  // ignore: avoid_print
  print(apiKey.isNotEmpty
      ? 'Clara: direct mode (build-time GROQ_API_KEY present)'
      : 'Clara: proxy mode (calls /api/clara — key held server-side)');

  // Open database and seed all subject content if needed.
  // Re-seed when the bundled content version is newer than what's stored,
  // OR when the chunk count is suspiciously low (safety net).
  final db = DemoDatabase();
  final count = await db.contentCount();
  final storedVersion = await db.getSeedVersion();
  if (storedVersion < kCurrentSeedVersion || count < kSeedThreshold) {
    // ignore: avoid_print
    print('main: seed v$storedVersion < v$kCurrentSeedVersion (or count=$count) — clearing and re-seeding...');
    await db.clearContent();
  }
  await ContentSeeder.seedIfEmpty(db);
  await db.setSeedVersion(kCurrentSeedVersion);

  // ignore: avoid_print
  print('main: database ready with ${await db.contentCount()} chunks (seed v$kCurrentSeedVersion)');

  runApp(
    ProviderScope(
      overrides: [
        // Inject the pre-opened DB instance so all providers share it
        demoDatabaseProvider.overrideWithValue(db),
      ],
      child: const ClarivoApp(),
    ),
  );
}

class ClarivoApp extends ConsumerWidget {
  const ClarivoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: 'Clarivo',
      debugShowCheckedModeBanner: false,

      // Light theme — deep blue primary
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),

      // Dark theme
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),

      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('ta'),
        Locale('te'),
        Locale('kn'),
        Locale('bn'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
