import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Technical error reporting. Expected business conditions (for example a
/// denied notification permission) are analytics events, not errors.
abstract class ErrorReporter {
  Future<void> captureException(Object error, StackTrace? stackTrace);

  /// Breadcrumbs must not contain raw notes or arbitrary service names.
  void addBreadcrumb(String message, {String? category});

  /// Starts or stops sending reports as the person chooses. While stopped,
  /// nothing is captured and nothing leaves the phone.
  Future<void> setEnabled(bool enabled);
}

class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async {}

  @override
  void addBreadcrumb(String message, {String? category}) {}

  @override
  Future<void> setEnabled(bool enabled) async {}
}

/// Sends reports to Sentry, but only while the person allows it.
///
/// Sentry is not started at all until they agree, so nothing (not even the
/// native crash handler) runs before the choice. [start] and [stop] are
/// injected so the on/off logic can be tested without the SDK.
class SentryErrorReporter implements ErrorReporter {
  SentryErrorReporter({
    required this._start,
    this._stop = Sentry.close,
    this._running = false,
  });

  final Future<void> Function() _start;
  final Future<void> Function() _stop;
  bool _running;

  bool get isRunning => _running;

  @override
  Future<void> setEnabled(bool enabled) async {
    if (enabled == _running) return;
    // Record the new state first, so a second call during the await sees it.
    _running = enabled;
    try {
      if (enabled) {
        await _start();
      } else {
        await _stop();
      }
    } catch (_) {
      _running = !enabled;
      rethrow;
    }
  }

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async {
    if (!_running) return;
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  @override
  void addBreadcrumb(String message, {String? category}) {
    if (!_running) return;
    Sentry.addBreadcrumb(Breadcrumb(message: message, category: category));
  }
}

/// Overridden in `main.dart` when Sentry is configured.
final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => const NoopErrorReporter(),
);
