import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/settings/application/settings_store.dart';
import 'package:trackly/shared/widgets/picker_field.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/test_app.dart';

const _tall = Size(390, 1800);

class _RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

Future<void> _openFromMore(WidgetTester tester) async {
  await tester.tap(find.text('More').last);
  await settle(tester);
  await tester.tap(find.text('Settings'));
  await settle(tester);
}

Payment _payment(String id, String itemId) => Payment(
  id: id,
  recurringItemId: itemId,
  amount: 10,
  currencyCode: 'USD',
  dueDate: DateTime(2026, 9, 20),
  paidDate: DateTime(2026, 9, 20),
  status: PaymentStatus.paid,
  createdAt: testNow,
);

void main() {
  group('opening', () {
    tracklyTest('the Home gear opens Settings', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester);

      expect(find.text('For new subscriptions'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.text('For new subscriptions'), findsNothing);
    });

    tracklyTest('More has a Settings entry', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await _openFromMore(tester);
      expect(find.text('Appearance'), findsOneWidget);
    });
  });

  group('currency', () {
    tracklyTest('is saved and logged', (tester) async {
      final store = InMemorySettingsStore();
      final analytics = _RecordingAnalytics();
      await pumpTrackly(
        tester,
        size: _tall,
        settings: store,
        analytics: analytics,
      );
      await _openFromMore(tester);

      await tester.tap(find.byKey(const ValueKey('currency-USD')));
      await settle(tester);
      await tester.tap(find.text('EUR').last);
      await settle(tester);

      expect(store.currency, 'EUR');
      expect(
        analytics.events
            .singleWhere((e) => e.$1 == AnalyticsEvents.currencyChanged)
            .$2,
        equals({'currency': 'EUR'}),
      );
    });

    tracklyTest('a saved currency is used on launch', (tester) async {
      final store = InMemorySettingsStore();
      await store.setCurrency('GBP');
      await pumpTrackly(tester, size: _tall, settings: store);
      await _openFromMore(tester);

      expect(find.byKey(const ValueKey('currency-GBP')), findsOneWidget);
    });
  });

  group('appearance', () {
    tracklyTest('Dark switches the theme and is saved', (tester) async {
      final store = InMemorySettingsStore();
      final analytics = _RecordingAnalytics();
      await pumpTrackly(
        tester,
        size: _tall,
        settings: store,
        analytics: analytics,
      );
      await _openFromMore(tester);
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.light,
      );

      await tester.tap(find.text('Dark'));
      await settle(tester);

      expect(store.themeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.dark,
      );
      expect(
        analytics.events
            .singleWhere((e) => e.$1 == AnalyticsEvents.themeChanged)
            .$2,
        equals({'theme': 'dark'}),
      );
    });

    tracklyTest('light is the default', (tester) async {
      await pumpTrackly(tester, size: _tall, settings: InMemorySettingsStore());
      await _openFromMore(tester);
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.light,
      );
    });
  });

  group('reminder defaults', () {
    tracklyTest('days and time are saved', (tester) async {
      final store = InMemorySettingsStore();
      await pumpTrackly(tester, size: _tall, settings: store);
      await _openFromMore(tester);

      await tester.tap(find.text('7 days before'));
      await settle(tester);
      expect(store.reminderDays, 7);

      await tester.tap(find.byType(PickerField));
      await settle(tester);
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await settle(tester);
      final fields = find.byType(EditableText);
      await tester.enterText(fields.at(0), '6');
      await tester.enterText(fields.at(1), '45');
      await tester.tap(find.text('OK'));
      await settle(tester);

      expect(store.reminderMinuteOfDay, 6 * 60 + 45);
      expect(find.text('6:45 AM'), findsOneWidget);
    });

    tracklyTest('Quick Add uses the chosen timing', (tester) async {
      final store = InMemorySettingsStore();
      await store.setReminderDays(7);
      await store.setReminderMinuteOfDay(18 * 60);
      final db = await pumpTrackly(
        tester,
        size: _tall,
        settings: store,
        notifications: FakeNotificationService(),
      );

      Finder input(String key) => find.descendant(
        of: find.byKey(Key(key)),
        matching: find.byType(EditableText),
      );
      await tester.enterText(input('quick-add-name'), 'Gym');
      await tester.enterText(input('quick-add-amount'), '25');
      await tester.pump();
      await tester.tap(find.byKey(const Key('quick-add-save')));
      await settle(tester);

      final items = (await tester.runAsync(
        () => db.recurringItemsDao.watchAll().first,
      ))!;
      expect(items.single.reminderDaysBefore, 7);
      expect(items.single.reminderMinuteOfDay, 18 * 60);
    });
  });

  group('notifications', () {
    tracklyTest('shows that reminders are on', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        notifications: FakeNotificationService(),
      );
      await _openFromMore(tester);

      expect(find.text('Reminders are on'), findsOneWidget);
      expect(find.text('Turn on'), findsNothing);
    });

    tracklyTest('Turn on asks the phone and flips the status', (tester) async {
      final service = FakeNotificationService(allowed: false);
      final analytics = _RecordingAnalytics();
      await pumpTrackly(
        tester,
        size: _tall,
        notifications: service,
        analytics: analytics,
      );
      await _openFromMore(tester);
      expect(find.textContaining('Notifications are off'), findsOneWidget);

      await tester.tap(find.text('Turn on'));
      await settle(tester);

      expect(service.permissionRequests, 1);
      expect(find.text('Reminders are on'), findsOneWidget);
      expect(
        [for (final e in analytics.events) e.$1],
        containsAll([
          AnalyticsEvents.notificationPermissionPrompted,
          AnalyticsEvents.notificationPermissionGranted,
        ]),
      );
    });

    tracklyTest('a refusal points to the phone settings', (tester) async {
      final service = FakeNotificationService(
        allowed: false,
        grantsPermission: false,
      );
      final analytics = _RecordingAnalytics();
      await pumpTrackly(
        tester,
        size: _tall,
        notifications: service,
        analytics: analytics,
      );
      await _openFromMore(tester);

      await tester.tap(find.text('Turn on'));
      await settle(tester);

      expect(find.textContaining('in your phone’s settings'), findsOneWidget);
      expect(find.text('Reminders are on'), findsNothing);
      expect([
        for (final e in analytics.events) e.$1,
      ], contains(AnalyticsEvents.notificationPermissionDenied));
    });
  });

  group('your data', () {
    tracklyTest('Clear history keeps the subscriptions', (tester) async {
      final db = await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix')],
      );
      await tester.runAsync(
        () => db.paymentsDao.insertPayment(_payment('p1', 'Netflix')),
      );
      await _openFromMore(tester);

      await tester.tap(find.text('Clear payment history'));
      await settle(tester);
      expect(find.text('Clear payment history?'), findsOneWidget);
      await tester.tap(find.text('Clear history'));
      await settle(tester);

      expect(find.text('Payment history cleared'), findsOneWidget);
      final payments = await tester.runAsync(
        () => db.paymentsDao.watchAll().first,
      );
      final items = await tester.runAsync(
        () => db.recurringItemsDao.watchAll().first,
      );
      expect(payments, isEmpty);
      expect(items, hasLength(1));
    });

    tracklyTest('keeping it changes nothing', (tester) async {
      final db = await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix')],
      );
      await tester.runAsync(
        () => db.paymentsDao.insertPayment(_payment('p1', 'Netflix')),
      );
      await _openFromMore(tester);

      await tester.tap(find.text('Clear payment history'));
      await settle(tester);
      await tester.tap(find.text('Keep it'));
      await settle(tester);

      final payments = await tester.runAsync(
        () => db.paymentsDao.watchAll().first,
      );
      expect(payments, hasLength(1));
      expect(find.text('Payment history cleared'), findsNothing);
    });

    tracklyTest('Delete all data wipes data, reminders and settings', (
      tester,
    ) async {
      final store = InMemorySettingsStore();
      await store.setCurrency('EUR');
      await store.setThemeMode(ThemeMode.dark);
      final service = FakeNotificationService();
      final db = await pumpTrackly(
        tester,
        size: _tall,
        settings: store,
        notifications: service,
        items: [testItem('Netflix'), testItem('Spotify')],
      );
      await tester.runAsync(
        () => db.paymentsDao.insertPayment(_payment('p1', 'Netflix')),
      );
      await _openFromMore(tester);

      await tester.tap(find.text('Delete all data'));
      await settle(tester);
      expect(find.text('Delete all data?'), findsOneWidget);
      await tester.tap(find.text('Delete everything'));
      await settle(tester);

      expect(find.text('All data deleted'), findsOneWidget);
      final items = await tester.runAsync(
        () => db.recurringItemsDao.watchAll().first,
      );
      final payments = await tester.runAsync(
        () => db.paymentsDao.watchAll().first,
      );
      expect(items, isEmpty);
      expect(payments, isEmpty);
      expect(service.cancelAllCalls, 1);
      expect(store.currency, isNull);
      expect(store.themeMode, isNull);
      // Back to the defaults on screen.
      expect(find.byKey(const ValueKey('currency-USD')), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Appearance'))).brightness,
        Brightness.light,
      );
    });

    tracklyTest('cancelling Delete all data keeps everything', (tester) async {
      final service = FakeNotificationService();
      final db = await pumpTrackly(
        tester,
        size: _tall,
        notifications: service,
        items: [testItem('Netflix')],
      );
      await _openFromMore(tester);

      await tester.tap(find.text('Delete all data'));
      await settle(tester);
      await tester.tap(find.text('Keep it'));
      await settle(tester);

      final items = await tester.runAsync(
        () => db.recurringItemsDao.watchAll().first,
      );
      expect(items, hasLength(1));
      expect(service.cancelAllCalls, 0);
    });
  });

  group('layout', () {
    for (final (size, scale) in [
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 1.6),
      (const Size(390, 844), 1.6),
    ]) {
      tracklyTest('no overflow at ${size.width}dp, ${scale}x text', (
        tester,
      ) async {
        await pumpTrackly(
          tester,
          size: size,
          textScale: scale,
          notifications: FakeNotificationService(allowed: false),
        );
        await _openFromMore(tester);
        await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Delete all data'), findsOneWidget);
      });
    }
  });
}
