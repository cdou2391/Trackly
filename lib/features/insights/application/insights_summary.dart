import '../../../core/utils/cost_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../subscriptions/domain/recurring_enums.dart';
import '../../subscriptions/domain/recurring_item.dart';

/// Items without a category are grouped under this system category.
const uncategorizedId = 'other';

/// One category's share of the monthly cost, in a single currency.
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.monthlyAmount,
    required this.count,
  });

  final String categoryId;
  final double monthlyAmount;
  final int count;
}

class InsightsSummary {
  const InsightsSummary({
    required this.monthlyTotalsByCurrency,
    required this.yearlyTotalsByCurrency,
    required this.categoryBreakdown,
    required this.activeCount,
    required this.trialCount,
    required this.upcomingCount,
    required this.hasItems,
  });

  final Map<String, double> monthlyTotalsByCurrency;
  final Map<String, double> yearlyTotalsByCurrency;

  /// Per currency, largest category first. Currencies are never merged.
  final Map<String, List<CategoryTotal>> categoryBreakdown;

  /// Active items that are not in a free trial. Paused items are excluded
  /// (unlike the Home Active card, which counts them).
  final int activeCount;

  /// Active items whose free trial is still running.
  final int trialCount;

  /// Charges due from today to one calendar month ahead (the Home Upcoming
  /// window), not capped. Counts every charge, including a weekly item's
  /// repeats, a trial's first charge and one overdue charge per item.
  final int upcomingCount;

  /// False only when nothing has been added yet (drives the empty state).
  final bool hasItems;
}

/// Builds the Insights state from raw rows. Pure, so it is easy to test.
///
/// Totals and the breakdown follow the same rule as the Home hero: only
/// active items that are not in a free trial count.
InsightsSummary buildInsightsSummary({
  required List<RecurringItem> items,
  required DateTime now,
}) {
  final today = dateOnly(now);
  final cutoff = upcomingCutoff(today);

  final byCurrency = <String, Map<String, ({double amount, int count})>>{};
  var active = 0;
  var trial = 0;
  var upcoming = 0;

  for (final item in items) {
    if (item.status != ItemStatus.active) continue;

    if (isInActiveTrial(item, now)) {
      trial++;
    } else {
      active++;
      final categories = byCurrency.putIfAbsent(item.currencyCode, () => {});
      final key = item.categoryId ?? uncategorizedId;
      final current = categories[key];
      categories[key] = (
        amount: (current?.amount ?? 0) + calculateMonthlyEquivalent(item),
        count: (current?.count ?? 0) + 1,
      );
    }

    if (dateOnly(item.nextDueDate).isBefore(today)) upcoming++;
    upcoming += occurrencesInRange(
      firstDue: item.nextDueDate,
      frequency: item.frequency,
      interval: item.interval,
      anchorDay: item.startDate.day,
      from: today,
      to: cutoff,
    ).length;
  }

  final breakdown = {
    for (final entry in byCurrency.entries)
      entry.key: [
        for (final category in entry.value.entries)
          CategoryTotal(
            categoryId: category.key,
            monthlyAmount: category.value.amount,
            count: category.value.count,
          ),
      ]..sort(_largestFirst),
  };

  return InsightsSummary(
    monthlyTotalsByCurrency: monthlyTotalsByCurrency(items, now: now),
    yearlyTotalsByCurrency: yearlyTotalsByCurrency(items, now: now),
    categoryBreakdown: breakdown,
    activeCount: active,
    trialCount: trial,
    upcomingCount: upcoming,
    hasItems: items.isNotEmpty,
  );
}

int _largestFirst(CategoryTotal a, CategoryTotal b) {
  final byAmount = b.monthlyAmount.compareTo(a.monthlyAmount);
  return byAmount != 0 ? byAmount : a.categoryId.compareTo(b.categoryId);
}
