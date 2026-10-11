import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../../features/home/application/home_providers.dart';
import '../../features/subscriptions/domain/recurring_item.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../error/error_reporter.dart';
import 'notification_service.dart';
import 'reminder_plan.dart';
import 'reminder_text.dart';

/// Makes the reminders scheduled on the device match the items in the
/// database.
///
/// It is a reconciler, not an event log: each run works out what should be
/// scheduled, then cancels what should not be and (re)schedules what is
/// missing or out of date. Running it again changes nothing, so it can be
/// triggered freely (item changes, app launch, app resume).
class ReminderSync {
  ReminderSync(this._ref, {Locale Function()? locale})
    : _locale = locale ?? (() => PlatformDispatcher.instance.locale);

  final Ref _ref;
  final Locale Function() _locale;

  Future<void>? _running;
  bool _again = false;

  /// Reconciles now. A request made while a run is in progress triggers one
  /// more run afterwards, so the latest data always wins.
  Future<void> reconcile() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      try {
        await _run();
      } catch (error, stackTrace) {
        await _ref
            .read(errorReporterProvider)
            .captureException(error, stackTrace);
      }
    } while (_again);
  }

  Future<void> _run() async {
    final service = _ref.read(notificationServiceProvider);
    if (!await service.notificationsAllowed()) return;

    final items = await _ref
        .read(appDatabaseProvider)
        .recurringItemsDao
        .getActive();
    final now = _ref.read(nowProvider)();
    final locale = _locale();
    final l10n = notificationLocalizations(locale);
    final localeTag = locale.toLanguageTag();

    final desired = <int, ScheduledReminder>{};
    for (final item in items) {
      for (final planned in planReminders(item, now: now)) {
        final text = reminderText(l10n, item, planned, locale: localeTag);
        desired[planned.id] = ScheduledReminder(
          id: planned.id,
          when: planned.when,
          title: text.title,
          body: text.body,
          payload: ReminderPayload(
            itemId: item.id,
            type: planned.type,
            signature: reminderSignature(planned.when, text.title, text.body),
          ).encode(),
        );
      }
    }

    final pending = {for (final p in await service.pending()) p.id: p.payload};

    for (final id in pending.keys) {
      if (desired.containsKey(id)) continue;
      await _isolated(() => service.cancel(id));
    }

    var scheduled = 0;
    for (final reminder in desired.values) {
      final current = ReminderPayload.parse(pending[reminder.id]);
      final wanted = ReminderPayload.parse(reminder.payload);
      if (pending.containsKey(reminder.id) &&
          current?.signature == wanted?.signature) {
        continue;
      }
      if (await _isolated(() => service.schedule(reminder))) scheduled++;
    }

    if (scheduled > 0) {
      unawaited(
        _ref
            .read(analyticsProvider)
            .logEvent(
              AnalyticsEvents.reminderScheduled,
              parameters: {'count': scheduled},
            ),
      );
    }
  }

  /// One reminder failing must not stop the rest.
  Future<bool> _isolated(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      await _ref
          .read(errorReporterProvider)
          .captureException(error, stackTrace);
      return false;
    }
  }
}

final reminderSyncProvider = Provider<ReminderSync>((ref) {
  final sync = ReminderSync(ref);

  // Reconcile whenever the items change (and once at launch).
  ref.listen<AsyncValue<List<RecurringItem>>>(recurringItemsProvider, (
    previous,
    next,
  ) {
    if (next.hasValue) unawaited(sync.reconcile());
  }, fireImmediately: true);

  // Time passing also changes what is due: catch up when the app returns.
  final observer = _ResumeObserver(() => unawaited(sync.reconcile()));
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

  return sync;
});

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this._onResume);

  final VoidCallback _onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }
}
