import '../../../core/utils/recurrence_utils.dart';
import '../domain/recurring_enums.dart';
import '../domain/recurring_item.dart';
import '../domain/service_catalog.dart';

/// What the user changed in the edit form.
class EditedSubscription {
  const EditedSubscription({
    required this.name,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.frequency,
    required this.nextDueDate,
    required this.remindersEnabled,
    required this.reminderDaysBefore,
    this.reminderMinuteOfDay = defaultReminderMinuteOfDay,
    this.isTrial = false,
    this.trialEndDate,
    this.categoryId,
    this.logoKey,
    this.notes,
  });

  final String name;
  final RecurringItemType type;
  final double amount;
  final String currencyCode;
  final BillingFrequency frequency;
  final DateTime nextDueDate;
  final bool remindersEnabled;
  final int reminderDaysBefore;
  final int reminderMinuteOfDay;
  final bool isTrial;
  final DateTime? trialEndDate;
  final String? categoryId;
  final String? logoKey;
  final String? notes;
}

/// Applies [edit] to [original]. Pure, so it is easy to test.
///
/// Kept from the original: id, status, interval and creation time. Moving the
/// next charge to a different day of the month also moves the billing anchor
/// (the start date), so later months follow the new day instead of snapping
/// back to the old one.
RecurringItem buildEditedItem(
  RecurringItem original,
  EditedSubscription edit, {
  required DateTime now,
}) {
  final trialEnd = edit.isTrial ? edit.trialEndDate : null;
  if (edit.isTrial && trialEnd == null) {
    throw ArgumentError('A trial needs a trial end date.');
  }

  // A trial's first charge is the day it ends.
  final nextDue = dateOnly(trialEnd ?? edit.nextDueDate);
  final dayChanged = nextDue.day != original.nextDueDate.day;
  final startDate = trialEnd != null || dayChanged
      ? nextDue
      : original.startDate;

  final notes = edit.notes?.trim();

  return RecurringItem(
    id: original.id,
    name: edit.name.trim(),
    type: edit.type,
    amount: edit.amount,
    currencyCode: edit.currencyCode,
    frequency: edit.frequency,
    interval: original.interval,
    startDate: startDate,
    nextDueDate: nextDue,
    status: original.status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd == null ? null : dateOnly(trialEnd),
    remindersEnabled: edit.remindersEnabled,
    reminderDaysBefore: edit.reminderDaysBefore,
    reminderMinuteOfDay: edit.reminderMinuteOfDay,
    categoryId: edit.categoryId,
    notes: (notes == null || notes.isEmpty) ? null : notes,
    logoKey: edit.logoKey ?? findServiceByName(edit.name)?.key,
    createdAt: original.createdAt,
    updatedAt: now,
  );
}
