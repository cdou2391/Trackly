import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/notifications/notification_prefs.dart';
import 'package:trackly/core/notifications/notification_service.dart';
import 'package:trackly/core/notifications/reminder_plan.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/test_app.dart';

const _tall = Size(390, 1800);

void main() {
  final nameKey = find.byKey(const Key('quick-add-name'));
  final amountKey = find.byKey(const Key('quick-add-amount'));
  final save = find.byKey(const Key('quick-add-save'));
  Finder input(Finder field) =>
      find.descendant(of: field, matching: find.byType(EditableText));

  Future<void> addGym(WidgetTester tester) async {
    await tester.enterText(input(nameKey), 'Gym');
    await tester.enterText(input(amountKey), '25');
    await tester.pump();
    await tester.tap(save);
    await settle(tester);
  }

  group('permission prompt', () {
    tracklyTest('is not shown at launch', (tester) async {
      final service = FakeNotificationService(allowed: false);
      await pumpTrackly(tester, size: _tall, notifications: service);
      expect(find.text('Get reminded before it renews?'), findsNothing);
      expect(service.permissionRequests, 0);
    });

    tracklyTest('appears after the first subscription is saved', (
      tester,
    ) async {
      final service = FakeNotificationService(allowed: false);
      await pumpTrackly(tester, size: _tall, notifications: service);
      await addGym(tester);

      expect(find.text('Get reminded before it renews?'), findsOneWidget);
      expect(service.permissionRequests, 0);
    });

    tracklyTest('Turn on asks the system and schedules reminders', (
      tester,
    ) async {
      final service = FakeNotificationService(allowed: false);
      await pumpTrackly(tester, size: _tall, notifications: service);
      await addGym(tester);

      await tester.tap(find.text('Turn on reminders'));
      await settle(tester);

      expect(service.permissionRequests, 1);
      expect(find.text('Get reminded before it renews?'), findsNothing);
      expect(service.scheduled, isNotEmpty);
    });

    tracklyTest('Not now never asks the system', (tester) async {
      final service = FakeNotificationService(allowed: false);
      await pumpTrackly(tester, size: _tall, notifications: service);
      await addGym(tester);

      await tester.tap(find.text('Not now'));
      await settle(tester);

      expect(service.permissionRequests, 0);
      expect(service.scheduled, isEmpty);
    });

    tracklyTest('is skipped when notifications are already allowed', (
      tester,
    ) async {
      final service = FakeNotificationService();
      await pumpTrackly(tester, size: _tall, notifications: service);
      await addGym(tester);

      expect(find.text('Get reminded before it renews?'), findsNothing);
      expect(service.scheduled, isNotEmpty);
    });

    tracklyTest('asks at most twice', (tester) async {
      final service = FakeNotificationService(allowed: false);
      final prefs = InMemoryNotificationPrefs();
      await prefs.recordPrompt();
      await prefs.recordPrompt();
      await pumpTrackly(
        tester,
        size: _tall,
        notifications: service,
        notificationPrefs: prefs,
      );
      await addGym(tester);

      expect(find.text('Get reminded before it renews?'), findsNothing);
    });
  });

  group('tapping a reminder', () {
    tracklyTest('opens that item', (tester) async {
      final service = FakeNotificationService();
      await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix')],
        notifications: service,
      );

      service.tap(
        const NotificationTap(itemId: 'Netflix', type: ReminderType.dueSoon),
      );
      await settle(tester);

      expect(find.text('Next charge'), findsOneWidget);
    });

    tracklyTest('a launch tap opens the item', (tester) async {
      final service = FakeNotificationService()
        ..launchTap = const NotificationTap(
          itemId: 'Netflix',
          type: ReminderType.dueToday,
        );
      await pumpTrackly(
        tester,
        size: _tall,
        items: [testItem('Netflix')],
        notifications: service,
      );

      expect(find.text('Next charge'), findsOneWidget);
    });

    tracklyTest('an item that no longer exists is ignored', (tester) async {
      final service = FakeNotificationService();
      await pumpTrackly(tester, size: _tall, notifications: service);

      service.tap(
        const NotificationTap(itemId: 'gone', type: ReminderType.dueSoon),
      );
      await settle(tester);

      expect(find.text('Next charge'), findsNothing);
      expect(find.text('Subscriptions & Bills'), findsOneWidget);
    });
  });
}
