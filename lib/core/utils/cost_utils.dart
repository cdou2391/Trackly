import '../../features/subscriptions/domain/recurring_enums.dart';
import '../../features/subscriptions/domain/recurring_item.dart';
import 'recurrence_utils.dart';

/// Average months per unit of each frequency (`custom` is per day).
double _monthsPerUnit(BillingFrequency frequency) {
  switch (frequency) {
    case BillingFrequency.weekly:
      return 12 / 52;
    case BillingFrequency.monthly:
      return 1;
    case BillingFrequency.quarterly:
      return 3;
    case BillingFrequency.semiAnnual:
      return 6;
    case BillingFrequency.yearly:
      return 12;
    case BillingFrequency.custom:
      return 12 / 365;
  }
}

/// What the item costs per month, ignoring its status.
double calculateMonthlyEquivalent(RecurringItem item) {
  return item.amount / (_monthsPerUnit(item.frequency) * item.interval);
}

double calculateAnnualEquivalent(RecurringItem item) {
  return calculateMonthlyEquivalent(item) * 12;
}

/// True while the free trial is still running. The trial end date itself still
/// counts as trial; the item is a normal paid item from the day after.
bool isInActiveTrial(RecurringItem item, DateTime now) {
  final end = item.trialEndDate;
  if (!item.isTrial || end == null) return false;
  return !dateOnly(now).isAfter(dateOnly(end));
}

/// Whether the item counts toward the hero and Insights totals: active, and
/// not currently in a free trial.
bool countsTowardTotals(RecurringItem item, DateTime now) {
  return item.status == ItemStatus.active && !isInActiveTrial(item, now);
}

/// Monthly cost per currency. Currencies are never converted or merged.
Map<String, double> monthlyTotalsByCurrency(
  Iterable<RecurringItem> items, {
  required DateTime now,
}) {
  final totals = <String, double>{};
  for (final item in items) {
    if (!countsTowardTotals(item, now)) continue;
    totals.update(
      item.currencyCode,
      (sum) => sum + calculateMonthlyEquivalent(item),
      ifAbsent: () => calculateMonthlyEquivalent(item),
    );
  }
  return totals;
}

Map<String, double> yearlyTotalsByCurrency(
  Iterable<RecurringItem> items, {
  required DateTime now,
}) {
  return {
    for (final entry in monthlyTotalsByCurrency(items, now: now).entries)
      entry.key: entry.value * 12,
  };
}
