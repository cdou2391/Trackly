import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1800);

class _RecordingAnalytics implements AnalyticsService {
  final events = <String>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(name);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

Future<void> _openInsights(WidgetTester tester) async {
  await tester.tap(find.text('Insights').last);
  await settle(tester);
}

void main() {
  tracklyTest('shows an invitation when there is nothing yet', (tester) async {
    await pumpTrackly(tester, size: _tall);
    await _openInsights(tester);

    expect(find.text('No spending to show yet'), findsOneWidget);
    expect(find.text('By category'), findsNothing);
    expect(find.text('Per month'), findsNothing);
  });

  tracklyTest('shows monthly and yearly totals', (tester) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 15, categoryId: 'entertainment'),
        testItem('Spotify', amount: 10, categoryId: 'entertainment'),
        testItem(
          'Notion',
          amount: 120,
          frequency: BillingFrequency.yearly,
          categoryId: 'software',
        ),
      ],
    );
    await _openInsights(tester);

    expect(find.text('Per month'), findsOneWidget);
    expect(find.text(r'$35.00'), findsOneWidget);
    expect(find.text('Per year'), findsOneWidget);
    expect(find.text(r'$420.00'), findsOneWidget);
  });

  tracklyTest('breaks the monthly cost down by category', (tester) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 15, categoryId: 'entertainment'),
        testItem('Spotify', amount: 10, categoryId: 'entertainment'),
        testItem(
          'Notion',
          amount: 120,
          frequency: BillingFrequency.yearly,
          categoryId: 'software',
        ),
      ],
    );
    await _openInsights(tester);

    expect(find.text('By category'), findsOneWidget);
    expect(find.text('Entertainment'), findsOneWidget);
    // Amounts also appear in Biggest costs, so the captions identify the rows.
    expect(find.text(r'$25.00'), findsOneWidget);
    expect(find.text('2 items · 71%'), findsOneWidget);
    expect(find.text('Software'), findsOneWidget);
    expect(find.text(r'$10.00'), findsWidgets);
    expect(find.text('1 item · 29%'), findsOneWidget);

    // Largest first.
    final entertainment = tester.getTopLeft(find.text('Entertainment')).dy;
    final software = tester.getTopLeft(find.text('Software')).dy;
    expect(entertainment, lessThan(software));
  });

  tracklyTest('items without a category are listed as Other', (tester) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [testItem('Pottery class', amount: 500)],
    );
    await _openInsights(tester);

    expect(find.text('Other'), findsOneWidget);
    expect(find.text('1 item · 100%'), findsOneWidget);
  });

  tracklyTest('each currency gets its own breakdown', (tester) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 10, categoryId: 'entertainment'),
        testItem(
          'Internet',
          amount: 30000,
          currency: 'RWF',
          categoryId: 'utilities',
        ),
      ],
    );
    await _openInsights(tester);

    // Each currency is labelled in every section that lists amounts.
    expect(find.text('USD'), findsWidgets);
    expect(find.text('RWF'), findsWidgets);
    expect(find.text('Entertainment'), findsOneWidget);
    expect(find.text('Utilities'), findsOneWidget);
  });

  tracklyTest('free trials and paused items are left out of the money', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem(
          'Canva',
          amount: 14.99,
          due: DateTime(2026, 11, 15),
          trialEnd: DateTime(2026, 11, 15),
          categoryId: 'software',
        ),
        testItem('Old', amount: 50, status: ItemStatus.paused),
      ],
    );
    await _openInsights(tester);

    expect(find.text(r'$0.00'), findsNWidgets(2));
    expect(find.text('By category'), findsNothing);
  });

  tracklyTest('counts active items, trials and charges ahead', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', due: DateTime(2026, 10, 12)),
        testItem('Spotify', due: DateTime(2026, 10, 14)),
        testItem(
          'Canva',
          due: DateTime(2026, 11, 15),
          trialEnd: DateTime(2026, 11, 15),
        ),
        testItem('Paused', status: ItemStatus.paused),
      ],
    );
    await _openInsights(tester);

    expect(find.bySemanticsLabel('Active: 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Trial: 1'), findsOneWidget);
    // Netflix 12 Oct, Spotify 14 Oct, and the same two again on 12 and 14 Nov
    // are outside the window; Canva's first charge (15 Nov) is too.
    expect(
      find.bySemanticsLabel('2 charges in the next month'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  tracklyTest('opening Insights and Calendar is logged', (tester) async {
    final analytics = _RecordingAnalytics();
    await pumpTrackly(tester, size: _tall, analytics: analytics);

    await _openInsights(tester);
    await tester.tap(find.text('Calendar').last);
    await settle(tester);

    expect(analytics.events, contains(AnalyticsEvents.insightsOpened));
    expect(analytics.events, contains(AnalyticsEvents.calendarOpened));
  });

  tracklyTest('has no layout overflow on a narrow screen with large text', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: const Size(320, 1800),
      textScale: 1.6,
      items: [
        testItem(
          'Netflix',
          amount: 15,
          categoryId: 'entertainment',
          due: DateTime(2026, 10, 12),
        ),
        testItem(
          'Internet',
          amount: 30000,
          currency: 'RWF',
          categoryId: 'utilities',
        ),
      ],
    );
    await _openInsights(tester);

    expect(tester.takeException(), isNull);
  });

  group('paid this month', () {
    tracklyTest('shows what was paid against the month, as the Calendar does', (
      tester,
    ) async {
      final db = await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Netflix', amount: 15, due: DateTime(2026, 10, 20)),
          testItem('Spotify', amount: 10, due: DateTime(2026, 11, 10)),
        ],
      );
      await tester.runAsync(
        () => db.paymentsDao.insertPayment(
          Payment(
            id: 'p1',
            recurringItemId: 'Spotify',
            amount: 10,
            currencyCode: 'USD',
            dueDate: DateTime(2026, 10, 5),
            paidDate: DateTime(2026, 10, 5),
            status: PaymentStatus.paid,
            createdAt: testNow,
          ),
        ),
      );
      await _openInsights(tester);

      expect(find.text('Paid this month'), findsOneWidget);
      expect(find.text(r'$10.00 of $25.00'), findsOneWidget);
      expect(find.text('Charges you mark as paid count here.'), findsNothing);
    });

    tracklyTest('with nothing paid it says how a charge counts', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix', amount: 15, due: DateTime(2026, 10, 20))],
      );
      await _openInsights(tester);

      expect(find.text(r'$0.00 of $15.00'), findsOneWidget);
      expect(find.text('Charges you mark as paid count here.'), findsOneWidget);
    });

    tracklyTest('is left out when nothing is due this month', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem(
            'Yearly',
            amount: 100,
            frequency: BillingFrequency.yearly,
            due: DateTime(2027, 3, 1),
          ),
        ],
      );
      await _openInsights(tester);

      expect(find.text('Paid this month'), findsNothing);
    });
  });

  group('subscriptions and bills', () {
    tracklyTest('are split when there are both', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Netflix', amount: 15),
          testItem('Rent', amount: 500, type: RecurringItemType.bill),
        ],
      );
      await _openInsights(tester);

      expect(find.text('Subscriptions and bills'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Subscriptions'), findsOneWidget);
      // Each also has a category row with the same figures: one item each.
      expect(find.text('1 item · 97%'), findsNWidgets(2)); // Rent
      expect(find.text('1 item · 3%'), findsNWidgets(2)); // Netflix
      // Largest first.
      expect(
        tester.getTopLeft(find.text('Bills')).dy,
        lessThan(tester.getTopLeft(find.text('Subscriptions')).dy),
      );
    });

    tracklyTest('are not split when there is only one kind', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix'), testItem('Spotify')],
      );
      await _openInsights(tester);

      expect(find.text('Subscriptions and bills'), findsNothing);
    });
  });

  group('biggest costs', () {
    tracklyTest('lists the five costliest, largest first', (tester) async {
      await pumpTrackly(
        tester,
        size: const Size(390, 2600),
        items: [
          for (var i = 1; i <= 6; i++) testItem('Service $i', amount: i * 10.0),
        ],
      );
      await _openInsights(tester);

      expect(find.text('Biggest costs'), findsOneWidget);
      expect(find.text('Service 6'), findsOneWidget);
      expect(find.text('Service 2'), findsOneWidget);
      expect(find.text('Service 1'), findsNothing); // the sixth, cut off
      expect(
        tester.getTopLeft(find.text('Service 6')).dy,
        lessThan(tester.getTopLeft(find.text('Service 5')).dy),
      );
      expect(find.text('29% of your monthly cost'), findsOneWidget); // 60/210
    });

    tracklyTest('a single item has nothing to rank', (tester) async {
      await pumpTrackly(tester, size: _tall, items: [testItem('Netflix')]);
      await _openInsights(tester);

      expect(find.text('Biggest costs'), findsNothing);
    });

    tracklyTest('tapping one opens it', (tester) async {
      await pumpTrackly(
        tester,
        size: const Size(390, 2600),
        items: [
          testItem('Netflix', amount: 50, due: DateTime(2026, 10, 15)),
          testItem('Spotify', amount: 10),
        ],
      );
      await _openInsights(tester);

      await tester.tap(find.text('Netflix'));
      await settle(tester);

      expect(find.text('Mark as paid'), findsOneWidget); // the item screen
    });
  });
}
