import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants.dart';

// ---------------------------------------------------------------------------
// Language provider — Riverpod 3.x Notifier (no code generation needed)
// ---------------------------------------------------------------------------

class _LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Default to English. Will be overwritten on startup once persisted
    // preference is read from key_value_store (Task 21.2).
    return const Locale('en');
  }

  void setLocale(Locale locale) {
    assert(
      kSupportedLocaleCodes.contains(locale.languageCode),
      'Unsupported locale: ${locale.languageCode}',
    );
    state = locale;
  }
}

/// Exposes the currently active [Locale] to the widget tree.
///
/// Read:  `ref.watch(currentLocaleProvider)`
/// Write: `ref.read(currentLocaleProvider.notifier).setLocale(locale)`
final currentLocaleProvider =
    NotifierProvider<_LocaleNotifier, Locale>(_LocaleNotifier.new);
