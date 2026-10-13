import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Anonymous product analytics. Parameters must be non-sensitive metadata
/// (frequency, currency code, flags), never user-entered text.
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  /// Turns collection on or off as the person chooses. Turning it off also
  /// forgets what the service stored about this installation.
  Future<void> setCollectionEnabled(bool enabled);
}

/// Used when analytics is disabled, unavailable or in debug builds.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Overridden in `main.dart` once Firebase has initialized successfully.
final analyticsProvider = Provider<AnalyticsService>(
  (ref) => const NoopAnalyticsService(),
);
