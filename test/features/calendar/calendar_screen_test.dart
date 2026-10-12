import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

/// Tall enough to build the whole screen, so every row is found.
const _tall = Size(390, 1800);

Future<void> _openCalendar(WidgetTester tester) async {
  await tester.tap(find.text('Calendar').last);
  await settle(tester);
}

Finder _day(int day) => find.text('$day');

void main() {
  group('summary', () {
    tracklyTest('opens on the current month with today selected', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Netflix', amount: 15, due: DateTime(2026, 10, 10)),
          testItem('Spotify', amount: 10, due: DateTime(2026, 10, 14)),
        ],
      );
      await _openCalendar(tester);

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Total this month'), findsOneWidget);
      expect(find.text('Left from Oct 9'), findsOneWidget);
      // Nothing is paid, so the total and what is left are the same.
      expect(find.text(r'$25.00'), findsNWidgets(2));
      expect(find.text('Fri, Oct 9'), findsOneWidget);
      expect(find.text('No charges on this day.'), findsOneWidget);
    });

    tracklyTest('shows zero when there are no items', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await _openCalendar(tester);

      expect(find.text(r'$0.00'), findsNWidgets(2));
    });

    tracklyTest('lists each currency on its own line', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Netflix', amount: 10, due: DateTime(2026, 10, 12)),
          testItem(
            'Internet',
            amount: 30000,
            currency: 'RWF',
            due: DateTime(2026, 10, 15),
          ),
        ],
      );
      await _openCalendar(tester);

      expect(find.text(r'$10.00'), findsNWidgets(2));
      expect(find.text('RWF 30,000'), findsNWidgets(2));
    });

    tracklyTest('paid charges count in the total but are not left', (
      tester,
    ) async {
      final db = await pumpTrackly(
        tester,
        size: _tall,
        items: [
          // Paid on 3 Oct, so its next charge is already in November.
          testItem('Netflix', amount: 15, due: DateTime(2026, 11, 3)),
          testItem('Spotify', amount: 10, due: DateTime(2026, 10, 14)),
        ],
      );
      await tester.runAsync(
        () => db.paymentsDao.insertPayment(
          Payment(
            id: 'p1',
            recurringItemId: 'Netflix',
            amount: 15,
            currencyCode: 'USD',
            dueDate: DateTime(2026, 10, 3),
            paidDate: DateTime(2026, 10, 3),
            status: PaymentStatus.paid,
            createdAt: testNow,
          ),
        ),
      );
      await settle(tester);
      await _openCalendar(tester);

      expect(find.text(r'$25.00'), findsOneWidget); // total
      expect(find.text(r'$10.00'), findsOneWidget); // left from 9 Oct

      await tester.tap(_day(3));
      await settle(tester);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
    });
  });

  group('days', () {
    tracklyTest('tapping a day lists its charges and updates what is left', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Netflix', amount: 15, due: DateTime(2026, 10, 10)),
          testItem('Spotify', amount: 10, due: DateTime(2026, 10, 14)),
        ],
      );
      await _openCalendar(tester);

      await tester.tap(_day(10));
      await settle(tester);
      expect(find.text('Left from Oct 10'), findsOneWidget);
      expect(find.text(r'$25.00'), findsNWidgets(2));
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Spotify'), findsNothing);

      await tester.tap(_day(14));
      await settle(tester);
      expect(find.text('Left from Oct 14'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('Netflix'), findsNothing);
      // Total stays at $25.00; left drops to $10.00 (the row shows it too).
      expect(find.text(r'$25.00'), findsOneWidget);
      expect(find.text(r'$10.00'), findsNWidgets(2));
    });

    tracklyTest('a charge before today is marked overdue', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix', due: DateTime(2026, 10, 5))],
      );
      await _openCalendar(tester);

      await tester.tap(_day(5));
      await settle(tester);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });

    tracklyTest('a trial charge is shown with a Trial chip', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem(
            'Canva',
            amount: 14.99,
            due: DateTime(2026, 10, 20),
            trialEnd: DateTime(2026, 10, 20),
          ),
        ],
      );
      await _openCalendar(tester);

      // Trials are left out of the totals, as on Home.
      expect(find.text(r'$0.00'), findsNWidgets(2));
      await tester.tap(_day(20));
      await settle(tester);
      expect(find.text('Canva'), findsOneWidget);
      expect(find.text('Trial'), findsOneWidget);
    });

    tracklyTest('tapping a charge opens the item', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix', due: DateTime(2026, 10, 12))],
      );
      await _openCalendar(tester);

      await tester.tap(_day(12));
      await settle(tester);
      await tester.tap(find.text('Netflix'));
      await settle(tester);
      expect(find.text('Mark as paid'), findsOneWidget);
    });
  });

  group('months', () {
    tracklyTest('steps through months and projects the schedule', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix', amount: 15, due: DateTime(2026, 10, 10))],
      );
      await _openCalendar(tester);
      expect(find.text('Today'), findsNothing);

      await tester.tap(find.byTooltip('Next month'));
      await settle(tester);
      expect(find.text('November 2026'), findsOneWidget);
      // Another month ahead: a different month starts on its first day.
      expect(find.text('Left from Nov 1'), findsOneWidget);
      expect(find.text(r'$15.00'), findsNWidgets(2));
      expect(find.text('Today'), findsOneWidget);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pump();
      await tester.tap(find.byTooltip('Previous month'));
      await settle(tester);
      expect(find.text('September 2026'), findsOneWidget);
      // Nothing was due before the first charge.
      expect(find.text(r'$0.00'), findsNWidgets(2));

      await tester.tap(find.text('Today'));
      await settle(tester);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Left from Oct 9'), findsOneWidget);
    });

    tracklyTest('a weekly item appears on every week', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem(
            'Gym',
            amount: 10,
            frequency: BillingFrequency.weekly,
            due: DateTime(2026, 10, 2),
          ),
        ],
      );
      await _openCalendar(tester);

      // 2, 9, 16, 23 and 30 October.
      expect(find.text(r'$50.00'), findsOneWidget);
      // From the 9th: the 9th, 16th, 23rd and 30th are still to pay.
      expect(find.text(r'$40.00'), findsOneWidget);
    });
  });

  tracklyTest('has no layout overflow on a narrow screen with large text', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: const Size(320, 1800),
      textScale: 1.6,
      items: [
        testItem('Netflix', amount: 15, due: DateTime(2026, 10, 12)),
        testItem(
          'Internet',
          amount: 30000,
          currency: 'RWF',
          due: DateTime(2026, 10, 12),
        ),
      ],
    );
    await _openCalendar(tester);
    await tester.tap(_day(12));
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
