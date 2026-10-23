import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1800);

double _opacityOf(WidgetTester tester, Finder child) {
  final fade = tester.widget<FadeTransition>(
    find.ancestor(of: child, matching: find.byType(FadeTransition)).first,
  );
  return fade.opacity.value;
}

void main() {
  tracklyTest('choosing a day with charges fades its rows in', (tester) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 15, due: DateTime(2026, 10, 14)),
        testItem('Spotify', amount: 10, due: DateTime(2026, 10, 14)),
      ],
    );
    await tester.tap(find.text('Calendar').last);
    await settle(tester);

    // The 14th is a plain day cell; the rows are not there yet.
    await tester.tap(find.text('14'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('Netflix'), findsOneWidget);
    // Just arrived: still mostly transparent, not popped in fully formed.
    expect(_opacityOf(tester, find.text('Netflix')), lessThan(0.6));

    await settle(tester);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);
    expect(_opacityOf(tester, find.text('Netflix')), 1);
    expect(_opacityOf(tester, find.text('Spotify')), 1);
  });

  tracklyTest('the second row arrives after the first', (tester) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 15, due: DateTime(2026, 10, 14)),
        testItem('Spotify', amount: 10, due: DateTime(2026, 10, 14)),
      ],
    );
    await tester.tap(find.text('Calendar').last);
    await settle(tester);
    await tester.tap(find.text('14'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      _opacityOf(tester, find.text('Netflix')),
      greaterThan(_opacityOf(tester, find.text('Spotify'))),
    );
    await settle(tester);
  });

  tracklyTest('moving away leaves one list, not two', (tester) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [testItem('Netflix', amount: 15, due: DateTime(2026, 10, 14))],
    );
    await tester.tap(find.text('Calendar').last);
    await settle(tester);
    await tester.tap(find.text('14'));
    await settle(tester);
    expect(find.text('Netflix'), findsOneWidget);

    await tester.tap(find.text('20'));
    await settle(tester);
    expect(find.text('Netflix'), findsNothing);
    expect(find.text('No charges on this day.'), findsOneWidget);
  });
}
