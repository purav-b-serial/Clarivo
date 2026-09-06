// Basic smoke test — verifies the app can build and render without crashing.
// Detailed unit and property tests are added in subsequent tasks.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clarivo/main.dart';

void main() {
  testWidgets('App renders splash screen without crashing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ClarivoApp()),
    );
    // Pump one frame — verifies the widget tree builds without throwing.
    await tester.pump();

    // The splash screen should show 'Clarivo' somewhere in the tree.
    expect(find.text('Clarivo'), findsWidgets);
  });
}
