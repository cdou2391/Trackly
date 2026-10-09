import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/app.dart';

void main() {
  testWidgets('app shell shows navigation and navigates between tabs',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TracklyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Subscriptions & Bills'), findsOneWidget);
    for (final label in ['Home', 'Insights', 'Calendar', 'More']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Insights'), findsWidgets);
  });

  testWidgets('add button opens the add screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TracklyApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Add subscription'), findsOneWidget);
  });
}
