import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/error/error_reporter.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../home/application/home_providers.dart';
import '../../payments/domain/payment.dart';
import '../domain/recurring_enums.dart';
import '../domain/recurring_item.dart';
import 'item_analytics.dart';

/// What a payment action changed, so it can be undone.
class PaymentOutcome {
  const PaymentOutcome({required this.previous, required this.payment});

  /// The item as it was before the payment was recorded.
  final RecurringItem previous;
  final Payment payment;

  PaymentStatus get status => payment.status;
}

/// The next due date after a payment (or skip) for [item].
///
/// Advances from the current due date, not from today, so paying late never
/// shifts the schedule (15 Oct paid on 18 Oct is still due 15 Nov). The start
/// date's day is the anchor, so a clamped month recovers (28 Feb -> 31 Mar).
DateTime nextDueAfterPayment(RecurringItem item) {
  return calculateNextDueDate(
    fromDate: item.nextDueDate,
    frequency: item.frequency,
    interval: item.interval,
    anchorDay: item.startDate.day,
  );
}

/// Where a resumed item's schedule should pick up by default: its next real
/// occurrence on or after [today].
DateTime defaultResumeDate(RecurringItem item, DateTime today) {
  return nextOccurrenceOnOrAfter(
    from: item.nextDueDate,
    frequency: item.frequency,
    interval: item.interval,
    anchorDay: item.startDate.day,
    today: today,
  );
}

/// Changes to an existing subscription or bill: record a payment, skip a
/// charge, pause, resume, cancel, delete and edit.
///
/// Each action writes to the local database, logs structured analytics (never
/// names or notes) and reports failures to Sentry before rethrowing.
class SubscriptionActions {
  SubscriptionActions(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);
  DateTime get _now => _ref.read(nowProvider)();

  /// Records a payment for the current due date and moves to the next one.
  Future<PaymentOutcome> markPaid(RecurringItem item) =>
      _recordCharge(item, PaymentStatus.paid);

  /// Skips the current charge (it is not paid) and moves to the next one.
  Future<PaymentOutcome> skip(RecurringItem item) =>
      _recordCharge(item, PaymentStatus.skipped);

  Future<PaymentOutcome> _recordCharge(
    RecurringItem item,
    PaymentStatus status,
  ) async {
    final now = _now;
    final payment = Payment(
      id: const Uuid().v4(),
      recurringItemId: item.id,
      amount: item.amount,
      currencyCode: item.currencyCode,
      dueDate: item.nextDueDate,
      paidDate: status == PaymentStatus.paid ? dateOnly(now) : null,
      status: status,
      createdAt: now,
    );
    final updated = _copy(
      item,
      nextDueDate: nextDueAfterPayment(item),
      updatedAt: now,
    );

    await _guard(() {
      return _db.transaction(() async {
        await _db.paymentsDao.insertPayment(payment);
        await _db.recurringItemsDao.updateItem(updated);
      });
    });

    _log(
      status == PaymentStatus.paid
          ? AnalyticsEvents.paymentRecorded
          : AnalyticsEvents.paymentSkipped,
      item,
    );
    return PaymentOutcome(previous: item, payment: payment);
  }

  /// Reverses [markPaid] or [skip]: removes the payment and restores the item.
  Future<void> undo(PaymentOutcome outcome) {
    return _guard(() {
      return _db.transaction(() async {
        await _db.paymentsDao.deletePayment(outcome.payment.id);
        await _db.recurringItemsDao.updateItem(outcome.previous);
      });
    });
  }

  /// Stops reminders, totals and Upcoming for [item]; history is kept.
  Future<void> pause(RecurringItem item) async {
    await _save(_copy(item, status: ItemStatus.paused, updatedAt: _now));
    _log(AnalyticsEvents.subscriptionPaused, item);
  }

  /// Starts [item] again with [nextDue] as its next charge.
  Future<void> resume(RecurringItem item, DateTime nextDue) async {
    await _save(
      _copy(
        item,
        status: ItemStatus.active,
        nextDueDate: dateOnly(nextDue),
        updatedAt: _now,
      ),
    );
    _log(AnalyticsEvents.subscriptionResumed, item);
  }

  /// Ends [item]: no more reminders or due dates, history retained.
  Future<void> cancel(RecurringItem item) async {
    await _save(_copy(item, status: ItemStatus.cancelled, updatedAt: _now));
    _log(AnalyticsEvents.subscriptionCancelled, item);
  }

  /// Removes [item] and its payment history.
  Future<void> delete(RecurringItem item) async {
    await _guard(() => _db.recurringItemsDao.deleteItem(item.id));
    _log(AnalyticsEvents.subscriptionDeleted, item);
  }

  /// Saves an edited item. The caller builds [edited] from the original, and
  /// passes that original as [previous] so a reminder being switched on or
  /// off can be told apart from other edits.
  Future<void> update(RecurringItem edited, {RecurringItem? previous}) async {
    await _save(edited);
    _log(AnalyticsEvents.subscriptionUpdated, edited);
    if (previous != null &&
        previous.remindersEnabled != edited.remindersEnabled) {
      _log(
        edited.remindersEnabled
            ? AnalyticsEvents.reminderEnabled
            : AnalyticsEvents.reminderDisabled,
        edited,
      );
    }
  }

  Future<void> _save(RecurringItem item) {
    return _guard(() => _db.recurringItemsDao.updateItem(item));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    final errors = _ref.read(errorReporterProvider);
    try {
      errors.addBreadcrumb('item_write_started', category: 'ui');
      return await action();
    } catch (error, stackTrace) {
      await errors.captureException(error, stackTrace);
      rethrow;
    }
  }

  void _log(String event, RecurringItem item) {
    _ref
        .read(analyticsProvider)
        .logEvent(event, parameters: itemAnalyticsParameters(item));
  }

  RecurringItem _copy(
    RecurringItem item, {
    ItemStatus? status,
    DateTime? nextDueDate,
    required DateTime updatedAt,
  }) {
    return RecurringItem(
      id: item.id,
      name: item.name,
      type: item.type,
      amount: item.amount,
      currencyCode: item.currencyCode,
      frequency: item.frequency,
      interval: item.interval,
      startDate: item.startDate,
      nextDueDate: nextDueDate ?? item.nextDueDate,
      status: status ?? item.status,
      isTrial: item.isTrial,
      trialEndDate: item.trialEndDate,
      remindersEnabled: item.remindersEnabled,
      reminderDaysBefore: item.reminderDaysBefore,
      reminderMinuteOfDay: item.reminderMinuteOfDay,
      categoryId: item.categoryId,
      notes: item.notes,
      logoKey: item.logoKey,
      createdAt: item.createdAt,
      updatedAt: updatedAt,
    );
  }
}

final subscriptionActionsProvider = Provider<SubscriptionActions>(
  SubscriptionActions.new,
);
