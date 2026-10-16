import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/navigation/app_bottom_navigation.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/features/import/application/data_import.dart';

import '../../helpers/fake_notification_service.dart';
import '../../helpers/privacy_fakes.dart';
import '../../helpers/test_app.dart';

const _tall = Size(390, 1800);

const _subs =
    'name,amount,currency,frequency,next_due_date,id\n'
    'Netflix,15.49,USD,monthly,2026-10-20,nf-1\n'
    'Gym,30,USD,monthly,2026-10-25,gym-1\n';

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('More').last);
  await settle(tester);
  await tester.tap(find.text('Settings'));
  await settle(tester);
}

Future<void> _tapImport(WidgetTester tester) async {
  await tester.tap(find.text('Import data (CSV)'));
  await settle(tester);
}

void main() {
  tracklyTest('the row is in Your data with its hint', (tester) async {
    await pumpTrackly(tester, size: _tall);
    await _openSettings(tester);

    expect(find.text('Import data (CSV)'), findsOneWidget);
    expect(
      find.text(
        'Restore a Trackly export, or add subscriptions from a spreadsheet',
      ),
      findsOneWidget,
    );
  });

  tracklyTest('cancelling the file chooser does nothing', (tester) async {
    final picker = FakeCsvPicker();
    final db = await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);

    await _tapImport(tester);

    expect(picker.picks, 1);
    expect(find.text('Review before importing'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(await tester.runAsync(() => db.recurringItemsDao.getAll()), isEmpty);
  });

  tracklyTest('shows what would be added, and imports only on Import', (
    tester,
  ) async {
    final analytics = FakeAnalytics();
    final picker = FakeCsvPicker([csvFile('subs.csv', _subs)]);
    final db = await pumpTrackly(
      tester,
      size: _tall,
      csvPicker: picker,
      analytics: analytics,
    );
    await _openSettings(tester);

    await _tapImport(tester);

    expect(find.text('Review before importing'), findsOneWidget);
    expect(find.text('2 new subscriptions and bills'), findsOneWidget);
    // Nothing is written until the person says so.
    expect(await tester.runAsync(() => db.recurringItemsDao.getAll()), isEmpty);
    expect(analytics.events, isNot(contains(AnalyticsEvents.dataImported)));

    await tester.tap(find.byKey(const Key('import-confirm')));
    await settle(tester);

    expect(find.text('Review before importing'), findsNothing);
    expect(
      find.text('Imported 2 subscriptions and 0 payments'),
      findsOneWidget,
    );
    final items = (await tester.runAsync(() => db.recurringItemsDao.getAll()))!;
    expect(items.map((i) => i.name).toSet(), {'Netflix', 'Gym'});
    expect(analytics.events, contains(AnalyticsEvents.dataImported));
  });

  tracklyTest('Cancel on the review imports nothing', (tester) async {
    final analytics = FakeAnalytics();
    final picker = FakeCsvPicker([csvFile('subs.csv', _subs)]);
    final db = await pumpTrackly(
      tester,
      size: _tall,
      csvPicker: picker,
      analytics: analytics,
    );
    await _openSettings(tester);
    await _tapImport(tester);

    await tester.tap(find.byKey(const Key('import-cancel')));
    await settle(tester);

    expect(find.text('Review before importing'), findsNothing);
    expect(await tester.runAsync(() => db.recurringItemsDao.getAll()), isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(analytics.events, isNot(contains(AnalyticsEvents.dataImported)));
  });

  tracklyTest('imports payments with the subscriptions', (tester) async {
    final picker = FakeCsvPicker([
      csvFile('subs.csv', _subs),
      csvFile(
        'pays.csv',
        'subscription_id,due_date,paid_date,status,amount,currency\n'
            'nf-1,2026-09-20,2026-09-20,paid,15.49,USD\n'
            'nf-1,2026-08-20,,skipped,15.49,USD\n',
      ),
    ]);
    final db = await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);
    await _tapImport(tester);

    expect(find.text('2 new subscriptions and bills'), findsOneWidget);
    expect(find.text('2 new payments'), findsOneWidget);
    await tester.tap(find.byKey(const Key('import-confirm')));
    await settle(tester);

    expect(
      find.text('Imported 2 subscriptions and 2 payments'),
      findsOneWidget,
    );
    expect(await tester.runAsync(() => db.paymentsDao.getAll()), hasLength(2));
  });

  tracklyTest('imported items get reminders and show on Home', (tester) async {
    final notifications = FakeNotificationService();
    final picker = FakeCsvPicker([csvFile('subs.csv', _subs)]);
    await pumpTrackly(
      tester,
      size: _tall,
      csvPicker: picker,
      notifications: notifications,
    );
    await _openSettings(tester);
    await _tapImport(tester);
    await tester.tap(find.byKey(const Key('import-confirm')));
    await settle(tester);

    expect(notifications.scheduled, isNotEmpty);

    await tester.tap(find.text('Home').last);
    await settle(tester);
    expect(find.text('Netflix'), findsWidgets);
  });

  tracklyTest('rows with problems are listed, and skipped on request', (
    tester,
  ) async {
    final picker = FakeCsvPicker([
      csvFile(
        'subs.csv',
        'name,amount,currency,frequency,next_due_date\n'
            'Good,10,USD,monthly,2026-10-20\n'
            'Bad amount,ten,USD,monthly,2026-10-20\n'
            'Bad date,10,USD,monthly,2026-02-30\n',
      ),
    ]);
    final db = await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);
    await _tapImport(tester);

    expect(find.text('1 new subscription or bill'), findsOneWidget);
    expect(
      find.text('2 rows have problems and will be skipped'),
      findsOneWidget,
    );
    expect(find.text('subs.csv, line 3'), findsOneWidget);
    expect(
      find.textContaining('“ten” isn’t a valid amount in “amount”'),
      findsOneWidget,
    );
    expect(find.text('subs.csv, line 4'), findsOneWidget);
    expect(
      find.textContaining('“2026-02-30” isn’t a valid date'),
      findsOneWidget,
    );
    expect(find.text('Import, skipping the problem rows'), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-confirm')));
    await settle(tester);

    final items = (await tester.runAsync(() => db.recurringItemsDao.getAll()))!;
    expect(items.map((i) => i.name), ['Good']);
  });

  tracklyTest('a file that is not a Trackly file cannot be imported', (
    tester,
  ) async {
    final picker = FakeCsvPicker([
      csvFile('other.csv', 'colour,size\nred,big'),
    ]);
    final db = await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);
    await _tapImport(tester);

    expect(find.text('Files that can’t be read'), findsOneWidget);
    expect(
      find.textContaining('doesn’t look like a Trackly file'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('import-confirm')), findsNothing);
    expect(find.text('Close'), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-cancel')));
    await settle(tester);
    expect(await tester.runAsync(() => db.recurringItemsDao.getAll()), isEmpty);
  });

  tracklyTest('a Windows-1252 file is refused with the way to fix it', (
    tester,
  ) async {
    final picker = FakeCsvPicker([
      PickedCsv(name: 'old.csv', bytes: Uint8List.fromList([0x43, 0xE9])),
    ]);
    await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);
    await _tapImport(tester);

    expect(find.textContaining('save it as “CSV UTF-8”'), findsOneWidget);
    expect(find.byKey(const Key('import-confirm')), findsNothing);
  });

  tracklyTest('a file that is too large is refused', (tester) async {
    final picker = FakeCsvPicker([
      PickedCsv(name: 'huge.csv', bytes: Uint8List(0), tooLarge: true),
    ]);
    await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);
    await _tapImport(tester);

    expect(find.text('huge.csv'), findsOneWidget);
    expect(find.text('The file is too large to import.'), findsOneWidget);
    expect(find.byKey(const Key('import-confirm')), findsNothing);
  });

  tracklyTest('what Trackly already has is left out and counted', (
    tester,
  ) async {
    final picker = FakeCsvPicker([csvFile('subs.csv', _subs)]);
    final db = await pumpTrackly(
      tester,
      size: _tall,
      csvPicker: picker,
      items: [testItem('Netflix')],
    );
    // The same subscription the file calls nf-1, found by what it looks like.
    await tester.runAsync(() => db.recurringItemsDao.deleteAll());
    await _openSettings(tester);

    // First import adds both.
    await _tapImport(tester);
    await tester.tap(find.byKey(const Key('import-confirm')));
    await settle(tester);

    // Second import of the same file has nothing new.
    await _tapImport(tester);
    expect(
      find.text('2 rows are already in Trackly and are left out'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('import-confirm')), findsNothing);
    expect(
      await tester.runAsync(() => db.recurringItemsDao.getAll()),
      hasLength(2),
    );
  });

  tracklyTest('a file chooser failure says nothing was changed', (
    tester,
  ) async {
    final picker = FakeCsvPicker()..failWith = StateError('no chooser');
    final db = await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);

    await _tapImport(tester);

    expect(find.text('Couldn’t import. Nothing was changed.'), findsOneWidget);
    expect(await tester.runAsync(() => db.recurringItemsDao.getAll()), isEmpty);
  });

  tracklyTest('a long list of problems is shortened', (tester) async {
    final rows = [
      for (var i = 0; i < 12; i++) 'Bad $i,x,USD,monthly,2026-10-20',
    ].join('\n');
    final picker = FakeCsvPicker([
      csvFile(
        'subs.csv',
        'name,amount,currency,frequency,next_due_date\n$rows\n',
      ),
    ]);
    await pumpTrackly(tester, size: _tall, csvPicker: picker);
    await _openSettings(tester);
    await _tapImport(tester);

    expect(
      find.text('12 rows have problems and will be skipped'),
      findsOneWidget,
    );
    expect(find.text('…and 6 more'), findsOneWidget);
    // Every row is a problem, so there is nothing to import and no Import button.
    expect(find.text('Nothing to import.'), findsOneWidget);
    expect(find.byKey(const Key('import-confirm')), findsNothing);
  });

  group('layout', () {
    for (final (size, scale) in [
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 1.6),
      (const Size(390, 844), 1.6),
    ]) {
      tracklyTest('the review fits at ${size.width}dp, ${scale}x text', (
        tester,
      ) async {
        final rows = [
          'Good,10,USD,monthly,2026-10-20',
          for (var i = 0; i < 8; i++) 'Bad $i,x,USD,monthly,2026-02-30',
        ].join('\n');
        final picker = FakeCsvPicker([
          csvFile(
            'a-fairly-long-file-name-for-the-subscriptions-export.csv',
            'name,amount,currency,frequency,next_due_date,category\n'
                '${rows.replaceAll('\n', ',Pets\n')},Pets\n',
          ),
        ]);
        await pumpTrackly(
          tester,
          size: size,
          textScale: scale,
          csvPicker: picker,
        );
        await _openSettings(tester);
        // Bring the row clear of the bottom navigation before tapping it.
        await tester.scrollUntilVisible(
          find.text('Import data (CSV)'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.ensureVisible(find.text('Import data (CSV)'));
        await settle(tester);
        // The page runs behind the floating bar: move the row above it.
        final overlap =
            tester.getBottomLeft(find.text('Import data (CSV)')).dy -
            (tester.getTopLeft(find.byType(AppBottomNavigation)).dy - 16);
        if (overlap > 0) {
          await tester.drag(find.byType(ListView).last, Offset(0, -overlap));
          await settle(tester);
        }
        await _tapImport(tester);

        expect(tester.takeException(), isNull);
        // The buttons stay reachable whatever the text size.
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(
          tester.getBottomLeft(find.byKey(const Key('import-cancel'))).dy,
          lessThanOrEqualTo(screen.height),
        );
        expect(find.byKey(const Key('import-confirm')), findsOneWidget);
      });
    }
  });
}
