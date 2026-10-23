import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/insights/application/insights_summary.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item(
  String id, {
  double amount = 10,
  String currency = 'USD',
  DateTime? due,
  BillingFrequency frequency = BillingFrequency.monthly,
  ItemStatus status = ItemStatus.active,
  DateTime? trialEnd,
  String? categoryId,
  RecurringItemType type = RecurringItemType.subscription,
}) {
  final nextDue = due ?? DateTime(2026, 10, 20);
  return RecurringItem(
    id: id,
    name: id,
    type: type,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    startDate: DateTime(2026, 1, nextDue.day),
    nextDueDate: nextDue,
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    categoryId: categoryId,
    createdAt: _now,
    updatedAt: _now,
  );
}

InsightsSummary summarize(
  List<RecurringItem> items, {
  List<Payment> payments = const [],
}) => buildInsightsSummary(items: items, payments: payments, now: _now);

Payment paid(
  String itemId,
  DateTime due, {
  double amount = 10,
  String currency = 'USD',
  PaymentStatus status = PaymentStatus.paid,
}) => Payment(
  id: '$itemId-${due.toIso8601String()}',
  recurringItemId: itemId,
  amount: amount,
  currencyCode: currency,
  dueDate: due,
  paidDate: status == PaymentStatus.paid ? due : null,
  status: status,
  createdAt: _now,
);

