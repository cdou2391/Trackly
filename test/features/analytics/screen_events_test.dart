import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/core/navigation/app_bottom_navigation.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/settings/application/settings_store.dart';

import '../../helpers/test_app.dart';

class _Analytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  List<String> get names => [for (final e in events) e.$1];

  Map<String, Object>? parametersOf(String name) =>
      events.firstWhere((e) => e.$1 == name).$2;

  int count(String name) => names.where((n) => n == name).length;

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

Finder _tab(String label) => find.descendant(
  of: find.byType(AppBottomNavigation),
  matching: find.text(label),
);

const _tall = Size(390, 1400);

void main() {
  group('screens', () {
    tracklyTest('Home is counted at launch and each time it is chosen', (
      tester,
    ) async {
      final analytics = _Analytics();
      await pumpTrackly(tester, size: _tall, analytics: analytics);
      expect(analytics.count(AnalyticsEvents.homeOpened), 1);

      await tester.tap(_tab('Insights'));
      await settle(tester);
      expect(analytics.count(AnalyticsEvents.homeOpened), 1);
      expect(analytics.count(AnalyticsEvents.insightsOpened), 1);

      await tester.tap(_tab('Home'));
      await settle(tester);
      expect(analytics.count(AnalyticsEvents.homeOpened), 2);
    });

    tracklyTest('Payment history is counted when it opens', (tester) async {
      final analytics = _Analytics();
      await pumpTrackly(tester, size: _tall, analytics: analytics);
      expect(analytics.count(AnalyticsEvents.historyOpened), 0);

      await tester.tap(_tab('More'));
      await settle(tester);
      await tester.tap(find.text('Payment history'));
      await settle(tester);

      expect(analytics.count(AnalyticsEvents.historyOpened), 1);
    });
  });

  group('rows on Home', () {
    tracklyTest('an upcoming charge opened sends facts, never the name', (
      tester,
    ) async {
      final analytics = _Analytics();
      await pumpTrackly(
        tester,
        size: _tall,
        analytics: analytics,
        items: [testItem('Secret Club', due: DateTime(2026, 10, 12))],
      );

      await tester.tap(find.text('Secret Club'));
      await settle(tester);

      expect(analytics.count(AnalyticsEvents.upcomingItemOpened), 1);
      expect(analytics.count(AnalyticsEvents.recentPaymentOpened), 0);
      expect(analytics.parametersOf(AnalyticsEvents.upcomingItemOpened), {
        'item_type': 'subscription',
        'frequency': 'monthly',
        'currency': 'USD',
        'is_trial': false,
      });
      expect(find.text('Mark as paid'), findsOneWidget); // really opened
    });

    tracklyTest('a recent payment opened is counted separately', (
      tester,
    ) async {
      final analytics = _Analytics();
      final db = await pumpTrackly(
        tester,
        size: const Size(390, 1400),
        analytics: analytics,
        items: [testItem('Netflix', due: DateTime(2026, 11, 20))],
      );
      await tester.runAsync(
        () => db.paymentsDao.insertPayment(
          Payment(
            id: 'p1',
            recurringItemId: 'Netflix',
            amount: 10,
            currencyCode: 'USD',
            dueDate: DateTime(2026, 10, 5),
            paidDate: DateTime(2026, 10, 5),
            status: PaymentStatus.paid,
            createdAt: testNow,
          ),
        ),
      );
      await settle(tester);

      // Netflix is both upcoming and paid; the payment row has the date chip.
      await tester.tap(find.textContaining('Paid'));
      await settle(tester);

      expect(analytics.count(AnalyticsEvents.recentPaymentOpened), 1);
      expect(analytics.count(AnalyticsEvents.upcomingItemOpened), 0);
    });
  });

  group('quick add', () {
    Future<void> type(WidgetTester tester) async {
      await tester.enterText(find.byKey(const Key('quick-add-name')), 'Hulu');
      await settle(tester);
    }

    void background(WidgetTester tester) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    }

    tracklyTest('leaving a started form is counted once', (tester) async {
      final analytics = _Analytics();
      await pumpTrackly(tester, size: _tall, analytics: analytics);

      background(tester); // nothing typed yet
      expect(analytics.count(AnalyticsEvents.quickAddAbandoned), 0);

      await type(tester);
      background(tester);
      background(tester);

      expect(analytics.count(AnalyticsEvents.quickAddStarted), 1);
      expect(analytics.count(AnalyticsEvents.quickAddAbandoned), 1);
    });

    tracklyTest('a saved form is not abandoned, the next attempt can be', (
      tester,
    ) async {
      final analytics = _Analytics();
      await pumpTrackly(tester, size: _tall, analytics: analytics);

      await type(tester);
      await tester.enterText(find.byKey(const Key('quick-add-amount')), '9.99');
      await settle(tester);
      await tester.ensureVisible(find.byKey(const Key('quick-add-save')));
      await tester.tap(find.byKey(const Key('quick-add-save')));
      await settle(tester);
      expect(analytics.count(AnalyticsEvents.quickAddCompleted), 1);

      background(tester);
      expect(analytics.count(AnalyticsEvents.quickAddAbandoned), 0);

      await type(tester);
      background(tester);
      expect(analytics.count(AnalyticsEvents.quickAddStarted), 2);
      expect(analytics.count(AnalyticsEvents.quickAddAbandoned), 1);
    });
  });

  group('trial ended', () {
    tracklyTest('is counted once per trial, and only after it ended', (
      tester,
    ) async {
      final analytics = _Analytics();
      final store = InMemorySettingsStore();
      await pumpTrackly(
        tester,
        analytics: analytics,
        settings: store,
        items: [
          testItem('Over', trialEnd: DateTime(2026, 10, 8)),
          testItem('Today', trialEnd: DateTime(2026, 10, 9)),
          testItem('Later', trialEnd: DateTime(2026, 10, 20)),
          testItem('Plain'),
        ],
      );

      expect(analytics.count(AnalyticsEvents.trialEnded), 1);
      expect(analytics.parametersOf(AnalyticsEvents.trialEnded), {
        'item_type': 'subscription',
        'frequency': 'monthly',
        'currency': 'USD',
        'is_trial': true,
      });
      expect(store.reportedTrialEnds, {'Over'});

      // The same device on its next launch does not count it again.
      final next = _Analytics();
      await pumpTrackly(
        tester,
        analytics: next,
        settings: store,
        items: [testItem('Over', trialEnd: DateTime(2026, 10, 8))],
      );
      expect(next.count(AnalyticsEvents.trialEnded), 0);
    });
  });
}
