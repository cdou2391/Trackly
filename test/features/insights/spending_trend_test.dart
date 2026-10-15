import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/calendar/application/calendar_month.dart';
import 'package:trackly/features/insights/application/spending_trend.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item(
  String id, {
  double amount = 10,
  String currency = 'USD',
  DateTime? due,
  DateTime? trialEnd,
}) {
  final nextDue = due ?? DateTime(2026, 10, 20);
  return RecurringItem(
    id: id,
    name: id,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: BillingFrequency.monthly,
    startDate: DateTime(2026, 1, nextDue.day),
    nextDueDate: nextDue,
    status: ItemStatus.active,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    createdAt: _now,
    updatedAt: _now,
  );
}

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

SpendingTrend trend(
  List<RecurringItem> items,
  List<Payment> payments, {
  int months = 6,
}) => buildSpendingTrend(
  items: items,
  payments: payments,
  now: _now,
  months: months,
);

void main() {
  group('buildSpendingTrend', () {
    test('has one point per month, oldest first, ending this month', () {
      final result = trend(
        [item('Netflix', due: DateTime(2026, 11, 5))],
        [
          paid('Netflix', DateTime(2026, 5, 5), amount: 15),
          paid('Netflix', DateTime(2026, 9, 5), amount: 20),
        ],
      );

      final points = result.byCurrency['USD']!;
      expect(points.map((p) => p.month), [
        for (var m = 5; m <= 10; m++) DateTime(2026, m),
      ]);
      expect(points.map((p) => p.amount), [15, 0, 0, 0, 20, 0]);
    });

    test('crosses a year boundary', () {
      final result = buildSpendingTrend(
        items: [item('Netflix', due: DateTime(2027, 2, 5))],
        payments: [
          paid('Netflix', DateTime(2026, 12, 5)),
          paid('Netflix', DateTime(2027, 1, 5)),
        ],
        now: DateTime(2027, 2, 9),
        months: 3,
      );

      expect(result.byCurrency['USD']!.map((p) => p.month), [
        DateTime(2026, 12),
        DateTime(2027, 1),
        DateTime(2027, 2),
      ]);
    });

    test('the range sets how many months it covers', () {
      final items = [item('Netflix')];
      for (final months in trendRanges) {
        final result = trend(items, const [], months: months);
        expect(result.byCurrency['USD']!, hasLength(months));
      }
    });

    test('never merges currencies', () {
      final result = trend(
        [
          item('Netflix', due: DateTime(2026, 11, 5)),
          item('Canva', currency: 'EUR', due: DateTime(2026, 11, 5)),
        ],
        [
          paid('Netflix', DateTime(2026, 8, 5), amount: 15),
          paid('Netflix', DateTime(2026, 9, 5), amount: 15),
          paid('Canva', DateTime(2026, 8, 5), amount: 12, currency: 'EUR'),
          paid('Canva', DateTime(2026, 9, 5), amount: 12, currency: 'EUR'),
        ],
      );

      expect(result.byCurrency.keys, containsAll(['USD', 'EUR']));
      expect(result.byCurrency['USD']![3].amount, 15);
      expect(result.byCurrency['EUR']![3].amount, 12);
      expect(result.chartableCurrencies, ['EUR', 'USD']);
    });

    test('skipped charges do not count', () {
      final result = trend(
        [item('Netflix', due: DateTime(2026, 11, 5))],
        [
          paid('Netflix', DateTime(2026, 8, 5), amount: 15),
          paid(
            'Netflix',
            DateTime(2026, 9, 5),
            amount: 15,
            status: PaymentStatus.skipped,
          ),
        ],
      );

      expect(result.byCurrency['USD']![3].amount, 15);
      expect(result.byCurrency['USD']![4].amount, 0);
    });

    test('a charge still to come during a free trial does not count', () {
      final result = trend(
        [
          item('Netflix', amount: 15, due: DateTime(2026, 10, 20)),
          item(
            'Hulu',
            amount: 8,
            due: DateTime(2026, 10, 22),
            trialEnd: DateTime(2026, 10, 25),
          ),
        ],
        [
          paid('Netflix', DateTime(2026, 8, 20), amount: 15),
          paid('Netflix', DateTime(2026, 9, 20), amount: 15),
        ],
      );

      // This month holds Netflix's $15 still to pay, not Hulu's trial charge.
      expect(result.byCurrency['USD']!.last.amount, 15);
    });

    test('a payment already recorded counts, even from a trial', () {
      final result = trend(
        [
          item(
            'Hulu',
            due: DateTime(2026, 11, 5),
            trialEnd: DateTime(2026, 9, 20),
          ),
        ],
        [
          paid('Hulu', DateTime(2026, 8, 5), amount: 8),
          paid('Hulu', DateTime(2026, 9, 5), amount: 8),
        ],
      );

      expect(result.byCurrency['USD']![3].amount, 8);
      expect(result.byCurrency['USD']![4].amount, 8);
    });

    test('each month is the Calendar total for that month', () {
      final items = [
        item('Netflix', amount: 15, due: DateTime(2026, 10, 20)),
        item('Spotify', amount: 10, due: DateTime(2026, 11, 10)),
      ];
      final payments = [
        paid('Netflix', DateTime(2026, 9, 20), amount: 15),
        paid('Spotify', DateTime(2026, 10, 5), amount: 10),
      ];

      final result = trend(items, payments);
      final calendar = buildCalendarMonth(
        items: items,
        payments: payments,
        month: DateTime(2026, 10),
        today: _now,
      ).totalByCurrency;

      // Paid $10 plus the $15 still to pay this month.
      expect(result.byCurrency['USD']!.last.amount, 25);
      expect(result.byCurrency['USD']!.last.amount, calendar['USD']);
    });

    test('has nothing with no items or payments', () {
      final result = trend(const [], const []);

      expect(result.byCurrency, isEmpty);
      expect(result.chartableCurrencies, isEmpty);
    });
  });

  group('isWorthDrawing', () {
    List<TrendPoint> points(List<double> amounts) => [
      for (final (i, a) in amounts.indexed)
        TrendPoint(month: DateTime(2026, 5 + i), amount: a),
    ];

    test('needs two months with something in them', () {
      expect(SpendingTrend.isWorthDrawing(points([0, 0, 0])), isFalse);
      expect(SpendingTrend.isWorthDrawing(points([0, 12, 0])), isFalse);
      expect(SpendingTrend.isWorthDrawing(points([0, 12, 0, 9])), isTrue);
    });

    test('a gap between two months still draws', () {
      expect(SpendingTrend.isWorthDrawing(points([5, 0, 0, 7])), isTrue);
    });
  });
}
