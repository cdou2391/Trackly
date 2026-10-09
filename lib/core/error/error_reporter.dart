import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Technical error reporting. Expected business conditions (for example a
/// denied notification permission) are analytics events, not errors.
abstract class ErrorReporter {
  Future<void> captureException(Object error, StackTrace? stackTrace);

  /// Breadcrumbs must not contain raw notes or arbitrary service names.
  void addBreadcrumb(String message, {String? category});
}

class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async {}

  @override
  void addBreadcrumb(String message, {String? category}) {}
}

class SentryErrorReporter implements ErrorReporter {
  const SentryErrorReporter();

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async {
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  @override
  void addBreadcrumb(String message, {String? category}) {
    Sentry.addBreadcrumb(Breadcrumb(message: message, category: category));
  }
}

/// Overridden in `main.dart` when Sentry is configured.
final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => const NoopErrorReporter(),
);
