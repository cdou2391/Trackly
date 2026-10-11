import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminder_plan.dart';

/// A reminder ready to hand to the operating system.
class ScheduledReminder {
  const ScheduledReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;

  /// Local wall-clock delivery time.
  final DateTime when;
  final String title;
  final String body;

  /// Encoded [ReminderPayload].
  final String payload;
}

/// A reminder the system has scheduled, as reported back to us.
class PendingReminder {
  const PendingReminder({required this.id, required this.payload});

  final int id;
  final String? payload;
}

/// The user tapped a reminder.
class NotificationTap {
  const NotificationTap({required this.itemId, required this.type});

  final String itemId;
  final ReminderType type;

  /// Null when [payload] is not one of our reminder payloads.
  static NotificationTap? fromPayload(String? payload) {
    final parsed = ReminderPayload.parse(payload);
    if (parsed == null) return null;
    return NotificationTap(itemId: parsed.itemId, type: parsed.type);
  }
}

/// Local (on-device) notifications. Everything here is scheduled on the phone;
/// there is no server and no push.
abstract class NotificationService {
  /// One-time setup (time zone, notification channel, tap handling).
  Future<void> initialize();

  /// Whether the user has allowed notifications.
  Future<bool> notificationsAllowed();

  /// Shows the system permission prompt. Returns whether it was granted.
  Future<bool> requestPermission();

  /// Schedules [reminder], replacing any with the same id.
  Future<void> schedule(ScheduledReminder reminder);

  Future<void> cancel(int id);

  /// Everything currently scheduled.
  Future<List<PendingReminder>> pending();

  /// Taps on reminders while the app is running.
  Stream<NotificationTap> get taps;

  /// The tap that launched the app from a closed state, if any (once).
  Future<NotificationTap?> takeLaunchTap();
}

/// Used where notifications are unavailable (tests, unsupported platforms).
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> notificationsAllowed() async => false;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> schedule(ScheduledReminder reminder) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<List<PendingReminder>> pending() async => const [];

  @override
  Stream<NotificationTap> get taps => const Stream.empty();

  @override
  Future<NotificationTap?> takeLaunchTap() async => null;
}

/// Overridden in `main.dart` with the real implementation.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NoopNotificationService(),
);
