import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../subscriptions/domain/recurring_item.dart';

/// Used until the user chooses otherwise.
const defaultCurrencyCode = 'USD';
const defaultThemeMode = ThemeMode.light;
const defaultReminderDays = 3;

/// Reminder offsets offered everywhere: same day, 1, 3 or 7 days before.
const reminderDayOptions = [0, 1, 3, 7];

/// Where the user's choices are kept between launches.
///
/// Values come back null when nothing has been chosen (or the stored value is
/// not usable), so the caller falls back to the default.
abstract class SettingsStore {
  String? get currency;
  ThemeMode? get themeMode;
  int? get reminderDays;
  int? get reminderMinuteOfDay;

  Future<void> setCurrency(String code);
  Future<void> setThemeMode(ThemeMode mode);
  Future<void> setReminderDays(int days);
  Future<void> setReminderMinuteOfDay(int minute);

  /// Forgets every choice, so each setting is back to its default.
  Future<void> clear();
}

class InMemorySettingsStore implements SettingsStore {
  String? _currency;
  ThemeMode? _themeMode;
  int? _reminderDays;
  int? _reminderMinute;

  @override
  String? get currency => _currency;
  @override
  ThemeMode? get themeMode => _themeMode;
  @override
  int? get reminderDays => _reminderDays;
  @override
  int? get reminderMinuteOfDay => _reminderMinute;

  @override
  Future<void> setCurrency(String code) async => _currency = code;
  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;
  @override
  Future<void> setReminderDays(int days) async => _reminderDays = days;
  @override
  Future<void> setReminderMinuteOfDay(int minute) async =>
      _reminderMinute = minute;

  @override
  Future<void> clear() async {
    _currency = null;
    _themeMode = null;
    _reminderDays = null;
    _reminderMinute = null;
  }
}

class SharedSettingsStore implements SettingsStore {
  SharedSettingsStore(this._prefs);

  static const _currencyKey = 'default_currency';
  static const _themeKey = 'theme_mode';
  static const _reminderDaysKey = 'default_reminder_days';
  static const _reminderMinuteKey = 'default_reminder_minute';

  final SharedPreferences _prefs;

  @override
  String? get currency {
    final code = _prefs.getString(_currencyKey);
    return (code == null || code.isEmpty) ? null : code;
  }

  @override
  ThemeMode? get themeMode {
    final name = _prefs.getString(_themeKey);
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return null;
  }

  @override
  int? get reminderDays {
    final days = _prefs.getInt(_reminderDaysKey);
    return (days != null && days >= 0) ? days : null;
  }

  @override
  int? get reminderMinuteOfDay {
    final minute = _prefs.getInt(_reminderMinuteKey);
    return (minute != null && minute >= 0 && minute < 24 * 60) ? minute : null;
  }

  @override
  Future<void> setCurrency(String code) async {
    await _prefs.setString(_currencyKey, code);
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
  }

  @override
  Future<void> setReminderDays(int days) async {
    await _prefs.setInt(_reminderDaysKey, days);
  }

  @override
  Future<void> setReminderMinuteOfDay(int minute) async {
    await _prefs.setInt(_reminderMinuteKey, minute);
  }

  @override
  Future<void> clear() async {
    for (final key in [
      _currencyKey,
      _themeKey,
      _reminderDaysKey,
      _reminderMinuteKey,
    ]) {
      await _prefs.remove(key);
    }
  }
}

/// Overridden in `main.dart` with the persistent implementation.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => InMemorySettingsStore(),
);

/// The reminder timing a new subscription starts with.
class ReminderDefaults {
  const ReminderDefaults({required this.days, required this.minuteOfDay});

  final int days;
  final int minuteOfDay;

  ReminderDefaults copyWith({int? days, int? minuteOfDay}) => ReminderDefaults(
    days: days ?? this.days,
    minuteOfDay: minuteOfDay ?? this.minuteOfDay,
  );
}

const fallbackReminderDefaults = ReminderDefaults(
  days: defaultReminderDays,
  minuteOfDay: defaultReminderMinuteOfDay,
);
