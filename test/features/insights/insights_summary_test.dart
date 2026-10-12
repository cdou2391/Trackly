import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/insights/application/insights_summary.dart';
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
}) {
  final nextDue = due ?? DateTime(2026, 10, 20);
  return RecurringItem(
    id: id,
    name: id,
    type: RecurringItemType.subscription,
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

InsightsSummary summarize(List<RecurringItem> items) =>
    buildInsightsSummary(items: items, now: _now);

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
}
