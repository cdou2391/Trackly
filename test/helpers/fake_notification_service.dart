import 'dart:async';

import 'package:trackly/core/notifications/notification_service.dart';

/// In-memory [NotificationService] for tests.
class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.allowed = true, this.grantsPermission = true});

  bool allowed;
  bool grantsPermission;
  int permissionRequests = 0;
  int scheduleCalls = 0;
  int cancelCalls = 0;
  int cancelAllCalls = 0;

  /// Ids whose `schedule` call should throw.
  final failingIds = <int>{};

  final scheduled = <int, ScheduledReminder>{};
  final _taps = StreamController<NotificationTap>.broadcast();
  NotificationTap? launchTap;

  void tap(NotificationTap tap) => _taps.add(tap);

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> notificationsAllowed() async => allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    if (grantsPermission) allowed = true;
    return grantsPermission;
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) async {
    scheduleCalls++;
    if (failingIds.contains(reminder.id)) throw StateError('schedule failed');
    scheduled[reminder.id] = reminder;
  }

  @override
  Future<void> cancel(int id) async {
    cancelCalls++;
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalls++;
    scheduled.clear();
  }

  @override
  Future<List<PendingReminder>> pending() async => [
    for (final r in scheduled.values)
      PendingReminder(id: r.id, payload: r.payload),
  ];

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  Future<NotificationTap?> takeLaunchTap() async {
    final tap = launchTap;
    launchTap = null;
    return tap;
  }
}