void main() {
  test('empty input has no items', () {
    final summary = summarize(const []);
    expect(summary.hasItems, isFalse);
    expect(summary.activeCount + summary.trialCount + summary.upcomingCount, 0);
    expect(summary.categoryBreakdown, isEmpty);
    expect(summary.monthlyTotalsByCurrency, isEmpty);
  });

  group('counts', () {
    test('active excludes paused, cancelled and trials', () {
      final summary = summarize([
        item('a'),
        item('paused', status: ItemStatus.paused),
        item('cancelled', status: ItemStatus.cancelled),
        item('trial', trialEnd: DateTime(2026, 11, 15)),
      ]);
      expect(summary.activeCount, 1);
      expect(summary.trialCount, 1);
    });

    test('an ended trial is a normal active item', () {
      final summary = summarize([item('t', trialEnd: DateTime(2026, 10, 1))]);
      expect(summary.activeCount, 1);
      expect(summary.trialCount, 0);
    });
  });

  group('totals', () {
    test('monthly and yearly use the normalised cost', () {
      final summary = summarize([
        item('monthly', amount: 12),
        item('yearly', amount: 120, frequency: BillingFrequency.yearly),
      ]);
      expect(summary.monthlyTotalsByCurrency['USD'], closeTo(22, 1e-9));
      expect(summary.yearlyTotalsByCurrency['USD'], closeTo(264, 1e-9));
    });

    test('paused, cancelled and trial items are left out', () {
      final summary = summarize([
        item('a', amount: 10),
        item('p', amount: 99, status: ItemStatus.paused),
        item('c', amount: 99, status: ItemStatus.cancelled),
        item('t', amount: 99, trialEnd: DateTime(2026, 11, 15)),
      ]);
      expect(summary.monthlyTotalsByCurrency, {'USD': 10});
    });
  });

  group('category breakdown', () {
    test('groups by category and sorts the largest first', () {
      final summary = summarize([
        item('a', amount: 10, categoryId: 'software'),
        item('b', amount: 30, categoryId: 'entertainment'),
        item('c', amount: 5, categoryId: 'software'),
      ]);
      final rows = summary.categoryBreakdown['USD']!;
      expect(rows.map((r) => r.categoryId), ['entertainment', 'software']);
      expect(rows[0].monthlyAmount, 30);
      expect(rows[1].monthlyAmount, 15);
      expect(rows[1].count, 2);
    });

    test('items without a category are grouped as Other', () {
      final summary = summarize([
        item('a', amount: 10),
        item('b', amount: 5, categoryId: 'other'),
      ]);
      final rows = summary.categoryBreakdown['USD']!;
      expect(rows, hasLength(1));
      expect(rows.single.categoryId, uncategorizedId);
      expect(rows.single.monthlyAmount, 15);
    });

    test('currencies get separate breakdowns and are never merged', () {
      final summary = summarize([
        item('a', amount: 10, categoryId: 'software'),
        item('b', amount: 30000, currency: 'RWF', categoryId: 'software'),
      ]);
      expect(summary.categoryBreakdown.keys, containsAll(['USD', 'RWF']));
      expect(summary.categoryBreakdown['USD']!.single.monthlyAmount, 10);
      expect(summary.categoryBreakdown['RWF']!.single.monthlyAmount, 30000);
    });

    test('trials and inactive items are not in the breakdown', () {
      final summary = summarize([
        item('t', trialEnd: DateTime(2026, 11, 15), categoryId: 'software'),
        item('p', status: ItemStatus.paused, categoryId: 'software'),
      ]);
      expect(summary.categoryBreakdown, isEmpty);
    });

    test('ties are ordered by category id so the list is stable', () {
      final summary = summarize([
        item('a', amount: 10, categoryId: 'software'),
        item('b', amount: 10, categoryId: 'health'),
      ]);
      expect(summary.categoryBreakdown['USD']!.map((r) => r.categoryId), [
        'health',
        'software',
      ]);
    });
  });

  group('upcoming', () {
    test('counts charges from today to one calendar month ahead', () {
      final summary = summarize([
        item(
          'today',
          due: DateTime(2026, 10, 9),
          frequency: BillingFrequency.yearly,
        ),
        item(
          'inside',
          due: DateTime(2026, 11, 9),
          frequency: BillingFrequency.yearly,
        ),
        item(
          'outside',
          due: DateTime(2026, 11, 10),
          frequency: BillingFrequency.yearly,
        ),
      ]);
      expect(summary.upcomingCount, 2);
    });

    test('a monthly item due today counts twice: today and in a month', () {
      // The window is inclusive at both ends, like the Home Upcoming list.
      final summary = summarize([item('m', due: DateTime(2026, 10, 9))]);
      expect(summary.upcomingCount, 2);
    });

    test('is not capped at five like the Home list', () {
      final summary = summarize([
        for (var i = 0; i < 8; i++) item('i$i', due: DateTime(2026, 10, 12)),
      ]);
      expect(summary.upcomingCount, 8);
    });

    test('a weekly item counts every repeat', () {
      final summary = summarize([
        item(
          'gym',
          due: DateTime(2026, 10, 10),
          frequency: BillingFrequency.weekly,
        ),
      ]);
      // 10, 17, 24, 31 Oct and 7 Nov.
      expect(summary.upcomingCount, 5);
    });

    test('an overdue item counts once, as on Home', () {
      final summary = summarize([item('late', due: DateTime(2026, 9, 1))]);
      // The overdue 1 Sep, plus the next real occurrence 1 Nov.
      expect(summary.upcomingCount, 2);
    });

    test('a trial first charge counts, paused and cancelled do not', () {
      final summary = summarize([
        item(
          'trial',
          due: DateTime(2026, 10, 20),
          trialEnd: DateTime(2026, 10, 20),
        ),
        item('paused', status: ItemStatus.paused),
        item('cancelled', status: ItemStatus.cancelled),
      ]);
      expect(summary.upcomingCount, 1);
    });
  });

  group('subscriptions and bills', () {
    test('splits the monthly cost by type, largest first', () {
      final summary = summarize([
        item('Netflix', amount: 15),
        item('Spotify', amount: 10),
        item('Rent', amount: 500, type: RecurringItemType.bill),
        item('Trial', trialEnd: DateTime(2026, 11, 15), amount: 99),
        item('Paused', status: ItemStatus.paused, amount: 99),
      ]);
      final types = summary.typeBreakdown['USD']!;
      expect(types.map((t) => t.type), [
        RecurringItemType.bill,
        RecurringItemType.subscription,
      ]);
      expect(types.map((t) => t.monthlyAmount), [500, 25]);
      expect(types.map((t) => t.count), [1, 2]);
    });

    test('one type alone is a single entry', () {
      final summary = summarize([item('a'), item('b')]);
      expect(
        summary.typeBreakdown['USD']!.single.type,
        RecurringItemType.subscription,
      );
    });

    test('currencies are never merged', () {
      final summary = summarize([
        item('a', amount: 10),
        item('b', amount: 5000, currency: 'RWF', type: RecurringItemType.bill),
      ]);
      expect(summary.typeBreakdown.keys.toSet(), {'USD', 'RWF'});
      expect(summary.typeBreakdown['RWF']!.single.monthlyAmount, 5000);
    });
  });

  group('biggest costs', () {
    test('ranks by monthly equivalent, so a yearly item counts by month', () {
      final summary = summarize([
        item('Small', amount: 5),
        item('Yearly', amount: 240, frequency: BillingFrequency.yearly), // 20
        item('Medium', amount: 15),
      ]);
      expect(summary.biggestCosts['USD']!.map((c) => c.item.id), [
        'Yearly',
        'Medium',
        'Small',
      ]);
      expect(summary.biggestCosts['USD']!.first.monthlyAmount, 20);
    });

    test('keeps at most five per currency', () {
      final summary = summarize([
        for (var i = 1; i <= 7; i++) item('item$i', amount: i * 10),
      ]);
      final list = summary.biggestCosts['USD']!;
      expect(list, hasLength(biggestCostsLimit));
      expect(list.map((c) => c.item.id), [
        'item7',
        'item6',
        'item5',
        'item4',
        'item3',
      ]);
    });

    test('a tie is broken by name', () {
      final summary = summarize([
        item('beta', amount: 10),
        item('Alpha', amount: 10),
      ]);
      expect(summary.biggestCosts['USD']!.map((c) => c.item.id), [
        'Alpha',
        'beta',
      ]);
    });

    test('trials, paused and cancelled items are not ranked', () {
      final summary = summarize([
        item('a', amount: 10),
        item('b', amount: 20),
        item('trial', amount: 999, trialEnd: DateTime(2026, 11, 15)),
        item('paused', amount: 999, status: ItemStatus.paused),
        item('cancelled', amount: 999, status: ItemStatus.cancelled),
      ]);
      expect(summary.biggestCosts['USD']!.map((c) => c.item.id), ['b', 'a']);
    });

    test('a currency with one item has nothing to rank', () {
      final summary = summarize([
        item('a', amount: 10),
        item('b', amount: 20),
        item('solo', amount: 9000, currency: 'RWF'),
      ]);
      expect(summary.biggestCosts.keys, ['USD']);
    });
  });

  group('paid this month', () {
    test(
      'compares what was paid with the month total, as the Calendar does',
      () {
        final summary = summarize(
          [
            item('Netflix', amount: 15, due: DateTime(2026, 10, 20)),
            item('Spotify', amount: 10, due: DateTime(2026, 11, 10)),
          ],
          payments: [paid('Spotify', DateTime(2026, 10, 5))],
        );
        final progress = summary.monthProgress['USD']!;
        expect(progress.paid, 10);
        expect(progress.total, 25); // Netflix on the 20th + Spotify paid
      },
    );

    test('nothing recorded is zero paid', () {
      final summary = summarize([item('Netflix', amount: 15)]);
      expect(summary.monthProgress['USD']!.paid, 0);
      expect(summary.monthProgress['USD']!.total, 15);
    });

    test('a skipped charge is neither paid nor part of the total', () {
      final summary = summarize(
        [item('Netflix', amount: 15, due: DateTime(2026, 10, 20))],
        payments: [
          paid('Netflix', DateTime(2026, 10, 5), status: PaymentStatus.skipped),
        ],
      );
      final progress = summary.monthProgress['USD']!;
      expect(progress.paid, 0);
      expect(progress.total, 15);
    });

    test('payments from other months are ignored', () {
      final summary = summarize(
        [item('Netflix', amount: 15, due: DateTime(2026, 10, 20))],
        payments: [paid('Netflix', DateTime(2026, 9, 20), amount: 15)],
      );
      expect(summary.monthProgress['USD']!.paid, 0);
    });

    test('is empty when nothing is due this month', () {
      final summary = summarize([
        item(
          'Yearly',
          amount: 100,
          frequency: BillingFrequency.yearly,
          due: DateTime(2027, 3, 1),
        ),
      ]);
      expect(summary.monthProgress, isEmpty);
    });

    test('currencies are never merged', () {
      final summary = summarize(
        [
          item('a', amount: 10, due: DateTime(2026, 10, 20)),
          item('b', amount: 5000, currency: 'RWF', due: DateTime(2026, 10, 21)),
        ],
        payments: [
          paid('b', DateTime(2026, 10, 3), amount: 5000, currency: 'RWF'),
        ],
      );
      expect(summary.monthProgress['USD']!.paid, 0);
      expect(summary.monthProgress['RWF']!.paid, 5000);
    });
  });

  group('weekly buckets (for the bar chart)', () {
    test('cut October into 1-7, 8-14, 15-21, 22-28 and 29-31', () {
      final summary = summarize([item('A', due: DateTime(2026, 10, 12))]);
      final weeks = summary.monthProgress['USD']!.weeks;
      expect(
        [for (final w in weeks) (w.startDay, w.endDay)],
        [(1, 7), (8, 14), (15, 21), (22, 28), (29, 31)],
      );
    });

    test('put each charge in the week it falls in', () {
      final summary = summarize([
        item('A', amount: 10, due: DateTime(2026, 10, 3)),
        item('B', amount: 20, due: DateTime(2026, 10, 14)),
        item('C', amount: 30, due: DateTime(2026, 10, 15)),
        item('D', amount: 5, due: DateTime(2026, 10, 30)),
      ]);
      final totals = [
        for (final w in summary.monthProgress['USD']!.weeks) w.total,
      ];
      expect(totals, [10, 20, 30, 0, 5]);
    });

    test('count a recorded payment as paid in its week', () {
      final summary = summarize(
        [item('A', amount: 10, due: DateTime(2026, 11, 3))],
        payments: [paid('A', DateTime(2026, 10, 5), amount: 10)],
      );
      // Paid on 5 Oct, so the first week shows 10 paid.
      final first = summary.monthProgress['USD']!.weeks.first;
      expect(first.paid, 10);
      expect(summary.monthProgress['USD']!.paid, 10);
    });

    test('weeks add up to the month total', () {
      final summary = summarize([
        item('A', amount: 12.5, due: DateTime(2026, 10, 2)),
        item('B', amount: 7.25, due: DateTime(2026, 10, 19)),
        item('C', amount: 3, due: DateTime(2026, 10, 31)),
      ]);
      final progress = summary.monthProgress['USD']!;
      final sum = progress.weeks.fold<double>(0, (a, w) => a + w.total);
      expect(sum, closeTo(progress.total, 0.0001));
    });

    test('a short month ends its last week on its last day', () {
      final feb = buildInsightsSummary(
        items: [item('A', due: DateTime(2027, 2, 10))],
        now: DateTime(2027, 2, 9),
      );
      final weeks = feb.monthProgress['USD']!.weeks;
      expect(weeks.last.endDay, 28);
      expect(weeks, hasLength(4));
    });
  });
}
