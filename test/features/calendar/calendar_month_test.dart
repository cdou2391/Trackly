import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/calendar/application/calendar_month.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _today = DateTime(2026, 10, 9);
final _oct = DateTime(2026, 10);

RecurringItem item(
  String id, {
  double amount = 10,
  String currency = 'USD',
  required DateTime due,
  BillingFrequency frequency = BillingFrequency.monthly,
  ItemStatus status = ItemStatus.active,
  DateTime? trialEnd,
}) {
  return RecurringItem(
    id: id,
    name: id,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    startDate: DateTime(2026, 1, due.day),
    nextDueDate: due,
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    createdAt: _today,
    updatedAt: _today,
  );
}

Payment payment(
  RecurringItem of,
  DateTime due, {
  PaymentStatus status = PaymentStatus.paid,
  double? amount,
}) {
  return Payment(
    id: '${of.id}-$due',
    recurringItemId: of.id,
    amount: amount ?? of.amount,
    currencyCode: of.currencyCode,
    dueDate: due,
    paidDate: status == PaymentStatus.paid ? due : null,
    status: status,
    createdAt: _today,
  );
}

CalendarMonth build(
  List<RecurringItem> items, {
  List<Payment> payments = const [],
  DateTime? month,
}) => buildCalendarMonth(
  items: items,
  payments: payments,
  month: month ?? _oct,
  today: _today,
);

