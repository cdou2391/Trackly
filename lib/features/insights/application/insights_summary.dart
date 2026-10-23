import '../../../core/utils/cost_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../calendar/application/calendar_month.dart';
import '../../payments/domain/payment.dart';
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

/// One kind of item's share of the monthly cost, in a single currency.
class TypeTotal {
  const TypeTotal({
    required this.type,
    required this.monthlyAmount,
    required this.count,
  });

  final RecurringItemType type;
  final double monthlyAmount;
  final int count;
}

/// An item and what it costs per month, for the "Biggest costs" list.
class CostlyItem {
  const CostlyItem({required this.item, required this.monthlyAmount});

  final RecurringItem item;
  final double monthlyAmount;
}

/// What has been paid so far this month against what the month costs, in a
/// single currency. [total] is the Calendar's "Total this month".
class MonthProgress {
  const MonthProgress({
    required this.paid,
    required this.total,
    this.weeks = const [],
  });

  final double paid;
  final double total;

  /// The month in blocks of seven days (1-7, 8-14, ...), for the bar chart.
  final List<WeekBucket> weeks;
}

/// One block of days of the month: what it costs and what is already paid.
class WeekBucket {
  const WeekBucket({
    required this.startDay,
    required this.endDay,
    required this.total,
    required this.paid,
  });

  final int startDay;
  final int endDay;
  final double total;
  final double paid;
}

/// The month cut into blocks of seven days; the last one runs to month end.
List<WeekBucket> weekBuckets(
  CalendarMonth month,
  String currency,
  DateTime firstOfMonth,
) {
  final daysInMonth = DateTime(
    firstOfMonth.year,
    firstOfMonth.month + 1,
    0,
  ).day;
  // A trailing sliver of one or two days joins the block before it.
  final starts = [1, 8, 15, 22, if (daysInMonth >= 31) 29];
  return [
    for (final start in starts)
      () {
        final end = start == starts.last ? daysInMonth : start + 6;
        var total = 0.0;
        var paid = 0.0;
        for (final entry in month.entries) {
          if (entry.currencyCode != currency) continue;
          final day = entry.date.day;
          if (day < start || day > end) continue;
          if (entry.countsInTotal) total += entry.amount;
          if (entry.status == CalendarEntryStatus.paid) paid += entry.amount;
        }
        return WeekBucket(
          startDay: start,
          endDay: end,
          total: total,
          paid: paid,
        );
      }(),
  ];
}

/// How many items the "Biggest costs" list shows per currency.
const biggestCostsLimit = 5;

class InsightsSummary {
  const InsightsSummary({
    required this.monthlyTotalsByCurrency,
    required this.yearlyTotalsByCurrency,
    required this.categoryBreakdown,
    required this.typeBreakdown,
    required this.biggestCosts,
    required this.monthProgress,
    required this.activeCount,
    required this.trialCount,
    required this.upcomingCount,
    required this.hasItems,
  });

  final Map<String, double> monthlyTotalsByCurrency;
  final Map<String, double> yearlyTotalsByCurrency;

  /// Per currency, largest category first. Currencies are never merged.
  final Map<String, List<CategoryTotal>> categoryBreakdown;

  /// Per currency, subscriptions and bills with their monthly cost, largest
  /// first. Same items as the category breakdown.
  final Map<String, List<TypeTotal>> typeBreakdown;

  /// Per currency, the costliest items per month (at most
  /// [biggestCostsLimit]), largest first. A currency with a single counted
  /// item has no list: there is nothing to rank.
  final Map<String, List<CostlyItem>> biggestCosts;

  /// Per currency, paid so far this month and the month's total. Only
  /// currencies with something to pay this month are listed.
  final Map<String, MonthProgress> monthProgress;

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
  List<Payment> payments = const [],
}) {
  final today = dateOnly(now);
  final cutoff = upcomingCutoff(today);

  final byCurrency = <String, Map<String, ({double amount, int count})>>{};
  final byType =
      <String, Map<RecurringItemType, ({double amount, int count})>>{};
  final costly = <String, List<CostlyItem>>{};
  var active = 0;
  var trial = 0;
  var upcoming = 0;

  for (final item in items) {
    if (item.status != ItemStatus.active) continue;

    if (isInActiveTrial(item, now)) {
      trial++;
    } else {
      active++;
      final monthly = calculateMonthlyEquivalent(item);
      final categories = byCurrency.putIfAbsent(item.currencyCode, () => {});
      final key = item.categoryId ?? uncategorizedId;
      final current = categories[key];
      categories[key] = (
        amount: (current?.amount ?? 0) + monthly,
        count: (current?.count ?? 0) + 1,
      );

      final types = byType.putIfAbsent(item.currencyCode, () => {});
      final currentType = types[item.type];
      types[item.type] = (
        amount: (currentType?.amount ?? 0) + monthly,
        count: (currentType?.count ?? 0) + 1,
      );

      costly
          .putIfAbsent(item.currencyCode, () => [])
          .add(CostlyItem(item: item, monthlyAmount: monthly));
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

  final typeBreakdown = {
    for (final entry in byType.entries)
      entry.key:
          [
            for (final type in entry.value.entries)
              TypeTotal(
                type: type.key,
                monthlyAmount: type.value.amount,
                count: type.value.count,
              ),
          ]..sort((a, b) {
            final byAmount = b.monthlyAmount.compareTo(a.monthlyAmount);
            return byAmount != 0
                ? byAmount
                : a.type.index.compareTo(b.type.index);
          }),
  };

  final biggestCosts = {
    for (final entry in costly.entries)
      if (entry.value.length >= 2)
        entry.key:
            ([...entry.value]..sort((a, b) {
                  final byAmount = b.monthlyAmount.compareTo(a.monthlyAmount);
                  return byAmount != 0
                      ? byAmount
                      : a.item.name.toLowerCase().compareTo(
                          b.item.name.toLowerCase(),
                        );
                }))
                .take(biggestCostsLimit)
                .toList(),
  };

  // The same month the Calendar shows, so the two screens agree.
  final month = buildCalendarMonth(
    items: items,
    payments: payments,
    month: DateTime(today.year, today.month),
    today: now,
  );
  final paidByCurrency = <String, double>{};
  for (final entry in month.entries) {
    if (entry.status == CalendarEntryStatus.paid) {
      paidByCurrency.update(
        entry.currencyCode,
        (sum) => sum + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }
  }
  final monthProgress = {
    for (final total in month.totalByCurrency.entries)
      if (total.value > 0)
        total.key: MonthProgress(
          paid: paidByCurrency[total.key] ?? 0,
          total: total.value,
          weeks: weekBuckets(
            month,
            total.key,
            DateTime(today.year, today.month),
          ),
        ),
  };

  return InsightsSummary(
    monthlyTotalsByCurrency: monthlyTotalsByCurrency(items, now: now),
    yearlyTotalsByCurrency: yearlyTotalsByCurrency(items, now: now),
    categoryBreakdown: breakdown,
    typeBreakdown: typeBreakdown,
    biggestCosts: biggestCosts,
    monthProgress: monthProgress,
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
