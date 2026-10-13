import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackly/features/settings/application/settings_store.dart';

void main() {
  Future<SharedSettingsStore> shared([Map<String, Object>? values]) async {
    SharedPreferences.setMockInitialValues(values ?? {});
    return SharedSettingsStore(await SharedPreferences.getInstance());
  }

  test('nothing chosen reads as null, so defaults apply', () async {
    final store = await shared();
    expect(store.currency, isNull);
    expect(store.themeMode, isNull);
    expect(store.reminderDays, isNull);
    expect(store.reminderMinuteOfDay, isNull);
  });

  test('round-trips every setting', () async {
    final store = await shared();
    await store.setCurrency('EUR');
    await store.setThemeMode(ThemeMode.dark);
    await store.setReminderDays(7);
    await store.setReminderMinuteOfDay(18 * 60 + 30);

    expect(store.currency, 'EUR');
    expect(store.themeMode, ThemeMode.dark);
    expect(store.reminderDays, 7);
    expect(store.reminderMinuteOfDay, 1110);
  });

  test('values survive a restart', () async {
    final first = await shared();
    await first.setThemeMode(ThemeMode.system);
    final prefs = await SharedPreferences.getInstance();
    expect(SharedSettingsStore(prefs).themeMode, ThemeMode.system);
  });

  test('unusable stored values fall back to null', () async {
    final store = await shared({
      'default_currency': '',
      'theme_mode': 'sepia',
      'default_reminder_days': -2,
      'default_reminder_minute': 24 * 60,
    });
    expect(store.currency, isNull);
    expect(store.themeMode, isNull);
    expect(store.reminderDays, isNull);
    expect(store.reminderMinuteOfDay, isNull);
  });

  test('clear forgets every choice', () async {
    final store = await shared();
    await store.setCurrency('GBP');
    await store.setThemeMode(ThemeMode.dark);
    await store.setReminderDays(1);
    await store.setReminderMinuteOfDay(60);
    await store.clear();

    expect(store.currency, isNull);
    expect(store.themeMode, isNull);
    expect(store.reminderDays, isNull);
    expect(store.reminderMinuteOfDay, isNull);
  });

  test('the in-memory store behaves the same', () async {
    final store = InMemorySettingsStore();
    await store.setCurrency('JPY');
    expect(store.currency, 'JPY');
    await store.clear();
    expect(store.currency, isNull);
  });

  test(
    'counted trial ends survive a restart and are kept by clear()',
    () async {
      final store = await shared();
      expect(store.reportedTrialEnds, isEmpty);

      await store.setReportedTrialEnds({'b', 'a'});
      await store.clear();

      final prefs = await SharedPreferences.getInstance();
      expect(SharedSettingsStore(prefs).reportedTrialEnds, {'a', 'b'});
    },
  );
}
