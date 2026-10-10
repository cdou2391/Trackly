import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

import '../../helpers/test_app.dart';

List<RecurringItem> _items() => [
  testItem(
    'Spotify Premium Family Plan',
    amount: 10.99,
    due: DateTime(2026, 10, 12),
    logoKey: 'spotify',
  ),
  testItem('Gym membership downtown', amount: 35, due: DateTime(2026, 10, 27)),
  testItem(
    'Canva Pro',
    amount: 14.99,
    due: DateTime(2026, 11, 5),
    logoKey: 'canva',
    trialEnd: DateTime(2026, 11, 5),
  ),
  testItem('Old magazine', amount: 5, status: ItemStatus.paused),
  testItem('Cancelled service', amount: 8, status: ItemStatus.cancelled),
];

Future<void> _history(WidgetTester tester, dynamic db, String itemId) async {
  for (var i = 0; i < 3; i++) {
    // One write at a time, pumping in between: each write refreshes the live
    // queries on screen, which need the fake clock to advance.
    await tester.runAsync(
      () => db.paymentsDao.insertPayment(
        Payment(
          id: 'p$i',
          recurringItemId: itemId,
          amount: 10.99,
          currencyCode: 'USD',
          dueDate: DateTime(2026, 7 + i, 12),
          paidDate: DateTime(2026, 7 + i, 12),
          status: i == 1 ? PaymentStatus.skipped : PaymentStatus.paid,
          createdAt: testNow,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await settle(tester);
}

Future<void> _scroll(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 3; i++) {
    await tester.drag(list, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settle(tester);
}

void main() {
  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [360.0, 390.0, 430.0]) {
      for (final scale in [1.0, 1.5]) {
        final name = '${themeMode.name} ${width.toInt()} dp, text x$scale';

        // Tall, so every row is built and can be tapped; the edit-panel test
        // below uses a normal phone height.
        Future<dynamic> pump(WidgetTester tester, {double height = 1800}) =>
            pumpTrackly(
              tester,
              size: Size(width, height),
              themeMode: themeMode,
              textScale: scale,
              items: _items(),
            );

        tracklyTest('detail (active, long name, history): $name', (
          tester,
        ) async {
          final db = await pump(tester);
          await _history(tester, db, 'Spotify Premium Family Plan');
          await tester.tap(find.textContaining('Spotify Premium').first);
          await settle(tester);
          expect(find.textContaining('Spotify Premium'), findsWidgets);
          await _scroll(tester);
          expect(tester.takeException(), isNull);
        });

        tracklyTest('detail (trial, paused, cancelled): $name', (tester) async {
          await pump(tester);
          await tester.tap(find.text('More').last);
          await settle(tester);
          await tester.tap(find.text('All subscriptions'));
          await settle(tester);

          for (final label in [
            'Canva Pro',
            'Old magazine',
            'Cancelled service',
          ]) {
            await tester.tap(find.text(label).first);
            await settle(tester);
            await _scroll(tester);
            expect(tester.takeException(), isNull, reason: label);
            await tester.tap(find.byTooltip('Back'));
            await settle(tester);
          }
        });

        tracklyTest('edit panel and confirmation dialogs: $name', (
          tester,
        ) async {
          await pump(tester);
          await tester.tap(find.textContaining('Spotify Premium').first);
          await settle(tester);

          await tester.tap(find.byTooltip('Edit'));
          await settle(tester);
          expect(find.byKey(const Key('add-panel')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Close'));
          await settle(tester);

          await tester.ensureVisible(find.text('Cancel subscription'));
          await tester.tap(find.text('Cancel subscription'));
          await settle(tester);
          expect(find.textContaining('Cancel Spotify'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        tracklyTest('lists and More: $name', (tester) async {
          final db = await pump(tester);
          await _history(tester, db, 'Gym membership downtown');

          await tester.tap(find.text('More').last);
          await settle(tester);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('All subscriptions'));
          await settle(tester);
          await _scroll(tester);
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Back'));
          await settle(tester);

          await tester.tap(find.text('Payment history'));
          await settle(tester);
          await _scroll(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
