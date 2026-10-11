import 'dart:convert';

import '../../features/subscriptions/domain/recurring_enums.dart';
import '../../features/subscriptions/domain/recurring_item.dart';
import '../utils/cost_utils.dart';
import '../utils/recurrence_utils.dart';

/// Local time of day (hour) that reminders are delivered.
const reminderHour = 9;

enum ReminderType {
  /// "Due in N days": sent N days ahead, as set on the item.
  dueSoon('due_soon'),

  /// "Due today": sent on the day itself.
  dueToday('due_today'),

  /// "Trial ends in N days": the free-trial version of [dueSoon].
  trialEnding('trial_ending');

  const ReminderType(this.wireName);

  /// Stable name used in notification payloads and analytics.
  final String wireName;

  static ReminderType? fromWireName(String? name) {
    for (final type in values) {
      if (type.wireName == name) return type;
    }
    return null;
  }
}

/// One reminder an item should have, before it is turned into text.
class PlannedReminder {
  const PlannedReminder({
    required this.itemId,
    required this.type,
    required this.when,
    required this.daysAhead,
  });

  final String itemId;
  final ReminderType type;

  /// Local wall-clock time to deliver it (the reminder day at [reminderHour]).
  final DateTime when;

  /// How many days before the due date it is sent (0 for [ReminderType.dueToday]).
  final int daysAhead;

  /// Stable notification id for this item and type.
  int get id => notificationIdFor(itemId, type);
}

/// The reminders [item] should have at time [now]. Pure, so it is easy to test.
///
/// - Only active items with reminders turned on have any.
/// - A "N days before" reminder is planned when N > 0, and a "due today" one
///   always, so "same day" gives just the latter and never two on one day.
/// - While a free trial runs, the "N days before" reminder says the trial is
///   ending (the first charge is the day it ends).
/// - Reminders whose time has already passed are left out.
List<PlannedReminder> planReminders(
  RecurringItem item, {
  required DateTime now,
}) {
  if (item.status != ItemStatus.active || !item.remindersEnabled) {
    return const [];
  }

  final due = dateOnly(item.nextDueDate);
  final trial = isInActiveTrial(item, now);
  final days = item.reminderDaysBefore;

  DateTime at(DateTime day) =>
      DateTime(day.year, day.month, day.day, reminderHour);

  final reminders = [
    if (days > 0)
      PlannedReminder(
        itemId: item.id,
        type: trial ? ReminderType.trialEnding : ReminderType.dueSoon,
        when: at(DateTime(due.year, due.month, due.day - days)),
        daysAhead: days,
      ),
    PlannedReminder(
      itemId: item.id,
      type: ReminderType.dueToday,
      when: at(due),
      daysAhead: 0,
    ),
  ];

  return reminders.where((r) => r.when.isAfter(now)).toList();
}

/// A stable, positive 31-bit notification id for [itemId] and [type].
///
/// Android notification ids are integers, so item UUIDs cannot be used
/// directly. FNV-1a over the id and type gives the same value every time, so a
/// reminder can be found and replaced later.
int notificationIdFor(String itemId, ReminderType type) {
  var hash = 0x811C9DC5;
  for (final byte in utf8.encode('$itemId|${type.wireName}')) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash & 0x7FFFFFFF;
}

/// The data carried by a reminder notification. Deliberately small: no names,
/// notes or amounts, only what is needed to open the item.
class ReminderPayload {
  const ReminderPayload({
    required this.itemId,
    required this.type,
    required this.signature,
  });

  final String itemId;
  final ReminderType type;

  /// Fingerprint of the time and text this reminder was scheduled with, so a
  /// later launch can tell whether it is still up to date.
  final String signature;

  String encode() => jsonEncode({
    'item_id': itemId,
    'notification_type': type.wireName,
    'sig': signature,
  });

  /// Null for anything that is not a well-formed reminder payload.
  static ReminderPayload? parse(String? text) {
    if (text == null || text.isEmpty) return null;
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, dynamic>) return null;
      final itemId = json['item_id'];
      final type = ReminderType.fromWireName(
        json['notification_type'] as String?,
      );
      if (itemId is! String || itemId.isEmpty || type == null) return null;
      return ReminderPayload(
        itemId: itemId,
        type: type,
        signature: json['sig'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// A short fingerprint of the delivery time and text (FNV-1a, hex).
String reminderSignature(DateTime when, String title, String body) {
  var hash = 0x811C9DC5;
  for (final byte in utf8.encode('${when.toIso8601String()}|$title|$body')) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
