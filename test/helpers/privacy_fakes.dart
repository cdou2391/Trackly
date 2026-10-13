import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/core/error/error_reporter.dart';

/// Records events and every on/off switch it was given.
class FakeAnalytics implements AnalyticsService {
  final events = <String>[];

  /// Each value passed to [setCollectionEnabled], in order.
  final switches = <bool>[];

  /// Set to make switching fail, as if the platform call threw.
  Object? failSwitchWith;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add(name);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    final error = failSwitchWith;
    if (error != null) throw error;
    switches.add(enabled);
  }
}

/// Records captured errors and every on/off switch it was given.
class FakeErrorReporter implements ErrorReporter {
  final captured = <Object>[];
  final switches = <bool>[];

  @override
  Future<void> captureException(Object error, StackTrace? stackTrace) async {
    captured.add(error);
  }

  @override
  void addBreadcrumb(String message, {String? category}) {}

  @override
  Future<void> setEnabled(bool enabled) async {
    switches.add(enabled);
  }
}
