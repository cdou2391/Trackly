import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/subscriptions/domain/recurring_item.dart';
import '../../l10n/l10n.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import 'notification_prefs.dart';
import 'notification_service.dart';
import 'reminder_sync.dart';

/// Offers to turn on reminders right after the user saved an item that wants
/// them: in context, with the reason in front of them, never at first launch.
///
/// Does nothing when reminders are off for the item, notifications are
/// already allowed, or the user has already been asked [NotificationPrefs
/// .maxPrompts] times. The [container] is passed (not a `WidgetRef`) because
/// the calling widget is usually gone by the time the user answers. [navigator] should be the root navigator, which
/// outlives the add panel.
Future<void> offerReminders(
  NavigatorState navigator,
  ProviderContainer container,
  RecurringItem item,
) async {
  if (!item.remindersEnabled) return;

  final service = container.read(notificationServiceProvider);
  final prefs = container.read(notificationPrefsProvider);
  final analytics = container.read(analyticsProvider);

  if (await service.notificationsAllowed()) return;
  if (!prefs.canPrompt) return;

  await prefs.recordPrompt();
  if (!navigator.mounted) return;
  unawaited(analytics.logEvent(AnalyticsEvents.notificationPermissionPrompted));

  final accepted = await showDialog<bool>(
    context: navigator.context,
    builder: (context) => const ReminderPermissionDialog(),
  );
  if (accepted != true) return;

  final granted = await service.requestPermission();
  unawaited(
    analytics.logEvent(
      granted
          ? AnalyticsEvents.notificationPermissionGranted
          : AnalyticsEvents.notificationPermissionDenied,
    ),
  );
  if (granted) await container.read(reminderSyncProvider).reconcile();
}

class ReminderPermissionDialog extends StatelessWidget {
  const ReminderPermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.remindersPromptTitle),
      content: Text(l10n.remindersPromptBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.remindersPromptLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.remindersPromptConfirm),
        ),
      ],
    );
  }
}
