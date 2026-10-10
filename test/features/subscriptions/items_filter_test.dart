import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/subscriptions/application/items_filter.dart';
import 'package:trackly/features/subscriptions/application/subscription_edit.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item(
  String id, {
  ItemStatus status = ItemStatus.active,
  DateTime? due,
  DateTime? trialEnd,
  DateTime? start,
  String? name,
}) {
  return RecurringItem(
    id: id,
    name: name ?? id,
    type: RecurringItemType.subscription,
    amount: 10,
    currencyCode: 'USD',
    frequency: BillingFrequency.monthly,
    startDate: start ?? DateTime(2026, 1, 15),
    nextDueDate: due ?? DateTime(2026, 10, 20),
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    createdAt: _now,
    updatedAt: _now,
  );
}

void main() {
  group('filterItems', () {
    final items = [
      item('active', due: DateTime(2026, 10, 25)),
      item('soon', due: DateTime(2026, 10, 12)),
      item('paused', status: ItemStatus.paused),
      item(
        'trial',
        trialEnd: DateTime(2026, 11, 1),
        due: DateTime(2026, 11, 1),
      ),
      item(
        'endedTrial',
        trialEnd: DateTime(2026, 10, 1),
        due: DateTime(2026, 10, 30),
      ),
      item('cancelled', status: ItemStatus.cancelled),
    ];

    List<String> ids(ItemFilter f) => [
      for (final i in filterItems(items, f, _now)) i.id,
    ];

    test('all lists live items first, then paused, then cancelled', () {
      expect(ids(ItemFilter.all), [
        'soon',
        'active',
        'endedTrial',
        'trial',
        'paused',
        'cancelled',
      ]);
    });

    test('active matches the Home card: live non-trial plus paused', () {
      expect(ids(ItemFilter.active), [
        'soon',
        'active',
        'endedTrial',
        'paused',
      ]);
    });

    test('trial is only items whose free trial is still running', () {
      expect(ids(ItemFilter.trial), ['trial']);
    });

    test('cancelled', () {
      expect(ids(ItemFilter.cancelled), ['cancelled']);
    });

    test('ties sort by name', () {
      final tie = [
        item('2', name: 'Zed', due: DateTime(2026, 10, 12)),
        item('1', name: 'Alpha', due: DateTime(2026, 10, 12)),
      ];
      expect(
        [for (final i in filterItems(tie, ItemFilter.all, _now)) i.name],
        ['Alpha', 'Zed'],
      );
    });

    test('parses the query parameter, defaulting to all', () {
      expect(ItemFilter.parse('trial'), ItemFilter.trial);
      expect(ItemFilter.parse('cancelled'), ItemFilter.cancelled);
      expect(ItemFilter.parse('nonsense'), ItemFilter.all);
      expect(ItemFilter.parse(null), ItemFilter.all);
    });
  });

  group('buildEditedItem', () {
    final original = item(
      'a',
      due: DateTime(2026, 10, 15),
      start: DateTime(2026, 1, 15),
    );

    EditedSubscription edit({
      String name = 'Netflix',
      double amount = 10,
      DateTime? next,
      bool isTrial = false,
      DateTime? trialEnd,
      String? notes,
    }) {
      return EditedSubscription(
        name: name,
        type: RecurringItemType.subscription,
        amount: amount,
        currencyCode: 'USD',
        frequency: BillingFrequency.monthly,
        nextDueDate: next ?? DateTime(2026, 10, 15),
        remindersEnabled: true,
        reminderDaysBefore: 3,
        isTrial: isTrial,
        trialEndDate: trialEnd,
        notes: notes,
      );
    }

    test('keeps id, status, interval and creation time; stamps updatedAt', () {
      final paused = item(
        'a',
        status: ItemStatus.paused,
        due: DateTime(2026, 10, 15),
      );
      final edited = buildEditedItem(
        paused,
        edit(),
        now: DateTime(2026, 10, 20),
      );
      expect(edited.id, 'a');
      expect(edited.status, ItemStatus.paused);
      expect(edited.interval, 1);
      expect(edited.createdAt, _now);
      expect(edited.updatedAt, DateTime(2026, 10, 20));
    });

    test('changing only the amount keeps the billing anchor', () {
      final edited = buildEditedItem(original, edit(amount: 22), now: _now);
      expect(edited.amount, 22);
      expect(edited.startDate, DateTime(2026, 1, 15));
      expect(edited.nextDueDate, DateTime(2026, 10, 15));
    });

    test('moving the next charge to another day moves the anchor too', () {
      final edited = buildEditedItem(
        original,
        edit(next: DateTime(2026, 10, 20)),
        now: _now,
      );
      expect(edited.nextDueDate, DateTime(2026, 10, 20));
      expect(edited.startDate, DateTime(2026, 10, 20));
    });

    test('moving the next charge within the same day keeps the anchor', () {
      final edited = buildEditedItem(
        original,
        edit(next: DateTime(2026, 12, 15)),
        now: _now,
      );
      expect(edited.startDate, DateTime(2026, 1, 15));
    });

    test('turning on a trial makes its end date the first charge', () {
      final edited = buildEditedItem(
        original,
        edit(isTrial: true, trialEnd: DateTime(2026, 11, 3)),
        now: _now,
      );
      expect(edited.isTrial, isTrue);
      expect(edited.nextDueDate, DateTime(2026, 11, 3));
      expect(edited.startDate, DateTime(2026, 11, 3));
    });

    test('a trial needs an end date', () {
      expect(
        () => buildEditedItem(original, edit(isTrial: true), now: _now),
        throwsArgumentError,
      );
    });

    test('turning a trial off clears the trial end', () {
      final trial = item(
        'a',
        trialEnd: DateTime(2026, 11, 1),
        due: DateTime(2026, 11, 1),
      );
      final edited = buildEditedItem(
        trial,
        edit(next: DateTime(2026, 11, 1), trialEnd: DateTime(2026, 11, 1)),
        now: _now,
      );
      expect(edited.isTrial, isFalse);
      expect(edited.trialEndDate, isNull);
    });

    test('trims the name and drops blank notes', () {
      final edited = buildEditedItem(
        original,
        edit(name: '  Hulu ', notes: '   '),
        now: _now,
      );
      expect(edited.name, 'Hulu');
      expect(edited.notes, isNull);
    });
  });
}
