import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import '../database/app_database.dart';
import '../navigation/app_router.dart';
import 'notification_service.dart';

/// Opens the item behind a tapped reminder, both when the app was running and
/// when the tap launched it. A reminder for an item that no longer exists
/// (deleted since) opens the app normally.
final reminderTapsProvider = Provider<void>((ref) {
  Future<void> open(NotificationTap tap) async {
    final item = await ref
        .read(appDatabaseProvider)
        .recurringItemsDao
        .getById(tap.itemId);
    if (item == null) return;

    unawaited(
      ref
          .read(analyticsProvider)
          .logEvent(
            AnalyticsEvents.reminderOpened,
            parameters: {'notification_type': tap.type.wireName},
          ),
    );

    // Wait for a frame so the router is attached (a launch tap can arrive
    // before the first one). A callback alone does not request a frame.
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        ref.read(appRouterProvider).push(AppRoutes.itemPath(tap.itemId));
      })
      ..ensureVisualUpdate();
  }

  final service = ref.read(notificationServiceProvider);
  final subscription = service.taps.listen(open);
  ref.onDispose(subscription.cancel);

  unawaited(
    service.takeLaunchTap().then((tap) {
      if (tap != null) return open(tap);
    }),
  );
});
