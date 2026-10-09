import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/utils/cost_utils.dart';
import 'package:trackly/features/subscriptions/application/subscription_creator.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

final _now = DateTime(2026, 10, 9, 12);

NewSubscription input({
  String name = 'Netflix',
  double amount = 15.49,
  BillingFrequency frequency = BillingFrequency.monthly,
  DateTime? startDate,
  RecurringItemType type = RecurringItemType.subscription,
  bool isTrial = false,
  DateTime? trialEndDate,
  String? notes,
}) {
  return NewSubscription(
    name: name,
    amount: amount,
    currencyCode: 'USD',
    frequency: frequency,
    startDate: startDate ?? DateTime(2026, 10, 9),
    entryMethod: EntryMethod.fullForm,
    type: type,
    isTrial: isTrial,
    trialEndDate: trialEndDate,
    notes: notes,
  );
}

void main() {
  group('buildRecurringItem', () {
    test('a monthly item started today is next due in a month', () {
      final item = buildRecurringItem(input(), id: 'a', now: _now);
      expect(item.startDate, DateTime(2026, 10, 9));
      expect(item.nextDueDate, DateTime(2026, 11, 9));
      expect(item.status, ItemStatus.active);
      expect(item.isTrial, isFalse);
      expect(item.trialEndDate, isNull);
    });

    test('a future start date is the next due date', () {
      final item = buildRecurringItem(
        input(startDate: DateTime(2026, 10, 20)),
        id: 'a',
        now: _now,
      );
      expect(item.nextDueDate, DateTime(2026, 10, 20));
    });

    test('trims the name and drops blank notes', () {
      final item = buildRecurringItem(
        input(name: '  Gym  ', notes: '   '),
        id: 'a',
        now: _now,
      );
      expect(item.name, 'Gym');
      expect(item.notes, isNull);
    });

    test('keeps non-blank notes trimmed', () {
      final item = buildRecurringItem(
        input(notes: ' family plan '),
        id: 'a',
        now: _now,
      );
      expect(item.notes, 'family plan');
    });

    test('keeps the type, amount and reminder settings', () {
      final item = buildRecurringItem(
        NewSubscription(
          name: 'Rent',
          amount: 500000,
          currencyCode: 'RWF',
          frequency: BillingFrequency.quarterly,
          startDate: DateTime(2026, 10, 1),
          entryMethod: EntryMethod.fullForm,
          type: RecurringItemType.bill,
          remindersEnabled: false,
          reminderDaysBefore: 7,
          categoryId: 'housing',
          logoKey: 'x',
        ),
        id: 'a',
        now: _now,
      );
      expect(item.type, RecurringItemType.bill);
      expect(item.currencyCode, 'RWF');
      expect(item.remindersEnabled, isFalse);
      expect(item.reminderDaysBefore, 7);
      expect(item.categoryId, 'housing');
      expect(item.logoKey, 'x');
      expect(item.nextDueDate, DateTime(2027, 1, 1));
    });

    group('free trials', () {
      test('the first charge is the day the trial ends', () {
        final item = buildRecurringItem(
          input(
            frequency: BillingFrequency.monthly,
            isTrial: true,
            trialEndDate: DateTime(2026, 11, 15),
          ),
          id: 'a',
          now: _now,
        );
        expect(item.isTrial, isTrue);
        expect(item.trialEndDate, DateTime(2026, 11, 15));
        expect(item.nextDueDate, DateTime(2026, 11, 15));
        // The billing anchor is the first charge, so later months keep the 15th.
        expect(item.startDate, DateTime(2026, 11, 15));
      });

      test('is excluded from totals until it ends', () {
        final item = buildRecurringItem(
          input(isTrial: true, trialEndDate: DateTime(2026, 11, 15)),
          id: 'a',
          now: _now,
        );
        expect(countsTowardTotals(item, _now), isFalse);
        expect(countsTowardTotals(item, DateTime(2026, 11, 16)), isTrue);
      });

      test('requires an end date', () {
        expect(
          () => buildRecurringItem(input(isTrial: true), id: 'a', now: _now),
          throwsArgumentError,
        );
      });

      test('an end date is ignored when it is not a trial', () {
        final item = buildRecurringItem(
          input(trialEndDate: DateTime(2026, 11, 15)),
          id: 'a',
          now: _now,
        );
        expect(item.isTrial, isFalse);
        expect(item.trialEndDate, isNull);
        expect(item.nextDueDate, DateTime(2026, 11, 9));
      });
    });
  });

  test('entry methods map to the analytics values', () {
    expect(EntryMethod.quickAdd.analyticsValue, 'quick_add');
    expect(EntryMethod.fullForm.analyticsValue, 'full_form');
  });
}
