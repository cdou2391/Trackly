import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

/// Firebase Analytics, collecting only while the person has allowed it.
///
/// The Android manifest keeps Firebase from collecting anything at launch
/// (`firebase_analytics_collection_enabled`), so nothing is sent before the
/// choice is made; [setCollectionEnabled] then switches it on or off.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics, {this._enabled = false});

  final FirebaseAnalytics _analytics;
  bool _enabled;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    // Belt and braces: no event is even handed to Firebase while it is off.
    if (!_enabled) return;
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    final wasEnabled = _enabled;
    _enabled = enabled;
    await _analytics.setAnalyticsCollectionEnabled(enabled);
    // Going from on to off also forgets this installation's identifier.
    if (wasEnabled && !enabled) await _analytics.resetAnalyticsData();
  }
}
