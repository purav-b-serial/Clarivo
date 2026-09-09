import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import '../database/demo_database.dart';

/// Current seed version — increment when content is updated to force re-seed.
const int kCurrentSeedVersion = 24;

/// Re-seed if total chunk count is below this threshold.
const int kSeedThreshold = 80;

/// Maps each content asset to its default CBSE class number.
/// A chunk may override this by including a `"class"` field in the JSON.
class _ContentAsset {
  const _ContentAsset(this.path, this.defaultClass);
  final String path;
  final int defaultClass;
}

class ContentSeeder {
  static const _assets = [
    // ── Class 10 ──────────────────────────────────────────────────────────
    _ContentAsset('assets/content/science.json', 10),
    _ContentAsset('assets/content/mathematics.json', 10),
    _ContentAsset('assets/content/social_science.json', 10),
    _ContentAsset('assets/content/english.json', 10),
    _ContentAsset('assets/content/hindi.json', 10),
    _ContentAsset('assets/content/sanskrit.json', 10),
    // ── Class 11 ──────────────────────────────────────────────────────────
    _ContentAsset('assets/content/physics_class11.json', 11),
    _ContentAsset('assets/content/chemistry_class11.json', 11),
    _ContentAsset('assets/content/biology_class11.json', 11),
    _ContentAsset('assets/content/mathematics_class11.json', 11),
    _ContentAsset('assets/content/computer_science_class11.json', 11),
    _ContentAsset('assets/content/english_class11.json', 11),
    // ── Class 12 ──────────────────────────────────────────────────────────
    _ContentAsset('assets/content/physics_class12.json', 12),
    _ContentAsset('assets/content/chemistry_class12.json', 12),
    _ContentAsset('assets/content/mathematics_class12.json', 12),
    _ContentAsset('assets/content/biology_class12.json', 12),
    _ContentAsset('assets/content/computer_science_class12.json', 12),
    _ContentAsset('assets/content/english_class12.json', 12),
  ];

  /// Loads all content JSON assets and seeds the database.
  /// Idempotent — checks count first and returns early if already seeded.
  static Future<void> seedIfEmpty(DemoDatabase db) async {
    final count = await db.contentCount();
    if (count > 0) return;

    for (final asset in _assets) {
      try {
        final jsonString = await rootBundle.loadString(asset.path);
        final List<dynamic> chunks = jsonDecode(jsonString) as List<dynamic>;

        await db.batch((batch) {
          for (final raw in chunks) {
            final chunk = raw as Map<String, dynamic>;
            final subject = chunk['subject'] as String? ?? 'Science';
            final chapter = chunk['chapter'] as String? ?? '';
            final text = chunk['text'] as String? ?? '';
            final classNumber =
                (chunk['class'] as num?)?.toInt() ?? asset.defaultClass;
            if (chapter.isEmpty || text.isEmpty) continue;
            batch.insert(
              db.contentChunks,
              ContentChunksCompanion.insert(
                classNumber: Value(classNumber),
                subject: Value(subject),
                chapter: chapter,
                chunkText: text,
              ),
            );
          }
        });
        // ignore: avoid_print
        print('ContentSeeder: loaded ${asset.path} '
            '(${chunks.length} chunks, class ${asset.defaultClass})');
      } catch (e) {
        // ignore: avoid_print
        print('ContentSeeder: failed to load ${asset.path} — $e');
      }
    }
  }
}