void main() {
  group('scheduled charges', () {
    test('an active item appears on its due date', () {
      final month = build([item('Netflix', due: DateTime(2026, 10, 15))]);
      expect(month.entries, hasLength(1));
      expect(month.entries.single.date, DateTime(2026, 10, 15));
      expect(month.entries.single.status, CalendarEntryStatus.due);
    });

    test('a month with no charge is empty', () {
      final month = build([
        item('Netflix', due: DateTime(2026, 10, 15)),
      ], month: DateTime(2026, 9));
      expect(month.entries, isEmpty);
    });

    test('future months are projected from the schedule', () {
      final month = build([
        item('Netflix', due: DateTime(2026, 10, 15)),
      ], month: DateTime(2027, 2));
      expect(month.entries.single.date, DateTime(2027, 2, 15));
    });

    test('a weekly item repeats within the month', () {
      final month = build([
        item(
          'Gym',
          due: DateTime(2026, 10, 2),
          frequency: BillingFrequency.weekly,
        ),
      ]);
      expect(month.entries.map((e) => e.date.day), [2, 9, 16, 23, 30]);
      expect(month.totalByCurrency['USD'], 50);
    });

    test('charges before today are overdue, today and later are due', () {
      final month = build([
        item('Past', due: DateTime(2026, 10, 3)),
        item('Today', due: DateTime(2026, 10, 9)),
        item('Later', due: DateTime(2026, 10, 20)),
      ]);
      final byName = {for (final e in month.entries) e.item.name: e.status};
      expect(byName['Past'], CalendarEntryStatus.overdue);
      expect(byName['Today'], CalendarEntryStatus.due);
      expect(byName['Later'], CalendarEntryStatus.due);
    });

    test('paused and cancelled items have no scheduled charges', () {
      final month = build([
        item('Paused', due: DateTime(2026, 10, 15), status: ItemStatus.paused),
        item(
          'Cancelled',
          due: DateTime(2026, 10, 16),
          status: ItemStatus.cancelled,
        ),
      ]);
      expect(month.entries, isEmpty);
    });

    test('entries are sorted by date, then name', () {
      final month = build([
        item('B', due: DateTime(2026, 10, 15)),
        item('A', due: DateTime(2026, 10, 15)),
        item('C', due: DateTime(2026, 10, 12)),
      ]);
      expect(month.entries.map((e) => e.item.name), ['C', 'A', 'B']);
    });

    test('entriesOn returns one day only', () {
      final month = build([
        item('A', due: DateTime(2026, 10, 15)),
        item('B', due: DateTime(2026, 10, 16)),
      ]);
      expect(month.entriesOn(DateTime(2026, 10, 15, 18)).single.item.name, 'A');
      expect(month.entriesOn(DateTime(2026, 10, 14)), isEmpty);
    });
  });

  group('recorded payments', () {
    test('a paid charge shows on the date it was due', () {
      final netflix = item('Netflix', due: DateTime(2026, 11, 3));
      final month = build(
        [netflix],
        payments: [payment(netflix, DateTime(2026, 10, 3))],
      );
      expect(month.entries, hasLength(1));
      expect(month.entries.single.status, CalendarEntryStatus.paid);
      expect(month.entries.single.date, DateTime(2026, 10, 3));
    });

    test('a skipped charge is shown but never counted', () {
      final netflix = item('Netflix', due: DateTime(2026, 11, 3));
      final month = build(
        [netflix],
        payments: [
          payment(
            netflix,
            DateTime(2026, 10, 3),
            status: PaymentStatus.skipped,
          ),
        ],
      );
      expect(month.entries.single.status, CalendarEntryStatus.skipped);
      expect(month.entries.single.countsInTotal, isFalse);
      expect(month.totalByCurrency, isEmpty);
    });

    test('the paid amount is used, not the current price', () {
      final netflix = item('Netflix', amount: 20, due: DateTime(2026, 11, 3));
      final month = build(
        [netflix],
        payments: [payment(netflix, DateTime(2026, 10, 3), amount: 15)],
      );
      expect(month.totalByCurrency['USD'], 15);
    });

    test('history of a cancelled item stays visible', () {
      final old = item(
        'Old',
        due: DateTime(2026, 11, 3),
        status: ItemStatus.cancelled,
      );
      final month = build(
        [old],
        payments: [payment(old, DateTime(2026, 10, 3))],
      );
      expect(month.entries.single.status, CalendarEntryStatus.paid);
    });

    test('payments outside the month or of deleted items are ignored', () {
      final netflix = item('Netflix', due: DateTime(2026, 12, 3));
      final ghost = item('Ghost', due: DateTime(2026, 12, 3));
      final month = build(
        [netflix],
        payments: [
          payment(netflix, DateTime(2026, 9, 3)),
          payment(ghost, DateTime(2026, 10, 3)),
        ],
      );
      expect(month.entries, isEmpty);
    });
  });

  group('totals', () {
    test('total counts paid and still-due charges together', () {
      final paid = item('Paid', amount: 15, due: DateTime(2026, 11, 3));
      final month = build(
        [paid, item('Later', amount: 10, due: DateTime(2026, 10, 20))],
        payments: [payment(paid, DateTime(2026, 10, 3))],
      );
      expect(month.totalByCurrency['USD'], 25);
    });

    test('left counts only open charges from the given day', () {
      final paid = item('Paid', amount: 15, due: DateTime(2026, 11, 3));
      final month = build(
        [
          paid,
          item('Past', amount: 5, due: DateTime(2026, 10, 5)),
          item('Soon', amount: 10, due: DateTime(2026, 10, 12)),
          item('End', amount: 7, due: DateTime(2026, 10, 31)),
        ],
        payments: [payment(paid, DateTime(2026, 10, 10))],
      );
      expect(month.leftFrom(DateTime(2026, 10, 9))['USD'], 17);
      expect(month.leftFrom(DateTime(2026, 10, 13))['USD'], 7);
      // From the 1st the overdue charge is included; paid ones never are.
      expect(month.leftFrom(DateTime(2026, 10, 1))['USD'], 22);
      expect(month.leftFrom(DateTime(2026, 11, 1)), isEmpty);
    });

    test('a charge on the chosen day is included in left', () {
      final month = build([item('A', amount: 4, due: DateTime(2026, 10, 12))]);
      expect(month.leftFrom(DateTime(2026, 10, 12))['USD'], 4);
    });

    test('currencies are never merged', () {
      final month = build([
        item('A', amount: 10, currency: 'USD', due: DateTime(2026, 10, 12)),
        item('B', amount: 30000, currency: 'RWF', due: DateTime(2026, 10, 14)),
        item('C', amount: 5, currency: 'USD', due: DateTime(2026, 10, 20)),
      ]);
      expect(month.totalByCurrency, {'USD': 15, 'RWF': 30000});
    });
  });

  group('free trials', () {
    test('a charge while the trial runs is shown but not counted', () {
      final month = build([
        item(
          'Canva',
          amount: 14.99,
          due: DateTime(2026, 10, 20),
          trialEnd: DateTime(2026, 10, 20),
        ),
      ]);
      expect(month.entries.single.countsInTotal, isFalse);
      expect(month.totalByCurrency, isEmpty);
      expect(month.leftFrom(DateTime(2026, 10, 1)), isEmpty);
    });

    test('charges after the trial has ended count normally', () {
      final month = build([
        item(
          'Canva',
          amount: 14.99,
          due: DateTime(2026, 10, 20),
          trialEnd: DateTime(2026, 10, 20),
        ),
      ], month: DateTime(2026, 11));
      expect(month.entries.single.date, DateTime(2026, 11, 20));
      expect(month.entries.single.countsInTotal, isTrue);
      expect(month.totalByCurrency['USD'], 14.99);
    });
  });
}
