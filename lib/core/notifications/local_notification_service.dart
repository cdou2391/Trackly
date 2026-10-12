import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../error/error_reporter.dart';
import 'notification_service.dart';

/// Android implementation on top of `flutter_local_notifications`.
///
/// Reminders use inexact delivery so no exact-alarm permission is needed; they
/// may arrive a few minutes after 9:00, which is fine for a renewal reminder.
class LocalNotificationService implements NotificationService {
  LocalNotificationService({
    required this.errorReporter,
    required this.channelName,
    required this.channelDescription,
  });

  static const _channelId = 'reminders';
  static const _icon = '@drawable/ic_stat_notify';

  final ErrorReporter errorReporter;
  final String channelName;
  final String channelDescription;

  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<NotificationTap>.broadcast();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (error, stackTrace) {
      // Falls back to UTC: reminders would fire at the wrong hour, so report.
      tz.setLocalLocation(tz.UTC);
      await errorReporter.captureException(error, stackTrace);
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: (response) {
        final tap = NotificationTap.fromPayload(response.payload);
        if (tap != null) _taps.add(tap);
      },
    );
  }

  @override
  Future<bool> notificationsAllowed() async {
    return await _android?.areNotificationsEnabled() ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    return await _android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> schedule(ScheduledReminder reminder) {
    final when = reminder.when;
    return _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: tz.TZDateTime(
        tz.local,
        when.year,
        when.month,
        when.day,
        when.hour,
        when.minute,
      ),
      payload: reminder.payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: _icon,
        ),
      ),
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<List<PendingReminder>> pending() async {
    final requests = await _plugin.pendingNotificationRequests();
    return [
      for (final r in requests) PendingReminder(id: r.id, payload: r.payload),
    ];
  }

  @override
  Stream<NotificationTap> get taps => _taps.stream;

  @override
  Future<NotificationTap?> takeLaunchTap() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return NotificationTap.fromPayload(details.notificationResponse?.payload);
  }
}
