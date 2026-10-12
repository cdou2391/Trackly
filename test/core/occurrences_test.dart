import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/utils/recurrence_utils.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

List<DateTime> occurrences(
  DateTime firstDue,
  BillingFrequency frequency, {
  required DateTime from,
  required DateTime to,
  int interval = 1,
  int? anchorDay,
}) => occurrencesInRange(
  firstDue: firstDue,
  frequency: frequency,
  interval: interval,
  anchorDay: anchorDay,
  from: from,
  to: to,
);

void main() {
  final oct1 = DateTime(2026, 10, 1);
  final oct31 = DateTime(2026, 10, 31);

  group('monthly', () {
    test('one date in the month containing the due date', () {
      expect(
        occurrences(
          DateTime(2026, 10, 15),
          BillingFrequency.monthly,
          from: oct1,
          to: oct31,
        ),
        [DateTime(2026, 10, 15)],
      );
    });

    test('projects forward into a later month', () {
      expect(
        occurrences(
          DateTime(2026, 10, 15),
          BillingFrequency.monthly,
          from: DateTime(2027, 1, 1),
          to: DateTime(2027, 1, 31),
        ),
        [DateTime(2027, 1, 15)],
      );
    });

    test('nothing before the first due date', () {
      expect(
        occurrences(
          DateTime(2026, 10, 15),
          BillingFrequency.monthly,
          from: DateTime(2026, 9, 1),
          to: DateTime(2026, 9, 30),
        ),
        isEmpty,
      );
    });

    test('a month-end anchor clamps in February and recovers in March', () {
      final february = occurrences(
        DateTime(2026, 1, 31),
        BillingFrequency.monthly,
        from: DateTime(2026, 2, 1),
        to: DateTime(2026, 2, 28),
        anchorDay: 31,
      );
      final march = occurrences(
        DateTime(2026, 1, 31),
        BillingFrequency.monthly,
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 31),
        anchorDay: 31,
      );
      expect(february, [DateTime(2026, 2, 28)]);
      expect(march, [DateTime(2026, 3, 31)]);
    });

    test('29 Feb leap-year anchor yearly lands on 28 Feb in a normal year', () {
      expect(
        occurrences(
          DateTime(2028, 2, 29),
          BillingFrequency.yearly,
          from: DateTime(2029, 2, 1),
          to: DateTime(2029, 2, 28),
          anchorDay: 29,
        ),
        [DateTime(2029, 2, 28)],
      );
    });
  });

  group('weekly and custom', () {
    test('a weekly item appears every week', () {
      expect(
        occurrences(
          DateTime(2026, 10, 2),
          BillingFrequency.weekly,
          from: oct1,
          to: oct31,
        ),
        [
          DateTime(2026, 10, 2),
          DateTime(2026, 10, 9),
          DateTime(2026, 10, 16),
          DateTime(2026, 10, 23),
          DateTime(2026, 10, 30),
        ],
      );
    });

    test('every 2 weeks', () {
      expect(
        occurrences(
          DateTime(2026, 10, 2),
          BillingFrequency.weekly,
          interval: 2,
          from: oct1,
          to: oct31,
        ),
        [DateTime(2026, 10, 2), DateTime(2026, 10, 16), DateTime(2026, 10, 30)],
      );
    });

    test('custom is every N days', () {
      expect(
        occurrences(
          DateTime(2026, 10, 1),
          BillingFrequency.custom,
          interval: 10,
          from: oct1,
          to: oct31,
        ),
        [
          DateTime(2026, 10, 1),
          DateTime(2026, 10, 11),
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 31),
        ],
      );
    });

    test('a due date long ago still lands on its own schedule', () {
      // 2025-10-03 + 7n days: 2026-10-02 is the Friday-aligned date.
      final dates = occurrences(
        DateTime(2025, 10, 3),
        BillingFrequency.weekly,
        from: oct1,
        to: oct31,
      );
      expect(dates.first, DateTime(2026, 10, 2));
      expect(
        dates.every((d) => d.difference(dates.first).inDays % 7 == 0),
        isTrue,
      );
    });
  });

  group('range edges', () {
    test('both ends are inclusive', () {
      expect(
        occurrences(
          DateTime(2026, 10, 1),
          BillingFrequency.custom,
          interval: 30,
          from: oct1,
          to: DateTime(2026, 10, 31),
        ),
        [DateTime(2026, 10, 1), DateTime(2026, 10, 31)],
      );
    });

    test('an empty or reversed range gives nothing', () {
      expect(
        occurrences(
          DateTime(2026, 10, 15),
          BillingFrequency.monthly,
          from: oct31,
          to: oct1,
        ),
        isEmpty,
      );
    });

    test('time of day is ignored', () {
      expect(
        occurrences(
          DateTime(2026, 10, 15, 23, 59),
          BillingFrequency.monthly,
          from: DateTime(2026, 10, 1, 8),
          to: DateTime(2026, 10, 15, 1),
        ),
        [DateTime(2026, 10, 15)],
      );
    });

    test('quarterly skips months with no charge', () {
      expect(
        occurrences(
          DateTime(2026, 10, 15),
          BillingFrequency.quarterly,
          from: DateTime(2026, 11, 1),
          to: DateTime(2026, 11, 30),
        ),
        isEmpty,
      );
    });
  });
}
