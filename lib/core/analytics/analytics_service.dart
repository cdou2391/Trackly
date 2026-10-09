import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Anonymous product analytics. Parameters must be non-sensitive metadata
/// (frequency, currency code, flags), never user-entered text.
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
}

/// Used when analytics is disabled, unavailable or in debug builds.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}
}

/// Overridden in `main.dart` once Firebase has initialized successfully.
final analyticsProvider = Provider<AnalyticsService>(
  (ref) => const NoopAnalyticsService(),
);
