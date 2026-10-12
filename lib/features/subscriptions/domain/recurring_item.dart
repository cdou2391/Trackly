import 'recurring_enums.dart';

/// When reminders are delivered unless the item says otherwise: 09:00, as
/// minutes after midnight (the item's reminder time is a local wall-clock time).
const defaultReminderMinuteOfDay = 9 * 60;

/// A subscription or recurring bill.
///
/// Dates are calendar dates (local, time of day ignored), so a charge on "the
/// 15th" stays on the 15th regardless of timezone.
class RecurringItem {
  RecurringItem({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.frequency,
    this.interval = 1,
    required this.startDate,
    required this.nextDueDate,
    this.status = ItemStatus.active,
    this.isTrial = false,
    this.trialEndDate,
    this.remindersEnabled = true,
    this.reminderDaysBefore = 3,
    this.reminderMinuteOfDay = defaultReminderMinuteOfDay,
    this.categoryId,
    this.notes,
    this.logoKey,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(interval >= 1, 'interval must be at least 1'),
       assert(amount >= 0, 'amount must not be negative'),
       assert(!isTrial || trialEndDate != null, 'a trial needs a trialEndDate'),
       assert(
         reminderMinuteOfDay >= 0 && reminderMinuteOfDay < 24 * 60,
         'reminderMinuteOfDay must be 0-1439',
       );

  final String id;
  final String name;
  final RecurringItemType type;

  final double amount;
  final String currencyCode;

  final BillingFrequency frequency;

  /// Repeat every `interval` units of [frequency] (for `custom`, days).
  final int interval;

  final DateTime startDate;
  final DateTime nextDueDate;

  final ItemStatus status;

  final bool isTrial;
  final DateTime? trialEndDate;

  final bool remindersEnabled;
  final int reminderDaysBefore;

  /// Local time of day the reminders are delivered, as minutes after midnight
  /// (540 is 09:00).
  final int reminderMinuteOfDay;

  final String? categoryId;
  final String? notes;

  /// Key into the bundled service catalog. Null for custom services.
  final String? logoKey;

  final DateTime createdAt;
  final DateTime updatedAt;
}
