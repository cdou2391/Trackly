import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/error/error_reporter.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../home/application/home_providers.dart';
import '../domain/recurring_enums.dart';
import '../domain/recurring_item.dart';

/// Which form created the item; sent to analytics as `entry_method`.
enum EntryMethod {
  quickAdd('quick_add'),
  fullForm('full_form');

  const EntryMethod(this.analyticsValue);
  final String analyticsValue;
}

/// What the user entered when adding a subscription or bill.
class NewSubscription {
  const NewSubscription({
    required this.name,
    required this.amount,
    required this.currencyCode,
    required this.frequency,
    required this.startDate,
    required this.entryMethod,
    this.type = RecurringItemType.subscription,
    this.categoryId,
    this.logoKey,
    this.remindersEnabled = true,
    this.reminderDaysBefore = 3,
    this.isTrial = false,
    this.trialEndDate,
    this.notes,
  });

  final String name;
  final double amount;
  final String currencyCode;
  final BillingFrequency frequency;

  /// The most recent (or first) charge date. Ignored for trials, whose first
  /// charge is the day the trial ends.
  final DateTime startDate;
  final EntryMethod entryMethod;
  final RecurringItemType type;
  final String? categoryId;
  final String? logoKey;
  final bool remindersEnabled;
  final int reminderDaysBefore;
  final bool isTrial;
  final DateTime? trialEndDate;
  final String? notes;
}

/// Turns user input into a [RecurringItem]. Pure, so it is easy to test.
///
/// A free trial's first charge is the day it ends, so for trials that date is
/// both the start date (the billing anchor) and the next due date.
RecurringItem buildRecurringItem(
  NewSubscription input, {
  required String id,
  required DateTime now,
}) {
  final trialEnd = input.isTrial ? input.trialEndDate : null;
  if (input.isTrial && trialEnd == null) {
    throw ArgumentError('A trial needs a trial end date.');
  }

  final start = trialEnd != null
      ? dateOnly(trialEnd)
      : dateOnly(input.startDate);
  final notes = input.notes?.trim();

  return RecurringItem(
    id: id,
    name: input.name.trim(),
    type: input.type,
    amount: input.amount,
    currencyCode: input.currencyCode,
    frequency: input.frequency,
    startDate: start,
    nextDueDate: trialEnd != null
        ? start
        : firstDueDate(
            startDate: start,
            frequency: input.frequency,
            today: now,
          ),
    isTrial: trialEnd != null,
    trialEndDate: trialEnd == null ? null : dateOnly(trialEnd),
    remindersEnabled: input.remindersEnabled,
    reminderDaysBefore: input.reminderDaysBefore,
    categoryId: input.categoryId,
    notes: (notes == null || notes.isEmpty) ? null : notes,
    logoKey: input.logoKey,
    createdAt: now,
    updatedAt: now,
  );
}

/// Saves new items from any entry point (Quick Add or the add panel).
class SubscriptionCreator {
  SubscriptionCreator(this._ref);

  final Ref _ref;

  /// Saves the item and logs analytics. On failure the error is reported to
  /// Sentry and rethrown so the caller can show a message.
  Future<RecurringItem> create(NewSubscription input) async {
    final now = _ref.read(nowProvider)();
    final item = buildRecurringItem(input, id: const Uuid().v4(), now: now);

    final errors = _ref.read(errorReporterProvider);
    try {
      errors.addBreadcrumb('item_save_started', category: 'ui');
      await _ref.read(appDatabaseProvider).recurringItemsDao.insertItem(item);
    } catch (error, stackTrace) {
      await errors.captureException(error, stackTrace);
      rethrow;
    }

    _logCreated(item, input.entryMethod);
    return item;
  }

  /// Names and notes are never sent; only structured metadata.
  void _logCreated(RecurringItem item, EntryMethod entryMethod) {
    final analytics = _ref.read(analyticsProvider);
    final parameters = <String, Object>{
      'item_type': item.type.name,
      'frequency': item.frequency.name,
      'currency': item.currencyCode,
      'has_reminder': item.remindersEnabled,
      'is_trial': item.isTrial,
      'entry_method': entryMethod.analyticsValue,
      'reminder_days_before': item.reminderDaysBefore,
      'category': ?item.categoryId,
    };

    if (entryMethod == EntryMethod.quickAdd) {
      analytics.logEvent(AnalyticsEvents.quickAddCompleted);
    }
    analytics.logEvent(
      AnalyticsEvents.subscriptionCreated,
      parameters: parameters,
    );
    if (item.type == RecurringItemType.bill) {
      analytics.logEvent(AnalyticsEvents.billCreated, parameters: parameters);
    }
    if (item.isTrial) {
      analytics.logEvent(AnalyticsEvents.trialCreated, parameters: parameters);
    }
  }
}

final subscriptionCreatorProvider = Provider<SubscriptionCreator>(
  SubscriptionCreator.new,
);
