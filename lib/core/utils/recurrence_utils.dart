import '../../features/subscriptions/domain/recurring_enums.dart';

/// Drops the time of day, keeping the local calendar date.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Adds [months] to [date], clamping to the last valid day of the target month
/// (31 Jan + 1 month = 28/29 Feb).
///
/// [anchorDay] is the day-of-month the schedule is meant to land on. Pass the
/// start date's day so a clamped date recovers afterwards (31 Jan -> 28 Feb ->
/// 31 Mar) instead of drifting to the 28th. Defaults to `date.day`.
DateTime addMonthsClamped(DateTime date, int months, {int? anchorDay}) {
  final anchor = anchorDay ?? date.day;
  final monthIndex = date.year * 12 + (date.month - 1) + months;
  final year = monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final day = anchor < daysInMonth(year, month)
      ? anchor
      : daysInMonth(year, month);
  return DateTime(year, month, day);
}

/// Next due date after [fromDate].
///
/// Call this with the *previous due date* (not today) so marking a payment
/// late does not shift the schedule. Pass [anchorDay] (usually the item's
/// start date day) for month-based frequencies.
DateTime calculateNextDueDate({
  required DateTime fromDate,
  required BillingFrequency frequency,
  int interval = 1,
  int? anchorDay,
}) {
  if (interval < 1) {
    throw ArgumentError.value(interval, 'interval', 'must be at least 1');
  }
  if (anchorDay != null && (anchorDay < 1 || anchorDay > 31)) {
    throw ArgumentError.value(anchorDay, 'anchorDay', 'must be 1-31');
  }

  final from = dateOnly(fromDate);

  switch (frequency) {
    case BillingFrequency.weekly:
      return DateTime(from.year, from.month, from.day + 7 * interval);
    case BillingFrequency.custom:
      return DateTime(from.year, from.month, from.day + interval);
    case BillingFrequency.monthly:
      return addMonthsClamped(from, interval, anchorDay: anchorDay);
    case BillingFrequency.quarterly:
      return addMonthsClamped(from, 3 * interval, anchorDay: anchorDay);
    case BillingFrequency.semiAnnual:
      return addMonthsClamped(from, 6 * interval, anchorDay: anchorDay);
    case BillingFrequency.yearly:
      return addMonthsClamped(from, 12 * interval, anchorDay: anchorDay);
  }
}
