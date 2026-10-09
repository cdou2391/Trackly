import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  tracklyTest('bottom add button opens the add screen', (tester) async {
    await pumpTrackly(tester);

    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await settle(tester);

    expect(find.text('Add subscription'), findsOneWidget);
  });
}
