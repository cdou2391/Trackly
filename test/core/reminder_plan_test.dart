import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/notifications/reminder_plan.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';
import 'package:uuid/uuid.dart';

final _now = DateTime(2026, 10, 9, 12); // Fri 9 Oct, noon

RecurringItem item({
  String id = 'a',
  DateTime? due,
  int daysBefore = 3,
  bool reminders = true,
  ItemStatus status = ItemStatus.active,
  DateTime? trialEnd,
  int minuteOfDay = defaultReminderMinuteOfDay,
}) {
  return RecurringItem(
    id: id,
    name: 'Netflix',
    type: RecurringItemType.subscription,
    amount: 15.49,
    currencyCode: 'USD',
    frequency: BillingFrequency.monthly,
    startDate: DateTime(2026, 1, 15),
    nextDueDate: due ?? DateTime(2026, 10, 20),
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    remindersEnabled: reminders,
    reminderDaysBefore: daysBefore,
    reminderMinuteOfDay: minuteOfDay,
    createdAt: _now,
    updatedAt: _now,
  );
}

List<(ReminderType, DateTime)> plan(RecurringItem i, {DateTime? now}) => [
  for (final r in planReminders(i, now: now ?? _now)) (r.type, r.when),
];

void main() {
  group('reminder time of day', () {
    const evening = 18 * 60 + 30; // 18:30

    test('the default is 9:00', () {
      expect(defaultReminderMinuteOfDay, 540);
    });

    test('both reminders are delivered at the chosen time', () {
      expect(plan(item(due: DateTime(2026, 10, 20), minuteOfDay: evening)), [
        (ReminderType.dueSoon, DateTime(2026, 10, 17, 18, 30)),
        (ReminderType.dueToday, DateTime(2026, 10, 20, 18, 30)),
      ]);
    });

    test('same day uses the chosen time too', () {
      expect(
        plan(
          item(
            due: DateTime(2026, 10, 20),
            daysBefore: 0,
            minuteOfDay: 7 * 60 + 5,
          ),
        ),
        [(ReminderType.dueToday, DateTime(2026, 10, 20, 7, 5))],
      );
    });

    test('midnight and one minute to midnight', () {
      expect(
        plan(item(due: DateTime(2026, 10, 20), daysBefore: 0, minuteOfDay: 0)),
        [(ReminderType.dueToday, DateTime(2026, 10, 20))],
      );
      expect(
        plan(
          item(
            due: DateTime(2026, 10, 20),
            daysBefore: 0,
            minuteOfDay: 23 * 60 + 59,
          ),
        ),
        [(ReminderType.dueToday, DateTime(2026, 10, 20, 23, 59))],
      );
    });

    test('a later time today is still ahead when the default has passed', () {
      // Noon on the due day: 9:00 is gone, 18:30 is not.
      final due = DateTime(2026, 10, 9);
      expect(plan(item(due: due, daysBefore: 0)), isEmpty);
      expect(plan(item(due: due, daysBefore: 0, minuteOfDay: evening)), [
        (ReminderType.dueToday, DateTime(2026, 10, 9, 18, 30)),
      ]);
    });

    test('a trial reminder follows the time as well', () {
      final r = plan(
        item(
          due: DateTime(2026, 10, 20),
          trialEnd: DateTime(2026, 10, 20),
          minuteOfDay: evening,
        ),
      );
      expect(r.first, (
        ReminderType.trialEnding,
        DateTime(2026, 10, 17, 18, 30),
      ));
    });

    test('the notification id does not depend on the time', () {
      // So changing the time replaces the scheduled reminder, not duplicates it.
      final nine = planReminders(item(due: DateTime(2026, 10, 20)), now: _now);
      final later = planReminders(
        item(due: DateTime(2026, 10, 20), minuteOfDay: evening),
        now: _now,
      );
      expect(later.map((r) => r.id), nine.map((r) => r.id));
    });
  });

  group('planReminders', () {
    test('plans "due soon" N days ahead and "due today", at 9:00', () {
      expect(plan(item(due: DateTime(2026, 10, 20))), [
        (ReminderType.dueSoon, DateTime(2026, 10, 17, 9)),
        (ReminderType.dueToday, DateTime(2026, 10, 20, 9)),
      ]);
    });

    test('same day gives only the due-today reminder, never two', () {
      expect(plan(item(due: DateTime(2026, 10, 20), daysBefore: 0)), [
        (ReminderType.dueToday, DateTime(2026, 10, 20, 9)),
      ]);
    });

    test('1, 3 and 7 days before', () {
      for (final days in [1, 3, 7]) {
        final r = planReminders(
          item(due: DateTime(2026, 10, 25), daysBefore: days),
          now: _now,
        );
        expect(r.first.when, DateTime(2026, 10, 25 - days, 9), reason: '$days');
        expect(r.first.daysAhead, days);
      }
    });

    test('a reminder whose time has passed is left out', () {
      // Due on the 11th with 3 days notice: the 8th at 9:00 is already past.
      expect(plan(item(due: DateTime(2026, 10, 11))), [
        (ReminderType.dueToday, DateTime(2026, 10, 11, 9)),
      ]);
    });

    test('9:00 today is still ahead of 8:59 and gone at 9:01', () {
      final due = DateTime(2026, 10, 9);
      expect(
        plan(item(due: due, daysBefore: 0), now: DateTime(2026, 10, 9, 8, 59)),
        hasLength(1),
      );
      expect(
        plan(item(due: due, daysBefore: 0), now: DateTime(2026, 10, 9, 9, 1)),
        isEmpty,
      );
    });

    test('an overdue item has nothing to remind about', () {
      expect(plan(item(due: DateTime(2026, 10, 1))), isEmpty);
    });

    test('paused and cancelled items have no reminders', () {
      expect(plan(item(status: ItemStatus.paused)), isEmpty);
      expect(plan(item(status: ItemStatus.cancelled)), isEmpty);
    });

    test('turning reminders off removes them all', () {
      expect(plan(item(reminders: false)), isEmpty);
    });

    test('crosses month and year boundaries', () {
      expect(
        plan(item(due: DateTime(2027, 1, 2), daysBefore: 7)).first.$2,
        DateTime(2026, 12, 26, 9),
      );
      expect(
        plan(item(due: DateTime(2026, 11, 1), daysBefore: 3)).first.$2,
        DateTime(2026, 10, 29, 9),
      );
    });

    test('wall-clock time is kept across a daylight-saving change', () {
      // The planner works in local calendar days at 9:00, so a clock change
      // between the reminder and the due date cannot shift the hour.
      for (final r in planReminders(
        item(due: DateTime(2026, 11, 2), daysBefore: 7),
        now: DateTime(2026, 10, 1),
      )) {
        expect(r.when.hour, 9);
      }
    });

    group('free trials', () {
      test('the "days before" reminder says the trial is ending', () {
        final trial = item(
          due: DateTime(2026, 11, 15),
          trialEnd: DateTime(2026, 11, 15),
        );
        expect(plan(trial), [
          (ReminderType.trialEnding, DateTime(2026, 11, 12, 9)),
          (ReminderType.dueToday, DateTime(2026, 11, 15, 9)),
        ]);
      });

      test('after the trial ends it is an ordinary item again', () {
        final ended = item(
          due: DateTime(2026, 10, 25),
          trialEnd: DateTime(2026, 10, 1),
        );
        expect(plan(ended).first.$1, ReminderType.dueSoon);
      });

      test('a trial that ends today is still a trial today', () {
        final trial = item(
          due: DateTime(2026, 10, 9),
          trialEnd: DateTime(2026, 10, 9),
          daysBefore: 0,
        );
        // 9:00 today has passed at noon, so nothing is left to send.
        expect(plan(trial), isEmpty);
      });
    });
  });

  group('notificationIdFor', () {
    test('is stable: pinned values must never change', () {
      // A reminder is found and replaced by its id, so these values are part of
      // the app's contract. If this test fails, every scheduled reminder on a
      // user's phone would be orphaned after an update.
      expect(notificationIdFor('abc', ReminderType.dueSoon), 1368260321);
      expect(notificationIdFor('abc', ReminderType.dueToday), 714777599);
      expect(
        notificationIdFor('abc', ReminderType.dueSoon),
        notificationIdFor('abc', ReminderType.dueSoon),
      );
    });

    test('is a positive 31-bit integer (Android ids are 32-bit signed)', () {
      for (var i = 0; i < 500; i++) {
        final id = notificationIdFor(const Uuid().v4(), ReminderType.dueToday);
        expect(id, inInclusiveRange(0, 0x7FFFFFFF));
      }
    });

    test('differs by type and by item', () {
      final ids = {
        for (final type in ReminderType.values) notificationIdFor('a', type),
        notificationIdFor('b', ReminderType.dueSoon),
      };
      expect(ids, hasLength(4));
    });

    test('has no collisions across thousands of items', () {
      // A fixed set of ids, so the result never changes between runs. With
      // random ids, 12,000 values in a 31-bit space collide by chance in about
      // 3% of runs (the birthday effect), which says nothing about the hash.
      final seen = <int, String>{};
      for (var i = 0; i < 4000; i++) {
        final itemId =
            'item-$i-${const Uuid().v5(Namespace.url.value, 'trackly-$i')}';
        for (final type in ReminderType.values) {
          final id = notificationIdFor(itemId, type);
          final clash = seen[id];
          expect(clash, isNull, reason: '$itemId/$type vs $clash');
          seen[id] = '$itemId/$type';
        }
      }
    });
  });

  group('ReminderPayload', () {
    test('round-trips, carrying only ids and a fingerprint', () {
      const payload = ReminderPayload(
        itemId: 'abc',
        type: ReminderType.trialEnding,
        signature: 'deadbeef',
      );
      final parsed = ReminderPayload.parse(payload.encode())!;
      expect(parsed.itemId, 'abc');
      expect(parsed.type, ReminderType.trialEnding);
      expect(parsed.signature, 'deadbeef');
      // Nothing but those three fields: no name, amount or notes.
      expect(payload.encode(), isNot(contains('Netflix')));
      expect(payload.encode().length, lessThan(120));
    });

    test('rejects anything malformed', () {
      for (final bad in [
        null,
        '',
        'not json',
        '[]',
        '{}',
        '{"item_id": "a"}',
        '{"item_id": "", "notification_type": "due_soon"}',
        '{"item_id": "a", "notification_type": "nonsense"}',
        '{"item_id": 5, "notification_type": "due_soon"}',
      ]) {
        expect(ReminderPayload.parse(bad), isNull, reason: '$bad');
      }
    });
  });

  group('reminderSignature', () {
    final when = DateTime(2026, 10, 17, 9);

    test('is stable and changes with time or text', () {
      expect(
        reminderSignature(when, 'A', 'b'),
        reminderSignature(when, 'A', 'b'),
      );
      expect(
        reminderSignature(when, 'A', 'b'),
        isNot(reminderSignature(when.add(const Duration(days: 1)), 'A', 'b')),
      );
      expect(
        reminderSignature(when, 'A', 'b'),
        isNot(reminderSignature(when, 'A', 'c')),
      );
      expect(
        reminderSignature(when, 'A', 'b'),
        isNot(reminderSignature(when, 'B', 'b')),
      );
    });
  });
}
