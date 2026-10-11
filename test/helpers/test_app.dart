import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/app.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/core/notifications/notification_prefs.dart';
import 'package:trackly/core/notifications/notification_service.dart';
import 'package:trackly/features/home/application/home_providers.dart';
import 'package:trackly/features/settings/application/settings_providers.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

AppDatabase? _openDatabase;

var _fontsLoaded = false;

/// Loads the bundled fonts. Without this the test renderer draws every glyph
/// as a fixed-width box roughly twice as wide as Inter, which hides real
/// layout (and overflow) behavior.
Future<void> _loadFonts(WidgetTester tester) async {
  if (_fontsLoaded) return;
  await tester.runAsync(() async {
    const fonts = {
      'Inter': 'assets/fonts/Inter.ttf',
      'PlayfairDisplay': 'assets/fonts/PlayfairDisplay.ttf',
    };
    for (final font in fonts.entries) {
      final loader = FontLoader(font.key)..addFont(rootBundle.load(font.value));
      await loader.load();
    }
  });
  _fontsLoaded = true;
}

/// Like `testWidgets`, but tears the app and database down inside the test.
///
/// Flutter checks for pending timers before `addTearDown` callbacks run, and
/// Drift schedules fake-async timers when streams are cancelled and when the
/// database closes, so cleanup must happen in the test body.
void tracklyTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    await body(tester);

    final db = _openDatabase;
    _openDatabase = null;
    // Let any snack bar finish its auto-dismiss timer.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(seconds: 1));
    if (db != null) {
      await tester.runAsync(db.close);
      await tester.pump(const Duration(seconds: 1));
    }
  });
}

/// Fixed "today" for widget tests.
final testNow = DateTime(2026, 10, 9, 12);

RecurringItem testItem(
  String name, {
  double amount = 10,
  String currency = 'USD',
  DateTime? due,
  BillingFrequency frequency = BillingFrequency.monthly,
  DateTime? trialEnd,
  String? logoKey,
  ItemStatus status = ItemStatus.active,
}) {
  return RecurringItem(
    id: name,
    name: name,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    // The billing anchor is the due day (a monthly item due on the 15th has
    // been billed on the 15th), so paying moves it to the 15th again.
    startDate: DateTime(2026, 1, (due ?? DateTime(2026, 10, 20)).day),
    nextDueDate: due ?? DateTime(2026, 10, 20),
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    logoKey: logoKey,
    createdAt: testNow,
    updatedAt: testNow,
  );
}

/// A fixed theme for tests.
class _FixedThemeMode extends ThemeModeController {
  _FixedThemeMode(this._mode);

  final ThemeMode _mode;

  @override
  ThemeMode build() => _mode;
}

/// Pumps the whole app on a phone-sized screen (390x844 by default) with an
/// in-memory database. The light theme is the default design.
Future<AppDatabase> pumpTrackly(
  WidgetTester tester, {
  List<RecurringItem> items = const [],
  Size size = const Size(390, 844),
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1.0,
  NotificationService notifications = const NoopNotificationService(),
  NotificationPrefs? notificationPrefs,
}) async {
  await _loadFonts(tester);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final db = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() async {
    for (final item in items) {
      await db.recurringItemsDao.insertItem(item);
    }
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nowProvider.overrideWithValue(() => testNow),
        notificationServiceProvider.overrideWithValue(notifications),
        if (notificationPrefs != null)
          notificationPrefsProvider.overrideWithValue(notificationPrefs),
        themeModeProvider.overrideWith(() => _FixedThemeMode(themeMode)),
      ],
      child: const TracklyApp(),
    ),
  );
  await settle(tester);

  _openDatabase = db;
  return db;
}

/// Lets Drift writes and streams complete and animations finish.
///
/// Database work happens in real time, outside the test's fake clock, so each
/// step waits a few real milliseconds before pumping the fake clock.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 4)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}
