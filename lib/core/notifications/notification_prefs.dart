import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How often we have asked for notification permission.
///
/// The system dialog only appears a couple of times before Android stops
/// showing it, so we ask at most [maxPrompts] times and never at first launch.
abstract class NotificationPrefs {
  static const maxPrompts = 2;

  int get promptCount;

  Future<void> recordPrompt();

  bool get canPrompt => promptCount < maxPrompts;
}

class InMemoryNotificationPrefs extends NotificationPrefs {
  int _count = 0;

  @override
  int get promptCount => _count;

  @override
  Future<void> recordPrompt() async => _count++;
}

class SharedNotificationPrefs extends NotificationPrefs {
  SharedNotificationPrefs(this._prefs);

  static const _key = 'notification_prompt_count';

  final SharedPreferences _prefs;

  @override
  int get promptCount => _prefs.getInt(_key) ?? 0;

  @override
  Future<void> recordPrompt() async {
    await _prefs.setInt(_key, promptCount + 1);
  }
}

/// Overridden in `main.dart` with the persistent implementation.
final notificationPrefsProvider = Provider<NotificationPrefs>(
  (ref) => InMemoryNotificationPrefs(),
);
