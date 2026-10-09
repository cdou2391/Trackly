import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app.dart';
import 'core/analytics/analytics_events.dart';
import 'core/analytics/analytics_service.dart';
import 'core/analytics/firebase_analytics_service.dart';
import 'core/config/app_config.dart';
import 'core/error/error_reporter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (AppConfig.sentryEnabled) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.sentryEnvironment;
        // Privacy: Trackly keeps user data on-device.
        options.sendDefaultPii = false;
      },
      appRunner: _runApp,
    );
  } else {
    await _runApp();
  }
}

Future<void> _runApp() async {
  final errorReporter = AppConfig.sentryEnabled
      ? const SentryErrorReporter()
      : const NoopErrorReporter();
  final analytics = await _initAnalytics(errorReporter);

  unawaited(analytics.logEvent(AnalyticsEvents.appOpened));

  runApp(
    ProviderScope(
      overrides: [
        errorReporterProvider.overrideWithValue(errorReporter),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: const TracklyApp(),
    ),
  );
}

/// Firebase is only used when explicitly enabled and never in debug builds,
/// to avoid polluting production data. Any init failure (for example missing
/// Firebase config files) falls back to a no-op so the app still starts.
Future<AnalyticsService> _initAnalytics(ErrorReporter errorReporter) async {
  if (!AppConfig.firebaseAnalyticsEnabled || kDebugMode) {
    return const NoopAnalyticsService();
  }
  try {
    await Firebase.initializeApp();
    return FirebaseAnalyticsService(FirebaseAnalytics.instance);
  } catch (error, stackTrace) {
    await errorReporter.captureException(error, stackTrace);
    return const NoopAnalyticsService();
  }
}
