import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/features/payments/domain/payment.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1800);

class _RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('More').last);
  await settle(tester);
  await tester.tap(find.text('Settings'));
  await settle(tester);
}

String _text(List<int> bytes) => utf8.decode(bytes.skip(3).toList());

void main() {
  final items = [
    testItem('Netflix', amount: 15.5, categoryId: 'entertainment'),
    testItem('Spotify', notes: 'Family, "plan"'),
  ];

  tracklyTest('Export data shares a subscriptions and a payments file', (
    tester,
  ) async {
    final sharer = FakeDataSharer();
    final db = await pumpTrackly(
      tester,
      size: _tall,
      items: items,
      dataSharer: sharer,
    );
    await tester.runAsync(
      () => db.paymentsDao.insertPayment(
        Payment(
          id: 'p1',
          recurringItemId: 'Netflix',
          amount: 15.5,
          currencyCode: 'USD',
          dueDate: DateTime(2026, 9, 20),
          paidDate: DateTime(2026, 9, 20),
          status: PaymentStatus.paid,
          createdAt: testNow,
        ),
      ),
    );
    await _openSettings(tester);

    await tester.tap(find.text('Export data (CSV)'));
    await settle(tester);

    expect(sharer.shared, hasLength(1));
    final files = sharer.shared.single;
    expect(files.map((f) => f.name), [
      'trackly-subscriptions-2026-10-09.csv',
      'trackly-payments-2026-10-09.csv',
    ]);

    final subscriptions = _text(files[0].bytes);
    expect(subscriptions, contains('Netflix,subscription,active,15.50,USD'));
    expect(subscriptions, contains(',Entertainment,'));
    expect(subscriptions, contains('"Family, ""plan"""'));
    expect(
      _text(files[1].bytes),
      contains('Netflix,2026-09-20,2026-09-20,paid,15.50,USD'),
    );
  });

  tracklyTest('exporting changes nothing and logs data_exported', (
    tester,
  ) async {
    final analytics = _RecordingAnalytics();
    final db = await pumpTrackly(
      tester,
      size: _tall,
      items: items,
      analytics: analytics,
    );
    await _openSettings(tester);

    await tester.tap(find.text('Export data (CSV)'));
    await settle(tester);

    final remaining = await tester.runAsync(
      () => db.recurringItemsDao.getAll(),
    );
    expect(remaining, hasLength(2));
    final exported = analytics.events.where(
      (e) => e.$1 == AnalyticsEvents.dataExported,
    );
    expect(exported, hasLength(1));
    expect(exported.single.$2, isNull, reason: 'no user data in the event');
  });

  tracklyTest('with nothing added it says so and shares nothing', (
    tester,
  ) async {
    final sharer = FakeDataSharer();
    final analytics = _RecordingAnalytics();
    await pumpTrackly(
      tester,
      size: _tall,
      dataSharer: sharer,
      analytics: analytics,
    );
    await _openSettings(tester);

    await tester.tap(find.text('Export data (CSV)'));
    await settle(tester);

    expect(
      find.text('Nothing to export yet. Add a subscription first.'),
      findsOneWidget,
    );
    expect(sharer.shared, isEmpty);
    expect(
      analytics.events.where((e) => e.$1 == AnalyticsEvents.dataExported),
      isEmpty,
    );
  });

  tracklyTest('when the share sheet fails it says so and logs nothing', (
    tester,
  ) async {
    final sharer = FakeDataSharer()..failWith = StateError('no share sheet');
    final analytics = _RecordingAnalytics();
    await pumpTrackly(
      tester,
      size: _tall,
      items: items,
      dataSharer: sharer,
      analytics: analytics,
    );
    await _openSettings(tester);

    await tester.tap(find.text('Export data (CSV)'));
    await settle(tester);

    expect(find.text('Couldn’t export your data. Try again.'), findsOneWidget);
    expect(
      analytics.events.where((e) => e.$1 == AnalyticsEvents.dataExported),
      isEmpty,
    );
  });

  tracklyTest('the export row sits first in Your data, with its hint', (
    tester,
  ) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSettings(tester);

    expect(
      find.text('Subscriptions and payment history, for Excel or Sheets'),
      findsOneWidget,
    );
    final export = tester.getTopLeft(find.text('Export data (CSV)')).dy;
    final clear = tester.getTopLeft(find.text('Clear payment history')).dy;
    expect(export, lessThan(clear));
  });

  group('layout', () {
    for (final (size, scale) in [
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 1.6),
    ]) {
      tracklyTest('no overflow at ${size.width}dp, ${scale}x text', (
        tester,
      ) async {
        await pumpTrackly(tester, size: size, textScale: scale, items: items);
        await _openSettings(tester);
        await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
        await settle(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Export data (CSV)'), findsOneWidget);
      });
    }
  });
}
