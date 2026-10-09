/// Build-time configuration, supplied with
/// `flutter run --dart-define-from-file=config/local.json`.
///
/// Every value defaults to "off" so the app (and tests) run without
/// credentials.
class AppConfig {
  const AppConfig._();

  static const appName = 'Trackly';

  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const sentryEnvironment = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
    defaultValue: 'development',
  );

  static const firebaseAnalyticsEnabled = bool.fromEnvironment(
    'FIREBASE_ANALYTICS_ENABLED',
  );

  static bool get sentryEnabled => sentryDsn.isNotEmpty;
}
