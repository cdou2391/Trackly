import '../../../core/utils/cost_utils.dart';
import '../domain/recurring_enums.dart';
import '../domain/recurring_item.dart';

/// Filters mirror the Home cards: Active (paused items count here, with a
/// Paused chip), Trial and Cancelled.
enum ItemFilter {
  all,
  active,
  trial,
  cancelled;

  /// Parses the `filter` query parameter; anything unknown means [all].
  static ItemFilter parse(String? value) {
    for (final filter in ItemFilter.values) {
      if (filter.name == value) return filter;
    }
    return ItemFilter.all;
  }
}

/// Items for [filter], grouped live first (soonest due first), then paused,
/// then cancelled, with names breaking ties.
List<RecurringItem> filterItems(
  Iterable<RecurringItem> items,
  ItemFilter filter,
  DateTime now,
) {
  bool matches(RecurringItem item) {
    final trial =
        item.status == ItemStatus.active && isInActiveTrial(item, now);
    return switch (filter) {
      ItemFilter.all => true,
      ItemFilter.cancelled => item.status == ItemStatus.cancelled,
      ItemFilter.trial => trial,
      ItemFilter.active =>
        item.status == ItemStatus.paused ||
            (item.status == ItemStatus.active && !trial),
    };
  }

  int rank(RecurringItem item) => switch (item.status) {
    ItemStatus.active => 0,
    ItemStatus.paused => 1,
    ItemStatus.cancelled => 2,
  };

  return items.where(matches).toList()..sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    final byDate = a.nextDueDate.compareTo(b.nextDueDate);
    return byDate != 0 ? byDate : a.name.compareTo(b.name);
  });
}
