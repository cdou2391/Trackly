import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/core/error/error_reporter.dart';
import 'package:trackly/features/home/application/home_providers.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/application/subscription_actions.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

class _Analytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

class _Errors implements ErrorReporter {
  final captured = <Object>[];

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async {
    captured.add(error);
  }

  @override
  void addBreadcrumb(String message, {String? category}) {}
}

RecurringItem item({
  String id = 'a',
  String name = 'Netflix',
  double amount = 15.49,
  BillingFrequency frequency = BillingFrequency.monthly,
  int interval = 1,
  DateTime? start,
  DateTime? due,
  ItemStatus status = ItemStatus.active,
}) {
  final created = DateTime(2026, 1, 1);
  return RecurringItem(
    id: id,
    name: name,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: 'USD',
    frequency: frequency,
    interval: interval,
    startDate: start ?? DateTime(2026, 1, 15),
    nextDueDate: due ?? DateTime(2026, 10, 15),
    status: status,
    notes: 'private note',
    createdAt: created,
    updatedAt: created,
  );
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _Analytics analytics;
  late _Errors errors;
  var now = DateTime(2026, 10, 18, 9);

  SubscriptionActions actions() => container.read(subscriptionActionsProvider);

  Future<RecurringItem> stored(String id) async =>
      (await db.recurringItemsDao.getById(id))!;

  Future<List<Payment>> history(String id) =>
      db.paymentsDao.watchForItem(id).first;

  setUp(() {
    now = DateTime(2026, 10, 18, 9);
    db = AppDatabase(NativeDatabase.memory());
    analytics = _Analytics();
    errors = _Errors();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nowProvider.overrideWithValue(() => now),
        analyticsProvider.overrideWithValue(analytics),
        errorReporterProvider.overrideWithValue(errors),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('nextDueAfterPayment', () {
    test('advances from the due date, not from today', () {
      expect(
        nextDueAfterPayment(item(due: DateTime(2026, 10, 15))),
        DateTime(2026, 11, 15),
      );
    });

    test('keeps the start day through short months', () {
      final jan31 = item(
        start: DateTime(2026, 1, 31),
        due: DateTime(2026, 2, 28),
      );
      expect(nextDueAfterPayment(jan31), DateTime(2026, 3, 31));
    });

    test('works for weekly, quarterly and yearly with intervals', () {
      expect(
        nextDueAfterPayment(
          item(
            frequency: BillingFrequency.weekly,
            interval: 2,
            due: DateTime(2026, 10, 15),
          ),
        ),
        DateTime(2026, 10, 29),
      );
      expect(
        nextDueAfterPayment(
          item(
            frequency: BillingFrequency.quarterly,
            due: DateTime(2026, 10, 15),
          ),
        ),
        DateTime(2027, 1, 15),
      );
      expect(
        nextDueAfterPayment(
          item(
            frequency: BillingFrequency.yearly,
            start: DateTime(2024, 2, 29),
            due: DateTime(2027, 2, 28),
          ),
        ),
        DateTime(2028, 2, 29),
      );
    });
  });

  group('defaultResumeDate', () {
    final today = DateTime(2026, 10, 18);

    test('a future due date is kept', () {
      expect(
        defaultResumeDate(item(due: DateTime(2026, 11, 2)), today),
        DateTime(2026, 11, 2),
      );
    });

    test('a past due date moves forward along the schedule', () {
      expect(
        defaultResumeDate(item(due: DateTime(2026, 6, 15)), today),
        DateTime(2026, 11, 15),
      );
    });

    test('a charge due today stays today', () {
      expect(
        defaultResumeDate(item(due: DateTime(2026, 10, 18)), today),
        DateTime(2026, 10, 18),
      );
    });
  });

  group('markPaid', () {
    test('records the payment and advances without drift', () async {
      await db.recurringItemsDao.insertItem(item());

      // Due 15 Oct, paid on 18 Oct.
      final outcome = await actions().markPaid(item());

      final payment = (await history('a')).single;
      expect(payment.status, PaymentStatus.paid);
      expect(payment.dueDate, DateTime(2026, 10, 15));
      expect(payment.paidDate, DateTime(2026, 10, 18));
      expect(payment.amount, 15.49);
      expect(payment.currencyCode, 'USD');
      expect(outcome.payment.id, payment.id);

      final updated = await stored('a');
      expect(updated.nextDueDate, DateTime(2026, 11, 15));
      expect(updated.status, ItemStatus.active);
      expect(updated.updatedAt, now);
    });

    test(
      'is saved as one transaction: nothing is left behind on failure',
      () async {
        // The item was never inserted, so the payment's foreign key fails.
        await expectLater(
          actions().markPaid(item(id: 'ghost')),
          throwsA(anything),
        );

        expect(await history('ghost'), isEmpty);
        expect(errors.captured, hasLength(1));
      },
    );

    test('logs payment_recorded with metadata only', () async {
      await db.recurringItemsDao.insertItem(item());
      await actions().markPaid(item());

      final (name, params) = analytics.events.single;
      expect(name, AnalyticsEvents.paymentRecorded);
      expect(params, {
        'item_type': 'subscription',
        'frequency': 'monthly',
        'currency': 'USD',
        'is_trial': false,
      });
      expect(params.toString(), isNot(contains('Netflix')));
      expect(params.toString(), isNot(contains('private note')));
    });

    test('several payments build a history, newest first', () async {
      await db.recurringItemsDao.insertItem(item());
      await actions().markPaid(item());
      await actions().markPaid(await stored('a'));

      final payments = await history('a');
      expect(payments.map((p) => p.dueDate), [
        DateTime(2026, 11, 15),
        DateTime(2026, 10, 15),
      ]);
      expect((await stored('a')).nextDueDate, DateTime(2026, 12, 15));
    });
  });

  group('skip', () {
    test('records a skipped charge without a paid date and advances', () async {
      await db.recurringItemsDao.insertItem(item());
      await actions().skip(item());

      final payment = (await history('a')).single;
      expect(payment.status, PaymentStatus.skipped);
      expect(payment.paidDate, isNull);
      expect((await stored('a')).nextDueDate, DateTime(2026, 11, 15));
      expect(analytics.events.single.$1, AnalyticsEvents.paymentSkipped);
    });

    test('skipped charges are not recent payments', () async {
      await db.recurringItemsDao.insertItem(item());
      await actions().skip(item());
      expect(await db.paymentsDao.watchRecentPaid().first, isEmpty);
    });
  });

  group('undo', () {
    test('restores the due date and removes the payment', () async {
      await db.recurringItemsDao.insertItem(item());
      final outcome = await actions().markPaid(item());
      await actions().undo(outcome);

      expect(await history('a'), isEmpty);
      final restored = await stored('a');
      expect(restored.nextDueDate, DateTime(2026, 10, 15));
    });

    test('also reverses a skip', () async {
      await db.recurringItemsDao.insertItem(item());
      final outcome = await actions().skip(item());
      await actions().undo(outcome);
      expect(await history('a'), isEmpty);
      expect((await stored('a')).nextDueDate, DateTime(2026, 10, 15));
    });
  });

  group('pause and resume', () {
    test('a paused item leaves Upcoming and the active list', () async {
      await db.recurringItemsDao.insertItem(item());
      await actions().pause(item());

      expect((await stored('a')).status, ItemStatus.paused);
      expect(await db.recurringItemsDao.getActive(), isEmpty);
      expect(
        await db.recurringItemsDao
            .watchUpcoming(until: DateTime(2027, 1, 1))
            .first,
        isEmpty,
      );
      expect(analytics.events.single.$1, AnalyticsEvents.subscriptionPaused);
    });

    test('resuming activates it with the chosen next charge', () async {
      await db.recurringItemsDao.insertItem(item(status: ItemStatus.paused));
      await actions().resume(
        item(status: ItemStatus.paused),
        DateTime(2026, 12, 3, 22),
      );

      final resumed = await stored('a');
      expect(resumed.status, ItemStatus.active);
      expect(resumed.nextDueDate, DateTime(2026, 12, 3));
      expect(analytics.events.single.$1, AnalyticsEvents.subscriptionResumed);
    });

    test('pausing keeps the payment history', () async {
      await db.recurringItemsDao.insertItem(item());
      await actions().markPaid(item());
      await actions().pause(await stored('a'));
      expect(await history('a'), hasLength(1));
    });
  });

  group('cancel and delete', () {
    test('cancelling keeps the item and its history', () async {
      await db.recurringItemsDao.insertItem(item());
      await actions().markPaid(item());
      await actions().cancel(await stored('a'));

      expect((await stored('a')).status, ItemStatus.cancelled);
      expect(await history('a'), hasLength(1));
      expect(await db.recurringItemsDao.getActive(), isEmpty);
      expect(analytics.events.last.$1, AnalyticsEvents.subscriptionCancelled);
    });

    test('deleting removes the item and its history', () async {
      await db.recurringItemsDao.insertItem(item());
      await db.recurringItemsDao.insertItem(item(id: 'b', name: 'Spotify'));
      await actions().markPaid(item());
      await actions().markPaid(item(id: 'b', name: 'Spotify'));

      await actions().delete(item());

      expect(await db.recurringItemsDao.getById('a'), isNull);
      expect(await history('a'), isEmpty);
      // Other items are untouched.
      expect(await db.recurringItemsDao.getById('b'), isNotNull);
      expect(await history('b'), hasLength(1));
      expect(analytics.events.last.$1, AnalyticsEvents.subscriptionDeleted);
    });
  });

  group('reminder time is kept', () {
    test('through pause, resume and payment', () async {
      await db.recurringItemsDao.insertItem(
        RecurringItem(
          id: 'a',
          name: 'Netflix',
          type: RecurringItemType.subscription,
          amount: 15.49,
          currencyCode: 'USD',
          frequency: BillingFrequency.monthly,
          startDate: DateTime(2026, 1, 15),
          nextDueDate: DateTime(2026, 10, 15),
          reminderMinuteOfDay: 18 * 60 + 30,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: now,
        ),
      );

      await actions().pause(await stored('a'));
      expect((await stored('a')).reminderMinuteOfDay, 18 * 60 + 30);

      await actions().resume(await stored('a'), DateTime(2026, 11, 15));
      expect((await stored('a')).reminderMinuteOfDay, 18 * 60 + 30);

      await actions().markPaid(await stored('a'));
      expect((await stored('a')).reminderMinuteOfDay, 18 * 60 + 30);
    });
  });

  group('update', () {
    test('persists the edited fields', () async {
      await db.recurringItemsDao.insertItem(item());
      final edited = RecurringItem(
        id: 'a',
        name: 'Netflix Premium',
        type: RecurringItemType.subscription,
        amount: 22.99,
        currencyCode: 'EUR',
        frequency: BillingFrequency.quarterly,
        startDate: DateTime(2026, 1, 15),
        nextDueDate: DateTime(2027, 1, 15),
        remindersEnabled: false,
        reminderDaysBefore: 7,
        categoryId: 'entertainment',
        notes: 'new note',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: now,
      );

      await actions().update(edited);

      final saved = await stored('a');
      expect(saved.name, 'Netflix Premium');
      expect(saved.amount, 22.99);
      expect(saved.currencyCode, 'EUR');
      expect(saved.frequency, BillingFrequency.quarterly);
      expect(saved.nextDueDate, DateTime(2027, 1, 15));
      expect(saved.remindersEnabled, isFalse);
      expect(saved.reminderDaysBefore, 7);
      expect(saved.categoryId, 'entertainment');
      expect(saved.notes, 'new note');
      expect(analytics.events.single.$1, AnalyticsEvents.subscriptionUpdated);
    });
  });

  test('a database failure is reported and rethrown', () async {
    await db.recurringItemsDao.insertItem(item());
    final bad = RecurringItem(
      id: 'a',
      name: 'Netflix',
      type: RecurringItemType.subscription,
      amount: 15.49,
      currencyCode: 'USD',
      frequency: BillingFrequency.monthly,
      startDate: DateTime(2026, 1, 15),
      nextDueDate: DateTime(2026, 10, 15),
      categoryId: 'no-such-category', // violates the foreign key
      createdAt: DateTime(2026, 1, 1),
      updatedAt: now,
    );

    await expectLater(actions().update(bad), throwsA(anything));

    expect(errors.captured, hasLength(1));
    // Nothing was logged for a change that did not happen.
    expect(analytics.events, isEmpty);
    // The stored item is unchanged.
    expect((await stored('a')).categoryId, isNull);
  });
}
