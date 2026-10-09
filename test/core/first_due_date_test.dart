import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/utils/recurrence_utils.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

DateTime first(DateTime start, DateTime today,
        [BillingFrequency frequency = BillingFrequency.monthly]) =>
    firstDueDate(startDate: start, frequency: frequency, today: today);

void main() {
  final today = DateTime(2026, 10, 9);

  group('firstDueDate', () {
    test('start today means one period from now', () {
      expect(first(today, today), DateTime(2026, 11, 9));
    });

    test('a future start date is itself the next due date', () {
      expect(first(DateTime(2026, 10, 20), today), DateTime(2026, 10, 20));
    });

    test('a charge falling today is due today', () {
      expect(first(DateTime(2026, 9, 9), today), DateTime(2026, 10, 9));
    });

    test('a long-past start lands on the next future occurrence', () {
      expect(first(DateTime(2025, 1, 15), today), DateTime(2026, 10, 15));
    });

    test('keeps the start day through short months', () {
      expect(first(DateTime(2026, 1, 31), DateTime(2026, 3, 1)),
          DateTime(2026, 3, 31));
    });

    test('works for weekly and yearly', () {
      expect(first(DateTime(2026, 10, 1), today, BillingFrequency.weekly),
          DateTime(2026, 10, 15));
      expect(first(DateTime(2026, 3, 5), today, BillingFrequency.yearly),
          DateTime(2027, 3, 5));
    });

    test('ignores time of day on today', () {
      expect(first(DateTime(2026, 9, 9), DateTime(2026, 10, 9, 23, 59)),
          DateTime(2026, 10, 9));
    });
  });

  group('daysBetween', () {
    test('counts calendar days', () {
      expect(daysBetween(DateTime(2026, 10, 9), DateTime(2026, 10, 10)), 1);
      expect(daysBetween(DateTime(2026, 10, 9), DateTime(2026, 10, 9)), 0);
      expect(daysBetween(DateTime(2026, 10, 9), DateTime(2026, 10, 8)), -1);
    });

    test('is not skewed by a daylight-saving change', () {
      // 29 Mar 2026 is a DST day in Europe; a naive Duration gives 0 days.
      expect(daysBetween(DateTime(2026, 3, 28), DateTime(2026, 3, 29)), 1);
      expect(daysBetween(DateTime(2026, 3, 29), DateTime(2026, 3, 30)), 1);
      expect(daysBetween(DateTime(2026, 10, 24), DateTime(2026, 10, 25)), 1);
    });
  });

  group('upcomingCutoff', () {
    test('is one calendar month ahead, whatever the month length', () {
      expect(upcomingCutoff(DateTime(2026, 10, 9)), DateTime(2026, 11, 9)); // 31 days
      expect(upcomingCutoff(DateTime(2026, 11, 9)), DateTime(2026, 12, 9)); // 30 days
      expect(upcomingCutoff(DateTime(2026, 1, 15)), DateTime(2026, 2, 15)); // 31 days
      expect(upcomingCutoff(DateTime(2026, 2, 15)), DateTime(2026, 3, 15)); // 28 days
      expect(upcomingCutoff(DateTime(2028, 2, 15)), DateTime(2028, 3, 15)); // 29 days
    });

    test('clamps at month end', () {
      expect(upcomingCutoff(DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
      expect(upcomingCutoff(DateTime(2026, 3, 31)), DateTime(2026, 4, 30));
      expect(upcomingCutoff(DateTime(2028, 1, 31)), DateTime(2028, 2, 29));
    });

    test('crosses the year boundary', () {
      expect(upcomingCutoff(DateTime(2026, 12, 20)), DateTime(2027, 1, 20));
    });

    test('ignores time of day', () {
      expect(upcomingCutoff(DateTime(2026, 10, 9, 23, 59)),
          DateTime(2026, 11, 9));
    });

    test('a monthly item added today is always inside the window', () {
      // Every start day of the year, including month ends and a leap year.
      for (final year in [2026, 2028]) {
        var day = DateTime(year, 1, 1);
        while (day.year == year) {
          final due = firstDueDate(
            startDate: day,
            frequency: BillingFrequency.monthly,
            today: day,
          );
          expect(due.isAfter(upcomingCutoff(day)), isFalse, reason: '$day');
          day = DateTime(day.year, day.month, day.day + 1);
        }
      }
    });
  });
}
