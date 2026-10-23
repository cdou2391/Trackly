import '../../features/subscriptions/domain/recurring_enums.dart';
import '../../features/subscriptions/domain/recurring_item.dart';
import '../utils/recurrence_utils.dart';

/// The item whose charge comes first: the soonest due date among active items
/// (overdue ones first, since they are the most urgent), ties broken by name
/// so the choice is stable. Null when nothing is active.
RecurringItem? nextPayment(List<RecurringItem> items) {
  RecurringItem? best;
  for (final item in items) {
    if (item.status != ItemStatus.active) continue;
    if (best == null) {
      best = item;
      continue;
    }
    final byDate = dateOnly(item.nextDueDate)
        .compareTo(dateOnly(best.nextDueDate));
    if (byDate < 0 ||
        (byDate == 0 &&
            item.name.toLowerCase().compareTo(best.name.toLowerCase()) < 0)) {
      best = item;
    }
  }
  return best;
}
