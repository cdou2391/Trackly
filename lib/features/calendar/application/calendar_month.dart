import '../../../core/utils/cost_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../payments/domain/payment.dart';
import '../../subscriptions/domain/recurring_enums.dart';
import '../../subscriptions/domain/recurring_item.dart';

enum CalendarEntryStatus {
  /// A recorded payment.
  paid,

  /// A charge the user skipped. Shown, but never counted in the totals.
  skipped,

  /// A scheduled charge that is due today or later.
  due,

  /// A scheduled charge whose date has passed without being recorded.
  overdue,
}

/// One charge on the calendar: either something already recorded (paid or
/// skipped) or a charge projected from an active item's schedule.
class CalendarEntry {
  const CalendarEntry({
    required this.item,
    required this.date,
    required this.amount,
    required this.currencyCode,
    required this.status,
    required this.countsInTotal,
  });

  final RecurringItem item;
  final DateTime date;
  final double amount;
  final String currencyCode;
  final CalendarEntryStatus status;

  /// False for skipped charges and charges made while a free trial still
  /// runs, which are left out of every total (as on Home and Insights).
  final bool countsInTotal;

  /// Not yet recorded, so still to pay.
  bool get isOpen =>
      status == CalendarEntryStatus.due ||
      status == CalendarEntryStatus.overdue;
}

/// Everything the Calendar shows for one month.
class CalendarMonth {
  CalendarMonth({required this.month, required List<CalendarEntry> entries})
    : entries = List.unmodifiable(entries);

  /// The first day of the month.
  final DateTime month;

  /// Sorted by date, then by name.
  final List<CalendarEntry> entries;

  DateTime get lastDay => DateTime(month.year, month.month + 1, 0);

  /// Entries on one calendar day.
  List<CalendarEntry> entriesOn(DateTime day) {
    final target = dateOnly(day);
    return [
      for (final entry in entries)
        if (entry.date == target) entry,
    ];
  }

  /// Everything scheduled this month, paid or not: what the month costs.
  Map<String, double> get totalByCurrency =>
      _sum(entries.where((e) => e.countsInTotal));

  /// What is still to pay from [from] (inclusive) to the end of the month.
  /// Charges already paid or skipped are not "left". A [from] before the month
  /// covers the whole month; one after it leaves nothing.
  Map<String, double> leftFrom(DateTime from) {
    final start = dateOnly(from);
    return _sum(
      entries.where(
        (e) => e.countsInTotal && e.isOpen && !e.date.isBefore(start),
      ),
    );
  }

  static Map<String, double> _sum(Iterable<CalendarEntry> entries) {
    final totals = <String, double>{};
    for (final entry in entries) {
      totals.update(
        entry.currencyCode,
        (sum) => sum + entry.amount,
        ifAbsent: () => entry.amount,
      );
    }
    return totals;
  }
}

/// Builds the Calendar for [month] from raw rows. Pure, so it is easy to test.
///
/// - Recorded payments and skips are shown on the date they were due.
/// - Active items are projected along their own schedule from their next due
///   date, so a weekly item appears every week and a monthly one in any month
///   ahead. Dates before [today] that are still unrecorded are overdue.
/// - Paused and cancelled items have no scheduled charges, but keep their
///   recorded history.
/// - A charge made while a free trial runs (up to and including its end date)
///   is shown but not counted in the totals.
CalendarMonth buildCalendarMonth({
  required List<RecurringItem> items,
  required List<Payment> payments,
  required DateTime month,
  required DateTime today,
}) {
  final first = DateTime(month.year, month.month);
  final last = DateTime(month.year, month.month + 1, 0);
  final now = dateOnly(today);
  final itemsById = {for (final item in items) item.id: item};

  final entries = <CalendarEntry>[];

  for (final payment in payments) {
    final item = itemsById[payment.recurringItemId];
    final due = dateOnly(payment.dueDate);
    if (item == null || due.isBefore(first) || due.isAfter(last)) continue;
    if (payment.status == PaymentStatus.upcoming) continue;

    final paid = payment.status == PaymentStatus.paid;
    entries.add(
      CalendarEntry(
        item: item,
        date: due,
        amount: payment.amount,
        currencyCode: payment.currencyCode,
        status: paid ? CalendarEntryStatus.paid : CalendarEntryStatus.skipped,
        countsInTotal: paid,
      ),
    );
  }

  for (final item in items) {
    if (item.status != ItemStatus.active) continue;

    final dates = occurrencesInRange(
      firstDue: item.nextDueDate,
      frequency: item.frequency,
      interval: item.interval,
      anchorDay: item.startDate.day,
      from: first,
      to: last,
    );
    for (final date in dates) {
      entries.add(
        CalendarEntry(
          item: item,
          date: date,
          amount: item.amount,
          currencyCode: item.currencyCode,
          status: date.isBefore(now)
              ? CalendarEntryStatus.overdue
              : CalendarEntryStatus.due,
          countsInTotal: !isInActiveTrial(item, date),
        ),
      );
    }
  }

  entries.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.item.name.compareTo(b.item.name);
  });

  return CalendarMonth(month: first, entries: entries);
}
