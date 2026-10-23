import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/analytics/analytics_events.dart';
import 'core/analytics/analytics_service.dart';
import 'core/analytics/firebase_analytics_service.dart';
import 'core/config/app_config.dart';
import 'core/error/error_reporter.dart';
import 'core/error/error_scrubber.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/notifications/notification_prefs.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/reminder_text.dart';
import 'core/widget/home_widget_gateway.dart';
import 'core/startup/boot_gate.dart';
import 'features/export/application/data_export.dart';
import 'features/export/application/share_plus_data_sharer.dart';
import 'features/settings/application/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Nothing is reported until the person agrees, on the first-run screen or in
  // Settings, so Sentry is not even started without that choice.
  final reportErrors =
      AppConfig.sentryEnabled &&
      SharedSettingsStore(prefs).errorReportsEnabled == true;

  if (reportErrors) {
    await SentryFlutter.init(
      _configureSentry,
      appRunner: () => _runApp(prefs, errorReportsRunning: true),
    );
  } else {
    await _runApp(prefs, errorReportsRunning: false);
  }
}

void _configureSentry(SentryFlutterOptions options) {
  options.dsn = AppConfig.sentryDsn;
  options.environment = AppConfig.sentryEnvironment;
  // Privacy: Trackly keeps user data on-device.
  options.sendDefaultPii = false;
  // Database errors can quote what the user typed; strip it before sending.
  options.beforeSend = scrubSentryEvent;
}

Future<void> _runApp(
  SharedPreferences prefs, {
  required bool errorReportsRunning,
}) async {
  final errorReporter = AppConfig.sentryEnabled
      ? SentryErrorReporter(
          // Used when the person agrees to error reports during this session.
          start: () => SentryFlutter.init(_configureSentry),
          running: errorReportsRunning,
        )
      : const NoopErrorReporter();

  // The splash is on screen at once, while the start-up work below runs.
  runApp(
    BootGate(
      bootstrap: () => _bootstrap(errorReporter, prefs),
      onError: (error, stackTrace) =>
          unawaited(errorReporter.captureException(error, stackTrace)),
    ),
  );
}

/// Starts the services and returns the app to show once they are ready.
Future<Widget> _bootstrap(
  ErrorReporter errorReporter,
  SharedPreferences prefs,
) async {
  final settings = SharedSettingsStore(prefs);
  final analytics = await _initAnalytics(
    errorReporter,
    allowed: settings.usageStatsEnabled == true,
  );

  final notifications = await _initNotifications(errorReporter);

  // Only counted if the person has agreed; until then this does nothing.
  unawaited(analytics.logEvent(AnalyticsEvents.appOpened));

  return ProviderScope(
    overrides: [
      errorReporterProvider.overrideWithValue(errorReporter),
      analyticsProvider.overrideWithValue(analytics),
      notificationServiceProvider.overrideWithValue(notifications),
      homeWidgetGatewayProvider.overrideWithValue(
        const AndroidHomeWidgetGateway(),
      ),
      notificationPrefsProvider.overrideWithValue(
        SharedNotificationPrefs(prefs),
      ),
      settingsStoreProvider.overrideWithValue(settings),
      dataSharerProvider.overrideWithValue(const SharePlusDataSharer()),
    ],
    child: const TracklyApp(),
  );
}

/// Firebase is only used when explicitly enabled and never in debug builds,
/// to avoid polluting production data. Any init failure (for example missing
/// Firebase config files) falls back to a no-op so the app still starts.
///
/// The manifest keeps Firebase from collecting anything until [allowed] has
/// been switched on here, so a person who has not chosen yet (or said no) is
/// not counted.
Future<AnalyticsService> _initAnalytics(
  ErrorReporter errorReporter, {
  required bool allowed,
}) async {
  if (!AppConfig.firebaseAnalyticsEnabled || kDebugMode) {
    return const NoopAnalyticsService();
  }
  try {
    await Firebase.initializeApp();
    final service = FirebaseAnalyticsService(
      FirebaseAnalytics.instance,
      enabled: allowed,
    );
    await service.setCollectionEnabled(allowed);
    return service;
  } catch (error, stackTrace) {
    await errorReporter.captureException(error, stackTrace);
    return const NoopAnalyticsService();
  }
}

/// Local reminders. A failure to set them up must not stop the app, so it
/// falls back to a no-op (reminders are simply unavailable) and is reported.
Future<NotificationService> _initNotifications(
  ErrorReporter errorReporter,
) async {
  try {
    final l10n = notificationLocalizations(PlatformDispatcher.instance.locale);
    final service = LocalNotificationService(
      errorReporter: errorReporter,
      channelName: l10n.notifChannelName,
      channelDescription: l10n.notifChannelDescription,
    );
    await service.initialize();
    return service;
  } catch (error, stackTrace) {
    await errorReporter.captureException(error, stackTrace);
    return const NoopNotificationService();
  }
}
