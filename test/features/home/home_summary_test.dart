import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/home/application/home_summary.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item(
  String id, {
  double amount = 10,
  String currency = 'USD',
  DateTime? due,
  ItemStatus status = ItemStatus.active,
  DateTime? trialEnd,
  String? name,
}) {
  return RecurringItem(
    id: id,
    name: name ?? id,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: BillingFrequency.monthly,
    startDate: DateTime(2026, 1, 1),
    nextDueDate: due ?? DateTime(2026, 10, 20),
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    createdAt: _now,
    updatedAt: _now,
  );
}

HomeSummary summarize(List<RecurringItem> items,
        [List<Payment> paid = const []]) =>
    buildHomeSummary(items: items, recentPaid: paid, now: _now);

void main() {
  test('empty input has no items', () {
    final summary = summarize(const []);
    expect(summary.hasItems, isFalse);
    expect(summary.activeCount + summary.trialCount + summary.cancelledCount, 0);
    expect(summary.upcoming, isEmpty);
    expect(summary.monthlyTotalsByCurrency, isEmpty);
  });

  group('status counts', () {
    test('trials count only in Trial, paused counts in Active', () {
      final summary = summarize([
        item('active'),
        item('paused', status: ItemStatus.paused),
        item('trial', trialEnd: DateTime(2026, 11, 15)),
        item('cancelled', status: ItemStatus.cancelled),
      ]);
      expect(summary.activeCount, 2);
      expect(summary.trialCount, 1);
      expect(summary.cancelledCount, 1);
    });

    test('an ended trial counts as Active', () {
      final summary =
          summarize([item('t', trialEnd: DateTime(2026, 10, 1))]);
      expect(summary.trialCount, 0);
      expect(summary.activeCount, 1);
    });

    test('a paused trial counts as Active, not Trial', () {
      final summary = summarize([
        item('t', status: ItemStatus.paused, trialEnd: DateTime(2026, 11, 15)),
      ]);
      expect(summary.trialCount, 0);
      expect(summary.activeCount, 1);
    });
  });

  group('totals', () {
    test('exclude trials, paused and cancelled', () {
      final summary = summarize([
        item('a', amount: 10),
        item('b', amount: 5),
        item('trial', amount: 100, trialEnd: DateTime(2026, 11, 15)),
        item('paused', amount: 100, status: ItemStatus.paused),
        item('cancelled', amount: 100, status: ItemStatus.cancelled),
      ]);
      expect(summary.monthlyTotalsByCurrency, {'USD': 15});
      expect(summary.yearlyTotalsByCurrency, {'USD': 180});
    });

    test('currencies stay separate', () {
      final summary = summarize([
        item('a', currency: 'USD'),
        item('b', currency: 'RWF', amount: 30000),
      ]);
      expect(summary.monthlyTotalsByCurrency, {'USD': 10, 'RWF': 30000});
    });
  });

  group('upcoming', () {
    test('is the next 5 active items within a month, soonest first', () {
      final items = [
        for (var i = 0; i < 8; i++)
          item('i$i', due: DateTime(2026, 10, 10 + i * 2)),
      ];
      final summary = summarize(items);
      expect([for (final i in summary.upcoming) i.id],
          ['i0', 'i1', 'i2', 'i3', 'i4']);
    });

    test('includes the same day next month but not the day after', () {
      final summary = summarize([
        item('in', due: DateTime(2026, 11, 9)),
        item('out', due: DateTime(2026, 11, 10)),
      ]);
      expect([for (final i in summary.upcoming) i.id], ['in']);
    });

    test('keeps overdue items and puts them first', () {
      final summary = summarize([
        item('later', due: DateTime(2026, 10, 15)),
        item('overdue', due: DateTime(2026, 10, 5)),
      ]);
      expect([for (final i in summary.upcoming) i.id], ['overdue', 'later']);
    });

    test('excludes paused and cancelled', () {
      final summary = summarize([
        item('p', status: ItemStatus.paused),
        item('c', status: ItemStatus.cancelled),
        item('a'),
      ]);
      expect([for (final i in summary.upcoming) i.id], ['a']);
    });

    test('includes a running trial', () {
      final summary =
          summarize([item('t', trialEnd: DateTime(2026, 11, 15))]);
      expect(summary.upcoming, hasLength(1));
    });

    test('ties on date sort by name', () {
      final summary = summarize([
        item('2', name: 'Zed', due: DateTime(2026, 10, 12)),
        item('1', name: 'Alpha', due: DateTime(2026, 10, 12)),
      ]);
      expect([for (final i in summary.upcoming) i.name], ['Alpha', 'Zed']);
    });
  });

  group('recent payments', () {
    Payment paid(String id, String itemId) => Payment(
          id: id,
          recurringItemId: itemId,
          amount: 9,
          currencyCode: 'USD',
          dueDate: DateTime(2026, 10, 2),
          paidDate: DateTime(2026, 10, 2),
          status: PaymentStatus.paid,
          createdAt: _now,
        );

    test('are joined with their item', () {
      final summary = summarize([item('a', name: 'Netflix')], [paid('p', 'a')]);
      expect(summary.recentPayments.single.item.name, 'Netflix');
    });

    test('drop payments whose item is missing', () {
      final summary = summarize([item('a')], [paid('p', 'ghost')]);
      expect(summary.recentPayments, isEmpty);
    });
  });
}
