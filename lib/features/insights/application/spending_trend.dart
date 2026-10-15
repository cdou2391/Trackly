import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../calendar/application/calendar_month.dart';
import '../../home/application/home_providers.dart';
import '../../payments/domain/payment.dart';
import '../../subscriptions/application/item_providers.dart';
import '../../subscriptions/domain/recurring_item.dart';

/// The ranges the trend can show, in months ending with the current one.
const trendRanges = [3, 6, 12];

/// What one calendar month cost, in a single currency.
class TrendPoint {
  const TrendPoint({required this.month, required this.amount});

  /// The first day of the month.
  final DateTime month;
  final double amount;
}

/// What each of the last months cost, one list per currency (never merged).
class SpendingTrend {
  const SpendingTrend(this.byCurrency);

  /// Oldest month first, one point per month of the range, zero when nothing
  /// was paid or due. Only currencies with something in the range are listed.
  final Map<String, List<TrendPoint>> byCurrency;

  /// A line needs at least two months with something in them to say anything.
  static bool isWorthDrawing(List<TrendPoint> points) =>
      points.where((p) => p.amount > 0).length >= 2;

  /// Currencies with a line worth drawing, sorted.
  List<String> get chartableCurrencies => [
    for (final entry in byCurrency.entries)
      if (isWorthDrawing(entry.value)) entry.key,
  ]..sort();
}

/// Builds the trend for the [months] months ending with the month of [now].
///
/// Each month is the Calendar's "Total this month" (§89), so the two screens
/// agree: a past month is what was recorded as paid in it (plus any charge
/// left overdue), and the current month is what has been paid plus what is
/// still to pay. Skipped charges and charges still to come during a free trial
/// are not counted. Pure, so it is easy to test.
SpendingTrend buildSpendingTrend({
  required List<RecurringItem> items,
  required List<Payment> payments,
  required DateTime now,
  required int months,
}) {
  final series = <String, List<TrendPoint>>{};
  final byMonth = <DateTime, Map<String, double>>{};

  for (var back = months - 1; back >= 0; back--) {
    final month = DateTime(now.year, now.month - back);
    final totals = buildCalendarMonth(
      items: items,
      payments: payments,
      month: month,
      today: now,
    ).totalByCurrency;
    byMonth[month] = totals;
    for (final currency in totals.keys) {
      series.putIfAbsent(currency, () => []);
    }
  }

  for (final currency in series.keys) {
    for (final entry in byMonth.entries) {
      series[currency]!.add(
        TrendPoint(month: entry.key, amount: entry.value[currency] ?? 0),
      );
    }
  }
  return SpendingTrend(series);
}

/// The range the person picked on Insights, kept while the app runs.
class TrendRange extends Notifier<int> {
  @override
  int build() => 6;

  void set(int months) {
    if (trendRanges.contains(months)) state = months;
  }
}

final trendRangeProvider = NotifierProvider<TrendRange, int>(TrendRange.new);

final spendingTrendProvider = Provider<AsyncValue<SpendingTrend>>((ref) {
  final items = ref.watch(recurringItemsProvider);
  final payments = ref.watch(allPaymentsProvider);
  final months = ref.watch(trendRangeProvider);

  final error = items.error ?? payments.error;
  if (error != null && !(items.hasValue && payments.hasValue)) {
    return AsyncValue.error(
      error,
      items.stackTrace ?? payments.stackTrace ?? StackTrace.empty,
    );
  }
  if (!items.hasValue || !payments.hasValue) return const AsyncValue.loading();

  return AsyncValue.data(
    buildSpendingTrend(
      items: items.requireValue,
      payments: payments.requireValue,
      now: ref.watch(nowProvider)(),
      months: months,
    ),
  );
});
