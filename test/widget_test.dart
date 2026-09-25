import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets(
      'Split, undo, redo, reload, drawer, and dark/light color mode test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Initially count is 1
    expect(find.text('1'), findsOneWidget);

    // Tap on the rectangle to split
    final initialGesture = find.byType(GestureDetector).first;
    await tester.tap(initialGesture);
    await tester.pump();

    // Now count is 2
    expect(find.text('2'), findsOneWidget);

    // Tap Undo (Before)
    await tester.tap(find.byTooltip('Before (Undo)'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // Tap Redo (After)
    await tester.tap(find.byTooltip('After (Redo)'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    // Tap Reload
    await tester.tap(find.byTooltip('Reload (Reset to 1)'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    // Test Dark & Light Mode button (turn ON)
    expect(find.byTooltip('Dark & Light Mode: OFF (Click to activate)'),
        findsOneWidget);
    await tester
        .tap(find.byTooltip('Dark & Light Mode: OFF (Click to activate)'));
    await tester.pumpAndSettle();

    // Verify it is now ON
    expect(find.byTooltip('Dark & Light Mode: ON (Click to restore colors)'),
        findsOneWidget);

    // Turn OFF (reverts back to original colors)
    await tester.tap(
        find.byTooltip('Dark & Light Mode: ON (Click to restore colors)'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Dark & Light Mode: OFF (Click to activate)'),
        findsOneWidget);

    // Open settings drawer with hamburger button
    await tester.tap(find.byTooltip('Settings Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Customizations'), findsOneWidget);
    expect(find.text('Dark & Light Colors Mode'), findsOneWidget);
    expect(find.text('Gap (Spacing)'), findsOneWidget);
    expect(find.text('Border Radius'), findsOneWidget);
  });
}