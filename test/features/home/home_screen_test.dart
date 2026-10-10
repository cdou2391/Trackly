import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

/// A screen tall enough to build the whole Home list, so every row is found.
const _tall = Size(390, 1800);

/// The hero amount is rich text ("$25.00" large, "/month" small).
Finder _perMonth(String amount) =>
    find.text('$amount /month', findRichText: true);

void main() {
  group('empty state', () {
    tracklyTest('shows a zero total, zero counts and an invitation', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall);

      expect(find.text('Your recurring cost'), findsOneWidget);
      expect(_perMonth(r'$0.00'), findsOneWidget);
      expect(find.text('No upcoming charges'), findsOneWidget);
      expect(
        find.text('Add your first subscription to start tracking renewals.'),
        findsOneWidget,
      );
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Trial'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });

    tracklyTest('has the header and the Quick Add form', (tester) async {
      await pumpTrackly(tester, size: _tall);

      expect(find.text('Subscriptions & Bills'), findsOneWidget);
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.text('Add a new subscription'), findsOneWidget);
      expect(
        find.text('Quick add — you can edit details later'),
        findsOneWidget,
      );
    });
  });

  group('with data', () {
    tracklyTest('shows monthly and yearly totals and upcoming rows', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Netflix', amount: 15, due: DateTime(2026, 10, 10)),
          testItem('Spotify', amount: 10, due: DateTime(2026, 10, 14)),
        ],
      );

      expect(_perMonth(r'$25.00'), findsOneWidget);
      expect(find.text(r'$300.00 per year'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('Due tomorrow'), findsOneWidget);
      expect(find.text('In 5 days'), findsOneWidget);
      expect(find.text('Monthly • USD'), findsNWidgets(2));
      expect(find.text('No upcoming charges'), findsNothing);
    });

    tracklyTest('relative labels: today, overdue and a far date with year', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Late', due: DateTime(2026, 10, 7)),
          testItem('Now', due: DateTime(2026, 10, 9)),
          testItem('Far', due: DateTime(2026, 10, 30)),
        ],
      );

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Oct 30, 2026'), findsOneWidget);
    });

    tracklyTest('multiple currencies are grouped, never summed', (
      tester,
    ) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          testItem('Netflix', amount: 15),
          testItem('Internet', amount: 30000, currency: 'RWF'),
          testItem('Hosting', amount: 8, currency: 'EUR'),
        ],
      );

      expect(find.text('RWF 30,000'), findsWidgets);
      expect(find.text('€8.00'), findsWidgets);
      expect(find.text('+ 1 other currency'), findsOneWidget);
      expect(find.textContaining('/month', findRichText: true), findsNothing);
    });

    tracklyTest(
      'a running trial counts in Trial and is excluded from the total',
      (tester) async {
        await pumpTrackly(
          tester,
          size: _tall,
          items: [
            testItem('Netflix', amount: 15),
            testItem('Canva', amount: 14.99, trialEnd: DateTime(2026, 11, 15)),
          ],
        );

        expect(_perMonth(r'$15.00'), findsOneWidget);
        // Trial pill on the Canva row.
        expect(find.text('Trial'), findsNWidgets(2)); // card label + chip
      },
    );

    tracklyTest('only the next 5 upcoming charges are listed', (tester) async {
      await pumpTrackly(
        tester,
        size: _tall,
        items: [
          for (var i = 0; i < 7; i++)
            testItem('Service $i', due: DateTime(2026, 10, 10 + i)),
        ],
      );

      expect(find.text('Service 4'), findsOneWidget);
      expect(find.text('Service 5'), findsNothing);
      expect(find.text('Service 6'), findsNothing);
    });
  });

  group('Quick Add', () {
    final nameKey = find.byKey(const Key('quick-add-name'));
    final amountKey = find.byKey(const Key('quick-add-amount'));
    final frequencyKey = find.byKey(const Key('quick-add-frequency'));
    final dateKey = find.byKey(const Key('quick-add-date'));
    final save = find.byKey(const Key('quick-add-save'));

    Finder input(Finder field) =>
        find.descendant(of: field, matching: find.byType(TextField));

    TextEditingController controller(WidgetTester tester, Finder field) =>
        tester.widget<TextField>(input(field)).controller!;

    bool saveEnabled(WidgetTester tester) =>
        tester.widget<FilledButton>(save).onPressed != null;

    tracklyTest('Save stays disabled until name and amount are valid', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall);
      expect(saveEnabled(tester), isFalse);

      await tester.enterText(input(nameKey), 'Gym');
      await tester.pump();
      expect(saveEnabled(tester), isFalse);

      await tester.enterText(input(amountKey), '0');
      await tester.pump();
      expect(saveEnabled(tester), isFalse);

      await tester.enterText(input(amountKey), '25');
      await tester.pump();
      expect(saveEnabled(tester), isTrue);
    });

    tracklyTest('wide phones put amount, frequency, date and Save on one row', (
      tester,
    ) async {
      await pumpTrackly(tester, size: const Size(430, 1800));

      // Row 1: the service search, full width, above everything else.
      final nameBox = tester.getRect(nameKey);
      for (final field in [amountKey, frequencyKey, dateKey, save]) {
        expect(tester.getTopLeft(field).dy, greaterThan(nameBox.bottom));
      }
      // Row 2: one line, left to right.
      final tops = {
        for (final f in [amountKey, frequencyKey, dateKey, save])
          tester.getTopLeft(f).dy,
      };
      expect(tops, hasLength(1));
      expect(
        tester.getTopLeft(amountKey).dx,
        lessThan(tester.getTopLeft(frequencyKey).dx),
      );
      expect(
        tester.getTopLeft(frequencyKey).dx,
        lessThan(tester.getTopLeft(dateKey).dx),
      );
      expect(
        tester.getTopLeft(dateKey).dx,
        lessThan(tester.getTopLeft(save).dx),
      );
      // The search is as wide as the whole row.
      expect(
        nameBox.width,
        closeTo(tester.getRect(save).right - tester.getRect(amountKey).left, 1),
      );
      // Every field and the button share one 48 dp height.
      expect(
        {
          for (final f in [nameKey, amountKey, frequencyKey, dateKey, save])
            tester.getSize(f).height,
        },
        {48.0},
      );
    });

    tracklyTest('narrow phones wrap Quick Add into two rows', (tester) async {
      await pumpTrackly(tester, size: const Size(360, 1800));

      expect(
        tester.getTopLeft(amountKey).dy,
        tester.getTopLeft(frequencyKey).dy,
      );
      expect(tester.getTopLeft(dateKey).dy, tester.getTopLeft(save).dy);
      expect(
        tester.getTopLeft(dateKey).dy,
        greaterThan(tester.getBottomLeft(amountKey).dy),
      );
      // Touch targets stay at least 48 dp.
      for (final f in [nameKey, amountKey, frequencyKey, dateKey, save]) {
        expect(tester.getSize(f).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(f).width, greaterThanOrEqualTo(48));
      }
    });

    tracklyTest('shows the currency symbol and a start-date placeholder', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall);

      expect(
        find.descendant(of: amountKey, matching: find.text(r'$')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: amountKey, matching: find.text('0.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dateKey, matching: find.text('Start date')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: frequencyKey, matching: find.text('Monthly')),
        findsOneWidget,
      );
    });

    tracklyTest('suggests catalog services and fills the name', (tester) async {
      await pumpTrackly(tester, size: _tall);

      await tester.enterText(input(nameKey), 'net');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Netflix'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Netflix'));
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Netflix'), findsNothing);
      expect(controller(tester, nameKey).text, 'Netflix');
    });

    tracklyTest('saving a catalog service adds it to Upcoming', (tester) async {
      final db = await pumpTrackly(tester, size: _tall);

      await tester.enterText(input(nameKey), 'net');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Netflix'));
      await tester.pump();
      await tester.enterText(input(amountKey), '15.49');
      await tester.pump();

      await tester.tap(save);
      await settle(tester);

      // Start date defaults to today, so the next charge is a month away.
      expect(find.text('Saved — next charge Nov 9'), findsOneWidget);

      final saved = await tester.runAsync(
        () => db.recurringItemsDao.getActive(),
      );
      expect(saved, hasLength(1));
      expect(saved!.single.name, 'Netflix');
      expect(saved.single.amount, 15.49);
      expect(saved.single.frequency, BillingFrequency.monthly);
      expect(saved.single.logoKey, 'netflix');
      expect(saved.single.categoryId, 'entertainment');
      expect(saved.single.currencyCode, 'USD');
      expect(saved.single.nextDueDate, DateTime(2026, 11, 9));

      // The form resets and Save is disabled again.
      expect(saveEnabled(tester), isFalse);

      // 9 Oct + 1 month is 31 days away; it must still be listed in Upcoming.
      expect(find.text('Nov 9, 2026'), findsOneWidget);
      expect(find.text(r'$15.49'), findsOneWidget);
      expect(find.text('No upcoming charges'), findsNothing);
    });

    tracklyTest('a custom service is saved without a logo key', (tester) async {
      final db = await pumpTrackly(tester, size: _tall);

      await tester.enterText(input(nameKey), 'Gym near home');
      await tester.enterText(input(amountKey), '35');
      await tester.pump();
      await tester.tap(save);
      await settle(tester);

      final saved = await tester.runAsync(
        () => db.recurringItemsDao.getActive(),
      );
      expect(saved!.single.name, 'Gym near home');
      expect(saved.single.logoKey, isNull);
      expect(saved.single.categoryId, isNull);
    });

    tracklyTest('editing a chosen suggestion makes it a custom service', (
      tester,
    ) async {
      final db = await pumpTrackly(tester, size: _tall);

      await tester.enterText(input(nameKey), 'net');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Netflix'));
      await tester.pump();
      await tester.enterText(input(nameKey), 'Netflix family');
      await tester.enterText(input(amountKey), '20');
      await tester.pump();
      await tester.tap(save);
      await settle(tester);

      final saved = await tester.runAsync(
        () => db.recurringItemsDao.getActive(),
      );
      expect(saved!.single.name, 'Netflix family');
      expect(saved.single.logoKey, isNull);
    });
  });
}
