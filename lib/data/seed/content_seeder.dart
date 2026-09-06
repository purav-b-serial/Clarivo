import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../database/demo_database.dart';

/// Current seed version — increment when content is updated to force re-seed.
const int kCurrentSeedVersion = 5;

/// Re-seed if total chunk count is below this threshold.
const int kSeedThreshold = 80;

class ContentSeeder {
  static const _assetFiles = [
    'assets/content/science.json',
    'assets/content/mathematics.json',
    'assets/content/social_science.json',
    'assets/content/english.json',
    'assets/content/hindi.json',
    'assets/content/sanskrit.json',
  ];

  /// Loads all content JSON assets and seeds the database.
  /// Idempotent — checks count first and returns early if already seeded.
  static Future<void> seedIfEmpty(DemoDatabase db) async {
    final count = await db.contentCount();
    if (count > 0) return;

    for (final assetPath in _assetFiles) {
      try {
        final jsonString = await rootBundle.loadString(assetPath);
        final List<dynamic> chunks = jsonDecode(jsonString) as List<dynamic>;

        await db.batch((batch) {
          for (final raw in chunks) {
            final chunk = raw as Map<String, dynamic>;
            final subject = chunk['subject'] as String? ?? 'Science';
            final chapter = chunk['chapter'] as String? ?? '';
            final text = chunk['text'] as String? ?? '';
            if (chapter.isEmpty || text.isEmpty) continue;
            batch.insert(
              db.contentChunks,
              ContentChunksCompanion.insert(
                subject: Value(subject),
                chapter: chapter,
                chunkText: text,
              ),
            );
          }
        });
        // ignore: avoid_print
        print('ContentSeeder: loaded $assetPath (${chunks.length} chunks)');
      } catch (e) {
        // ignore: avoid_print
        print('ContentSeeder: failed to load $assetPath — $e');
      }
    }
  }
}
