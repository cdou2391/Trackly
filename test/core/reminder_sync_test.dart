import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/core/error/error_reporter.dart';
import 'package:trackly/core/notifications/notification_service.dart';
import 'package:trackly/core/notifications/reminder_plan.dart';
import 'package:trackly/core/notifications/reminder_sync.dart';
import 'package:trackly/features/home/application/home_providers.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

import '../helpers/fake_notification_service.dart';
import '../helpers/test_app.dart' show testItem, testNow;

class _RecordingReporter implements ErrorReporter {
  final errors = <Object>[];

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async {
    errors.add(error);
  }

  @override
  void addBreadcrumb(String message, {String? category}) {}
}

/// [item] with some fields changed.
RecurringItem changed(
  RecurringItem item, {
  double? amount,
  DateTime? nextDueDate,
  ItemStatus? status,
  bool? remindersEnabled,
  int? reminderMinuteOfDay,
}) {
  return RecurringItem(
    id: item.id,
    name: item.name,
    type: item.type,
    amount: amount ?? item.amount,
    currencyCode: item.currencyCode,
    frequency: item.frequency,
    startDate: item.startDate,
    nextDueDate: nextDueDate ?? item.nextDueDate,
    status: status ?? item.status,
    remindersEnabled: remindersEnabled ?? item.remindersEnabled,
    reminderDaysBefore: item.reminderDaysBefore,
    reminderMinuteOfDay: reminderMinuteOfDay ?? item.reminderMinuteOfDay,
    createdAt: item.createdAt,
    updatedAt: item.updatedAt,
  );
}

final _syncProvider = Provider(
  (ref) => ReminderSync(ref, locale: () => const Locale('en', 'US')),
);

