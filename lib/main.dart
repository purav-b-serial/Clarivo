import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/providers/language_provider.dart';
import 'data/database/demo_database.dart';
import 'data/seed/content_seeder.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env for any future config values (GROQ_API_KEY now comes from
  // --dart-define=GROQ_API_KEY=... at build time — not from dotenv).
  await dotenv.load(fileName: '.env').catchError((_) {});

  // Verify key is available from build-time dart-define
  const apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  // ignore: avoid_print
  print(apiKey.isNotEmpty ? 'GROQ_API_KEY: build-time key loaded' : 'GROQ_API_KEY: WARNING — not set via --dart-define');

  // Open database and seed all subject content if needed
  final db = DemoDatabase();
  final count = await db.contentCount();
  if (count < kSeedThreshold) {
    // ignore: avoid_print
    print('main: count=$count < threshold=$kSeedThreshold, clearing and re-seeding...');
    await db.clearContent();
  }
  await ContentSeeder.seedIfEmpty(db);

  // ignore: avoid_print
  print('main: database ready with ${await db.contentCount()} chunks');

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
