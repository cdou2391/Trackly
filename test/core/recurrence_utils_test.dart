import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/utils/recurrence_utils.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

DateTime next(
  DateTime from,
  BillingFrequency frequency, {
  int interval = 1,
  int? anchorDay,
}) => calculateNextDueDate(
  fromDate: from,
  frequency: frequency,
  interval: interval,
  anchorDay: anchorDay,
);

void main() {
  group('monthly', () {
    test('15 Oct -> 15 Nov', () {
      expect(
        next(DateTime(2026, 10, 15), BillingFrequency.monthly),
        DateTime(2026, 11, 15),
      );
    });

    test('rolls over the year', () {
      expect(
        next(DateTime(2026, 12, 15), BillingFrequency.monthly),
        DateTime(2027, 1, 15),
      );
    });

    test('31 Jan -> 28 Feb in a normal year', () {
      expect(
        next(DateTime(2026, 1, 31), BillingFrequency.monthly),
        DateTime(2026, 2, 28),
      );
    });

    test('31 Jan -> 29 Feb in a leap year', () {
      expect(
        next(DateTime(2028, 1, 31), BillingFrequency.monthly),
        DateTime(2028, 2, 29),
      );
    });

    test('31 Mar -> 30 Apr', () {
      expect(
        next(DateTime(2026, 3, 31), BillingFrequency.monthly),
        DateTime(2026, 4, 30),
      );
    });

    test('without an anchor, a clamped date keeps drifting', () {
      final feb = next(DateTime(2026, 1, 31), BillingFrequency.monthly);
      expect(next(feb, BillingFrequency.monthly), DateTime(2026, 3, 28));
    });

    test('with the start day as anchor, the schedule recovers to the 31st', () {
      final feb = next(
        DateTime(2026, 1, 31),
        BillingFrequency.monthly,
        anchorDay: 31,
      );
      final mar = next(feb, BillingFrequency.monthly, anchorDay: 31);
      final apr = next(mar, BillingFrequency.monthly, anchorDay: 31);
      expect(feb, DateTime(2026, 2, 28));
      expect(mar, DateTime(2026, 3, 31));
      expect(apr, DateTime(2026, 4, 30));
    });

    test('every 2 months', () {
      expect(
        next(DateTime(2026, 10, 15), BillingFrequency.monthly, interval: 2),
        DateTime(2026, 12, 15),
      );
    });

    test('ignores time of day', () {
      expect(
        next(DateTime(2026, 10, 15, 23, 59), BillingFrequency.monthly),
        DateTime(2026, 11, 15),
      );
    });
  });

  group('quarterly and semi-annual', () {
    test('15 Oct quarterly -> 15 Jan', () {
      expect(
        next(DateTime(2026, 10, 15), BillingFrequency.quarterly),
        DateTime(2027, 1, 15),
      );
    });

    test('30 Nov quarterly -> 28 Feb', () {
      expect(
        next(DateTime(2026, 11, 30), BillingFrequency.quarterly),
        DateTime(2027, 2, 28),
      );
    });

    test('15 Oct semi-annual -> 15 Apr', () {
      expect(
        next(DateTime(2026, 10, 15), BillingFrequency.semiAnnual),
        DateTime(2027, 4, 15),
      );
    });
  });

  group('yearly', () {
    test('1 Jan -> 1 Jan next year', () {
      expect(
        next(DateTime(2026, 1, 1), BillingFrequency.yearly),
        DateTime(2027, 1, 1),
      );
    });

    test('29 Feb -> 28 Feb in a non-leap year', () {
      expect(
        next(DateTime(2028, 2, 29), BillingFrequency.yearly),
        DateTime(2029, 2, 28),
      );
    });

    test('29 Feb anchor returns to 29 Feb in the next leap year', () {
      var date = DateTime(2028, 2, 29);
      for (var i = 0; i < 4; i++) {
        date = next(date, BillingFrequency.yearly, anchorDay: 29);
      }
      expect(date, DateTime(2032, 2, 29));
    });
  });

  group('weekly and custom', () {
    test('weekly adds 7 days', () {
      expect(
        next(DateTime(2026, 10, 15), BillingFrequency.weekly),
        DateTime(2026, 10, 22),
      );
    });

    test('every 2 weeks crosses a month end', () {
      expect(
        next(DateTime(2026, 10, 25), BillingFrequency.weekly, interval: 2),
        DateTime(2026, 11, 8),
      );
    });

    test('weekly stays on the same calendar day across a DST change', () {
      // Europe/US DST dates fall in this window; calendar maths must not
      // produce 23:00 or 01:00 results.
      var date = DateTime(2026, 3, 1);
      for (var i = 0; i < 12; i++) {
        date = next(date, BillingFrequency.weekly);
        expect(date.hour, 0);
      }
      expect(date, DateTime(2026, 5, 24));
    });

    test('custom is every N days', () {
      expect(
        next(DateTime(2026, 10, 15), BillingFrequency.custom, interval: 45),
        DateTime(2026, 11, 29),
      );
    });
  });

  group('payment lateness', () {
    test('advancing from the due date, not the paid date, avoids drift', () {
      final due = DateTime(2026, 10, 15);
      // Marked paid on 18 Oct: the caller still passes the due date.
      expect(next(due, BillingFrequency.monthly), DateTime(2026, 11, 15));
    });
  });

  group('validation', () {
    test('rejects an interval below 1', () {
      expect(
        () => next(DateTime(2026, 1, 1), BillingFrequency.monthly, interval: 0),
        throwsArgumentError,
      );
    });

    test('rejects an invalid anchor day', () {
      expect(
        () =>
            next(DateTime(2026, 1, 1), BillingFrequency.monthly, anchorDay: 32),
        throwsArgumentError,
      );
    });
  });

  test('daysInMonth handles leap years', () {
    expect(daysInMonth(2026, 2), 28);
    expect(daysInMonth(2028, 2), 29);
    expect(daysInMonth(2100, 2), 28);
    expect(daysInMonth(2026, 4), 30);
    expect(daysInMonth(2026, 12), 31);
  });
}
