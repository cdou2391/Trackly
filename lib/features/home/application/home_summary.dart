import '../../../core/utils/cost_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../payments/domain/payment.dart';
import '../../subscriptions/domain/recurring_enums.dart';
import '../../subscriptions/domain/recurring_item.dart';

class RecentPayment {
  const RecentPayment({required this.payment, required this.item});

  final Payment payment;
  final RecurringItem item;
}

class HomeSummary {
  const HomeSummary({
    required this.monthlyTotalsByCurrency,
    required this.yearlyTotalsByCurrency,
    required this.activeCount,
    required this.trialCount,
    required this.cancelledCount,
    required this.upcoming,
    required this.recentPayments,
    required this.hasItems,
  });

  final Map<String, double> monthlyTotalsByCurrency;
  final Map<String, double> yearlyTotalsByCurrency;

  /// Active and paused items that are not in a free trial.
  final int activeCount;

  /// Active items whose free trial is still running.
  final int trialCount;
  final int cancelledCount;

  final List<RecurringItem> upcoming;
  final List<RecentPayment> recentPayments;

  /// False only when nothing has been added yet (drives the empty state).
  final bool hasItems;
}

/// Builds the Home state from raw rows. Pure, so it is easy to test.
///
/// Decisions: paused items count in Active; a trial counts only in Trial;
/// Upcoming is the next [upcomingLimit] active items due within one calendar
/// month (see [upcomingCutoff]), overdue ones included.
HomeSummary buildHomeSummary({
  required List<RecurringItem> items,
  required List<Payment> recentPaid,
  required DateTime now,
  int upcomingLimit = 5,
}) {
  final today = dateOnly(now);
  final cutoff = upcomingCutoff(today);

  var active = 0;
  var trial = 0;
  var cancelled = 0;
  for (final item in items) {
    switch (item.status) {
      case ItemStatus.cancelled:
        cancelled++;
      case ItemStatus.paused:
        active++;
      case ItemStatus.active:
        if (isInActiveTrial(item, now)) {
          trial++;
        } else {
          active++;
        }
    }
  }

  final upcoming =
      items
          .where(
            (item) =>
                item.status == ItemStatus.active &&
                !dateOnly(item.nextDueDate).isAfter(cutoff),
          )
          .toList()
        ..sort((a, b) {
          final byDate = a.nextDueDate.compareTo(b.nextDueDate);
          return byDate != 0 ? byDate : a.name.compareTo(b.name);
        });

  final itemsById = {for (final item in items) item.id: item};
  final recent = <RecentPayment>[
    for (final payment in recentPaid)
      if (itemsById[payment.recurringItemId] case final item?)
        RecentPayment(payment: payment, item: item),
  ];

  return HomeSummary(
    monthlyTotalsByCurrency: monthlyTotalsByCurrency(items, now: now),
    yearlyTotalsByCurrency: yearlyTotalsByCurrency(items, now: now),
    activeCount: active,
    trialCount: trial,
    cancelledCount: cancelled,
    upcoming: upcoming.take(upcomingLimit).toList(),
    recentPayments: recent,
    hasItems: items.isNotEmpty,
  );
}
