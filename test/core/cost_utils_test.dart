import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/utils/cost_utils.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item({
  double amount = 10,
  String currency = 'USD',
  BillingFrequency frequency = BillingFrequency.monthly,
  int interval = 1,
  ItemStatus status = ItemStatus.active,
  bool isTrial = false,
  DateTime? trialEndDate,
}) {
  return RecurringItem(
    id: 'id',
    name: 'Test',
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    interval: interval,
    startDate: DateTime(2026, 1, 1),
    nextDueDate: DateTime(2026, 11, 1),
    status: status,
    isTrial: isTrial,
    trialEndDate: trialEndDate,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  group('monthly equivalent', () {
    test(r'$12 monthly -> $12/month', () {
      expect(calculateMonthlyEquivalent(item(amount: 12)), closeTo(12, 1e-9));
    });

    test(r'$120 yearly -> $10/month', () {
      expect(
        calculateMonthlyEquivalent(
            item(amount: 120, frequency: BillingFrequency.yearly)),
        closeTo(10, 1e-9),
      );
    });

    test(r'$30 quarterly -> $10/month', () {
      expect(
        calculateMonthlyEquivalent(
            item(amount: 30, frequency: BillingFrequency.quarterly)),
        closeTo(10, 1e-9),
      );
    });

    test(r'$60 semi-annual -> $10/month', () {
      expect(
        calculateMonthlyEquivalent(
            item(amount: 60, frequency: BillingFrequency.semiAnnual)),
        closeTo(10, 1e-9),
      );
    });

    test(r'$10 weekly -> about $43.33/month', () {
      expect(
        calculateMonthlyEquivalent(
            item(amount: 10, frequency: BillingFrequency.weekly)),
        closeTo(43.33, 0.01),
      );
    });

    test('every 2 months halves the monthly cost', () {
      expect(calculateMonthlyEquivalent(item(amount: 20, interval: 2)),
          closeTo(10, 1e-9));
    });

    test('every 2 weeks halves the weekly equivalent', () {
      expect(
        calculateMonthlyEquivalent(
            item(amount: 10, frequency: BillingFrequency.weekly, interval: 2)),
        closeTo(21.67, 0.01),
      );
    });

    test('custom every 30 days', () {
      expect(
        calculateMonthlyEquivalent(
            item(amount: 10, frequency: BillingFrequency.custom, interval: 30)),
        closeTo(10.14, 0.01),
      );
    });
  });

  test('annual equivalent is monthly x 12', () {
    expect(
      calculateAnnualEquivalent(
          item(amount: 7, frequency: BillingFrequency.quarterly)),
      closeTo(28, 1e-9),
    );
  });

  group('trials', () {
    test('trial ending in the future is in an active trial', () {
      final trial = item(isTrial: true, trialEndDate: DateTime(2026, 11, 15));
      expect(isInActiveTrial(trial, _now), isTrue);
    });

    test('the trial end date itself still counts as trial', () {
      final trial = item(isTrial: true, trialEndDate: DateTime(2026, 10, 9));
      expect(isInActiveTrial(trial, DateTime(2026, 10, 9, 18)), isTrue);
    });

    test('the day after the trial end it counts as a paid item', () {
      final trial = item(isTrial: true, trialEndDate: DateTime(2026, 10, 8));
      expect(isInActiveTrial(trial, _now), isFalse);
      expect(countsTowardTotals(trial, _now), isTrue);
    });

    test('a non-trial item is never in a trial', () {
      expect(isInActiveTrial(item(), _now), isFalse);
    });

    test('a trial without an end date is rejected', () {
      expect(() => item(isTrial: true), throwsA(isA<AssertionError>()));
    });
  });

  group('totals', () {
    test('only active, non-trial items count', () {
      final items = [
        item(amount: 10),
        item(amount: 100, status: ItemStatus.paused),
        item(amount: 100, status: ItemStatus.cancelled),
        item(
            amount: 100,
            isTrial: true,
            trialEndDate: DateTime(2026, 11, 15)),
      ];
      expect(monthlyTotalsByCurrency(items, now: _now), {'USD': 10});
    });

    test('currencies are grouped, never merged', () {
      final items = [
        item(amount: 15, currency: 'USD'),
        item(amount: 30000, currency: 'RWF'),
        item(amount: 8, currency: 'EUR'),
        item(amount: 5, currency: 'USD'),
      ];
      final totals = monthlyTotalsByCurrency(items, now: _now);
      expect(totals, {'USD': 20, 'RWF': 30000, 'EUR': 8});
    });

    test('yearly totals are monthly x 12', () {
      final items = [item(amount: 10)];
      expect(yearlyTotalsByCurrency(items, now: _now), {'USD': 120});
    });

    test('no items gives an empty map', () {
      expect(monthlyTotalsByCurrency(const [], now: _now), isEmpty);
    });
  });
}
