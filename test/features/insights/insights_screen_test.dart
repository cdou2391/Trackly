import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/features/insights/presentation/spending_trend_card.dart';
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

  tracklyTest('the count cards put the figure beside the icon, like Home', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: const Size(390, 1800),
      items: [testItem('Netflix', due: DateTime(2026, 10, 12))],
    );
    await _openInsights(tester);

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Charges ahead'), findsNothing);
    for (final (icon, label) in [
      (Icons.check_circle_outline_rounded, 'Active'),
      (Icons.hourglass_bottom_rounded, 'Trial'),
      (Icons.event_rounded, 'Upcoming'),
    ]) {
      final iconBox = tester.getRect(find.byIcon(icon));
      final labelBox = tester.getRect(find.text(label));
      expect(labelBox.left, greaterThan(iconBox.right), reason: label);
    }
    // No chevron: these cards do not open anything.
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
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

  group('spending trend', () {
    // Payments go in as one transaction: separate inserts stall Drift's
    // fake-async timers while a screen is listening.
    Future<void> addPayments(
      WidgetTester tester,
      dynamic db,
      List<Payment> payments,
    ) => tester.runAsync(
      () => db.transaction(() async {
        for (final payment in payments) {
          await db.paymentsDao.insertPayment(payment);
        }
      }),
    );

    Payment paidIn(
      int month,
      double amount, {
      String item = 'Netflix',
      String currency = 'USD',
    }) => Payment(
      id: '$item-$month',
      recurringItemId: item,
      amount: amount,
      currencyCode: currency,
      dueDate: DateTime(2026, month, 5),
      paidDate: DateTime(2026, month, 5),
      status: PaymentStatus.paid,
      createdAt: testNow,
    );

    final summary = RegExp(r'^Spending trend, last (\d+) months');

    int monthsShown(WidgetTester tester) {
      final label = find
          .bySemanticsLabel(summary)
          .evaluate()
          .first
          .renderObject!
          .debugSemantics!
          .label;
      return int.parse(summary.firstMatch(label)!.group(1)!);
    }

    tracklyTest('says when there is not enough to draw yet', (tester) async {
      await pumpTrackly(tester, size: _tall, items: [testItem('Netflix')]);
      await _openInsights(tester);

      expect(find.text('Spending trend'), findsOneWidget);
      expect(
        find.text(
          'Your trend appears once two months have payments or charges.',
        ),
        findsOneWidget,
      );
      expect(find.text('6M'), findsNothing);
    });

    tracklyTest('draws a line once two months have something in them', (
      tester,
    ) async {
      final db = await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix', amount: 15)],
      );
      await addPayments(tester, db, [paidIn(8, 15), paidIn(9, 15)]);
      await _openInsights(tester);

      expect(find.text('Spending trend'), findsOneWidget);
      expect(find.text('3M'), findsOneWidget);
      expect(find.text('6M'), findsOneWidget);
      expect(find.text('1Y'), findsOneWidget);
      expect(monthsShown(tester), 6);
      expect(
        find.bySemanticsLabel(RegExp(r'Aug \$15\.00, Sep \$15\.00')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Past months show what you paid. This month also includes charges still to pay.',
        ),
        findsOneWidget,
      );
    });

    tracklyTest('the range buttons change how many months show', (
      tester,
    ) async {
      final db = await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix', amount: 15)],
      );
      await addPayments(tester, db, [paidIn(8, 15), paidIn(9, 15)]);
      await _openInsights(tester);

      await tester.tap(find.text('1Y'));
      await settle(tester);
      expect(monthsShown(tester), 12);

      await tester.tap(find.text('3M'));
      await settle(tester);
      expect(monthsShown(tester), 3);
    });

    tracklyTest('tapping along the line picks the nearest month', (
      tester,
    ) async {
      final db = await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix', amount: 15)],
      );
      await addPayments(tester, db, [paidIn(8, 15), paidIn(9, 30)]);
      await _openInsights(tester);

      int? selected() {
        final chart = find.descendant(
          of: find.byType(TrendChart),
          matching: find.byType(CustomPaint),
        );
        return (tester.widget<CustomPaint>(chart.first).painter! as dynamic)
                .selected
            as int?;
      }

      expect(selected(), isNull);

      final box = tester.getRect(find.byType(TrendChart));
      // Six months across the plot: the first sits at the left padding.
      await tester.tapAt(Offset(box.left + 20, box.center.dy));
      await tester.pump();
      expect(selected(), 0);

      await tester.tapAt(Offset(box.right - 20, box.center.dy));
      await tester.pump();
      expect(selected(), 5);
    });

    tracklyTest('one chart per currency, labelled', (tester) async {
      final db = await pumpTrackly(
        tester,
        size: const Size(390, 2400),
        items: [
          testItem('Netflix', amount: 15),
          testItem('Canva', amount: 12, currency: 'EUR'),
        ],
      );
      await addPayments(tester, db, [
        paidIn(8, 15),
        paidIn(9, 15),
        paidIn(8, 12, item: 'Canva', currency: 'EUR'),
        paidIn(9, 12, item: 'Canva', currency: 'EUR'),
      ]);
      await _openInsights(tester);

      expect(find.byType(TrendChart), findsNWidgets(2));
      expect(find.bySemanticsLabel(summary), findsNWidgets(2));
    });

    tracklyTest('fits a narrow screen with large text', (tester) async {
      final db = await pumpTrackly(
        tester,
        size: const Size(320, 2600),
        textScale: 2.0,
        items: [testItem('Netflix', amount: 15)],
      );
      await addPayments(tester, db, [
        for (var m = 1; m <= 10; m++) paidIn(m, 10.0 + m),
      ]);
      await _openInsights(tester);
      await tester.tap(find.text('1Y'));
      await settle(tester);

      expect(find.byType(TrendChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
