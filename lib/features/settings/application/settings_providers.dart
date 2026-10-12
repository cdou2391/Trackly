import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/error/error_reporter.dart';
import '../../subscriptions/domain/recurring_item.dart';
import 'settings_store.dart';

/// Saves a choice without ever failing the screen: the choice is already on
/// screen, so a storage problem is reported, not shown.
Future<void> _persist(Ref ref, Future<void> Function() save) async {
  try {
    await save();
  } catch (error, stackTrace) {
    await ref.read(errorReporterProvider).captureException(error, stackTrace);
  }
}

/// Currency used for new subscriptions and for empty totals.
class DefaultCurrencyController extends Notifier<String> {
  @override
  String build() =>
      ref.watch(settingsStoreProvider).currency ?? defaultCurrencyCode;

  Future<void> set(String code) async {
    if (code == state) return;
    state = code;
    await _persist(
      ref,
      () => ref.read(settingsStoreProvider).setCurrency(code),
    );
    unawaited(
      ref
          .read(analyticsProvider)
          .logEvent(
            AnalyticsEvents.currencyChanged,
            parameters: {'currency': code},
          ),
    );
  }
}

final defaultCurrencyProvider =
    NotifierProvider<DefaultCurrencyController, String>(
      DefaultCurrencyController.new,
    );

/// App theme: light, dark or follow the phone. Light until the user chooses.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      ref.watch(settingsStoreProvider).themeMode ?? defaultThemeMode;

  Future<void> set(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await _persist(
      ref,
      () => ref.read(settingsStoreProvider).setThemeMode(mode),
    );
    unawaited(
      ref
          .read(analyticsProvider)
          .logEvent(
            AnalyticsEvents.themeChanged,
            parameters: {'theme': mode.name},
          ),
    );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// When new subscriptions remind you: how many days before, and at what time.
class DefaultReminderController extends Notifier<ReminderDefaults> {
  @override
  ReminderDefaults build() {
    final store = ref.watch(settingsStoreProvider);
    return ReminderDefaults(
      days: store.reminderDays ?? defaultReminderDays,
      minuteOfDay: store.reminderMinuteOfDay ?? defaultReminderMinuteOfDay,
    );
  }

  Future<void> setDays(int days) async {
    if (days == state.days) return;
    state = state.copyWith(days: days);
    await _persist(
      ref,
      () => ref.read(settingsStoreProvider).setReminderDays(days),
    );
  }

  Future<void> setMinuteOfDay(int minute) async {
    if (minute == state.minuteOfDay) return;
    state = state.copyWith(minuteOfDay: minute);
    await _persist(
      ref,
      () => ref.read(settingsStoreProvider).setReminderMinuteOfDay(minute),
    );
  }
}

final defaultReminderProvider =
    NotifierProvider<DefaultReminderController, ReminderDefaults>(
      DefaultReminderController.new,
    );