void main() {
  late AppDatabase db;
  late FakeNotificationService service;
  late _RecordingReporter reporter;
  late ProviderContainer container;
  late ReminderSync sync;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = FakeNotificationService();
    reporter = _RecordingReporter();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        notificationServiceProvider.overrideWithValue(service),
        errorReporterProvider.overrideWithValue(reporter),
        nowProvider.overrideWithValue(() => testNow),
      ],
    );
    sync = container.read(_syncProvider);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // Due 20 Oct, 3 days before -> 17 Oct 9:00 (due soon) and 20 Oct (today).
  test('schedules the planned reminders with localized text', () async {
    await db.recurringItemsDao.insertItem(testItem('Netflix', amount: 15.49));
    await sync.reconcile();

    expect(service.scheduled, hasLength(2));
    final soon = service.scheduled.values.firstWhere((r) => r.when.day == 17);
    expect(soon.title, 'Netflix');
    expect(soon.body, 'Due in 3 days · \$15.49');
    expect(soon.when, DateTime(2026, 10, 17, 9));
    final today = service.scheduled.values.firstWhere((r) => r.when.day == 20);
    expect(today.body, 'Due today · \$15.49');
    expect(ReminderPayload.parse(soon.payload)?.itemId, 'Netflix');
  });

  test('delivers at the item\'s reminder time', () async {
    await db.recurringItemsDao.insertItem(
      testItem('Netflix', reminderMinuteOfDay: 18 * 60 + 30),
    );
    await sync.reconcile();

    final times = service.scheduled.values.map((r) => r.when).toSet();
    expect(times, {
      DateTime(2026, 10, 17, 18, 30),
      DateTime(2026, 10, 20, 18, 30),
    });
  });

  test(
    'changing the time reschedules the same reminders, no duplicates',
    () async {
      final netflix = testItem('Netflix');
      await db.recurringItemsDao.insertItem(netflix);
      await sync.reconcile();
      final idsBefore = service.scheduled.keys.toSet();
      expect(service.scheduled.values.map((r) => r.when.hour), everyElement(9));

      await db.recurringItemsDao.updateItem(
        changed(netflix, reminderMinuteOfDay: 20 * 60),
      );
      await sync.reconcile();

      expect(service.scheduled.keys.toSet(), idsBefore);
      expect(
        service.scheduled.values.map((r) => r.when.hour),
        everyElement(20),
      );
    },
  );

  test('is idempotent: a second run schedules nothing', () async {
    await db.recurringItemsDao.insertItem(testItem('Netflix'));
    await sync.reconcile();
    final calls = service.scheduleCalls;
    await sync.reconcile();
    expect(service.scheduleCalls, calls);
    expect(service.cancelCalls, 0);
  });

  test('does nothing when notifications are not allowed', () async {
    service.allowed = false;
    await db.recurringItemsDao.insertItem(testItem('Netflix'));
    await sync.reconcile();
    expect(service.scheduled, isEmpty);
    expect(service.scheduleCalls, 0);
  });

  test('reschedules when the due date changes', () async {
    final item = testItem('Netflix');
    await db.recurringItemsDao.insertItem(item);
    await sync.reconcile();

    await db.recurringItemsDao.updateItem(
      changed(item, nextDueDate: DateTime(2026, 11, 20)),
    );
    await sync.reconcile();

    final days = service.scheduled.values.map((r) => r.when).toSet();
    expect(days, {DateTime(2026, 11, 17, 9), DateTime(2026, 11, 20, 9)});
    expect(service.scheduled, hasLength(2));
  });

  test('reschedules when the amount changes (text changed)', () async {
    final item = testItem('Netflix', amount: 10);
    await db.recurringItemsDao.insertItem(item);
    await sync.reconcile();
    await db.recurringItemsDao.updateItem(changed(item, amount: 12));
    await sync.reconcile();
    expect(
      service.scheduled.values.map((r) => r.body),
      everyElement(contains('\$12.00')),
    );
  });

  test('cancels reminders of a paused, cancelled or deleted item', () async {
    final a = testItem('A');
    final b = testItem('B');
    final c = testItem('C');
    for (final i in [a, b, c]) {
      await db.recurringItemsDao.insertItem(i);
    }
    await sync.reconcile();
    expect(service.scheduled, hasLength(6));

    await db.recurringItemsDao.updateItem(
      changed(a, status: ItemStatus.paused),
    );
    await db.recurringItemsDao.updateItem(
      changed(b, status: ItemStatus.cancelled),
    );
    await db.recurringItemsDao.deleteItem('C');
    await sync.reconcile();
    expect(service.scheduled, isEmpty);
  });

  test('cancels reminders when reminders are switched off', () async {
    final item = testItem('Netflix');
    await db.recurringItemsDao.insertItem(item);
    await sync.reconcile();
    await db.recurringItemsDao.updateItem(
      changed(item, remindersEnabled: false),
    );
    await sync.reconcile();
    expect(service.scheduled, isEmpty);
  });

  test('removes stale reminders that no longer belong to any item', () async {
    await service.schedule(
      ScheduledReminder(
        id: 42,
        when: DateTime(2027),
        title: 'x',
        body: 'y',
        payload: 'not ours',
      ),
    );
    await sync.reconcile();
    expect(service.scheduled, isEmpty);
  });

  test('one failing reminder does not stop the others', () async {
    final bad = testItem('Bad');
    await db.recurringItemsDao.insertItem(bad);
    await db.recurringItemsDao.insertItem(testItem('Good'));
    service.failingIds.add(notificationIdFor('Bad', ReminderType.dueSoon));

    await sync.reconcile();

    expect(reporter.errors, hasLength(1));
    expect(
      service.scheduled.values
          .map((r) => ReminderPayload.parse(r.payload)!.itemId)
          .toSet(),
      {'Bad', 'Good'},
    );
    expect(service.scheduled, hasLength(3));
  });

  test('concurrent requests settle on the latest data', () async {
    await db.recurringItemsDao.insertItem(testItem('A'));
    final first = sync.reconcile();
    await db.recurringItemsDao.insertItem(testItem('B'));
    final second = sync.reconcile();
    await Future.wait([first, second]);
    expect(service.scheduled, hasLength(4));
  });
}
