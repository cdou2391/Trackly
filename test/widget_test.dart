import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/shared/widgets/screen_header.dart';

import 'helpers/test_app.dart';

void main() {
  tracklyTest('app shell shows navigation and switches tabs', (tester) async {
    await pumpTrackly(tester);

    for (final label in ['Home', 'Insights', 'Calendar', 'More']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Insights'));
    await settle(tester);
    expect(find.text('Insights'), findsWidgets);
    expect(find.text('YOUR RECURRING COST'), findsNothing);

    await tester.tap(find.text('Home'));
    await settle(tester);
    expect(find.text('YOUR RECURRING COST'), findsOneWidget);
  });

  tracklyTest('bottom add button opens the add panel, not a new screen', (
    tester,
  ) async {
    await pumpTrackly(tester);

    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await settle(tester);

    expect(find.byKey(const Key('add-panel')), findsOneWidget);
    // Home is still underneath and the navigation bar is still visible.
    expect(find.text('YOUR RECURRING COST'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
  });

  tracklyTest('every screen header matches Home and shows its icon', (
    tester,
  ) async {
    await pumpTrackly(tester);

    Finder inHeader(Finder finder) =>
        find.descendant(of: find.byType(ScreenHeader), matching: finder);
    double titleSize(String title) =>
        tester.widget<Text>(inHeader(find.text(title))).style!.fontSize!;

    final homeSize = titleSize('Trackly');
    expect(inHeader(find.byType(Icon)), findsNWidgets(2)); // search, settings

    final tabs = {
      'Insights': Icons.insights_rounded,
      'Calendar': Icons.calendar_month_rounded,
      'More': Icons.more_horiz_rounded,
    };
    for (final tab in tabs.entries) {
      await tester.tap(find.text(tab.key));
      await settle(tester);
      expect(titleSize(tab.key), homeSize, reason: tab.key);
      // The header hugs its content (a stretched header pushed icons mid-screen).
      expect(
        tester.getSize(find.byType(ScreenHeader)).height,
        lessThan(100),
        reason: tab.key,
      );
      expect(inHeader(find.byIcon(tab.value)), findsOneWidget, reason: tab.key);
    }
  });
}
