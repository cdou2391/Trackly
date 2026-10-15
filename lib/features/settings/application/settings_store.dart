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

  /// How All subscriptions is drawn: true for drifting bubbles, false for a
  /// list. Null until the person chooses (bubbles).
  bool? get itemsAsBubbles;

  /// Whether the person agreed to send anonymous usage statistics. Null until
  /// they have been asked: nothing is sent until then.
  bool? get usageStatsEnabled;

  /// Whether the person agreed to send error reports. Null until asked.
  bool? get errorReportsEnabled;

  /// Ids of the trials whose end has already been counted in analytics, so
  /// each is counted once.
  Set<String> get reportedTrialEnds;

  Future<void> setReportedTrialEnds(Set<String> ids);

  Future<void> setCurrency(String code);
  Future<void> setThemeMode(ThemeMode mode);
  Future<void> setReminderDays(int days);
  Future<void> setReminderMinuteOfDay(int minute);
  Future<void> setItemsAsBubbles(bool bubbles);
  Future<void> setUsageStatsEnabled(bool enabled);
  Future<void> setErrorReportsEnabled(bool enabled);

  /// Forgets the display and reminder choices, so each is back to its default.
  ///
  /// The two privacy choices are kept: someone who said no to sending data
  /// must not be treated as undecided (and asked again) after clearing their
  /// subscriptions.
  Future<void> clear();
}

class InMemorySettingsStore implements SettingsStore {
  String? _currency;
  ThemeMode? _themeMode;
  int? _reminderDays;
  int? _reminderMinute;
  bool? _itemsAsBubbles;
  bool? _usageStats;
  bool? _errorReports;
  Set<String> _reportedTrialEnds = const {};

  @override
  Set<String> get reportedTrialEnds => _reportedTrialEnds;
  @override
  Future<void> setReportedTrialEnds(Set<String> ids) async =>
      _reportedTrialEnds = {...ids};

  @override
  String? get currency => _currency;
  @override
  ThemeMode? get themeMode => _themeMode;
  @override
  int? get reminderDays => _reminderDays;
  @override
  int? get reminderMinuteOfDay => _reminderMinute;
  @override
  bool? get itemsAsBubbles => _itemsAsBubbles;
  @override
  bool? get usageStatsEnabled => _usageStats;
  @override
  bool? get errorReportsEnabled => _errorReports;

  @override
  Future<void> setItemsAsBubbles(bool bubbles) async =>
      _itemsAsBubbles = bubbles;
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
  Future<void> setUsageStatsEnabled(bool enabled) async =>
      _usageStats = enabled;
  @override
  Future<void> setErrorReportsEnabled(bool enabled) async =>
      _errorReports = enabled;

  @override
  Future<void> clear() async {
    _currency = null;
    _themeMode = null;
    _reminderDays = null;
    _reminderMinute = null;
    _itemsAsBubbles = null;
  }
}

class SharedSettingsStore implements SettingsStore {
  SharedSettingsStore(this._prefs);

  static const _currencyKey = 'default_currency';
  static const _themeKey = 'theme_mode';
  static const _reminderDaysKey = 'default_reminder_days';
  static const _reminderMinuteKey = 'default_reminder_minute';
  static const _itemsAsBubblesKey = 'items_as_bubbles';
  static const _usageStatsKey = 'privacy_usage_stats';
  static const _errorReportsKey = 'privacy_error_reports';
  static const _reportedTrialEndsKey = 'reported_trial_ends';

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
  bool? get itemsAsBubbles => _prefs.getBool(_itemsAsBubblesKey);

  @override
  bool? get usageStatsEnabled => _prefs.getBool(_usageStatsKey);

  @override
  bool? get errorReportsEnabled => _prefs.getBool(_errorReportsKey);

  @override
  Set<String> get reportedTrialEnds =>
      (_prefs.getStringList(_reportedTrialEndsKey) ?? const []).toSet();

  @override
  Future<void> setReportedTrialEnds(Set<String> ids) async {
    await _prefs.setStringList(_reportedTrialEndsKey, ids.toList()..sort());
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
  Future<void> setItemsAsBubbles(bool bubbles) async {
    await _prefs.setBool(_itemsAsBubblesKey, bubbles);
  }

  @override
  Future<void> setUsageStatsEnabled(bool enabled) async {
    await _prefs.setBool(_usageStatsKey, enabled);
  }

  @override
  Future<void> setErrorReportsEnabled(bool enabled) async {
    await _prefs.setBool(_errorReportsKey, enabled);
  }

  @override
  Future<void> clear() async {
    // The privacy choices are deliberately not cleared (see SettingsStore).
    for (final key in [
      _currencyKey,
      _themeKey,
      _reminderDaysKey,
      _reminderMinuteKey,
      _itemsAsBubblesKey,
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
