import 'recurring_enums.dart';

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
    this.categoryId,
    this.notes,
    this.logoKey,
    required this.createdAt,
    required this.updatedAt,
  })  : assert(interval >= 1, 'interval must be at least 1'),
        assert(amount >= 0, 'amount must not be negative'),
        assert(
          !isTrial || trialEndDate != null,
          'a trial needs a trialEndDate',
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

  final String? categoryId;
  final String? notes;

  /// Key into the bundled service catalog. Null for custom services.
  final String? logoKey;

  final DateTime createdAt;
  final DateTime updatedAt;
}
