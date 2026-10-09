import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

void main() {
  group('empty state', () {
    tracklyTest('shows a zero total, zero counts and an invitation',
        (tester) async {
      await pumpTrackly(tester);

      expect(find.text('YOUR RECURRING COST'), findsOneWidget);
      expect(find.text(r'$0.00 / month'), findsOneWidget);
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
      await pumpTrackly(tester);

      expect(find.text('Subscriptions & Bills'), findsOneWidget);
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.text('Add a new subscription'), findsOneWidget);
      expect(find.text('Quick add — you can edit details later'),
          findsOneWidget);
    });
  });

  group('with data', () {
    tracklyTest('shows monthly and yearly totals and upcoming rows',
        (tester) async {
      await pumpTrackly(tester, items: [
        testItem('Netflix', amount: 15, due: DateTime(2026, 10, 10)),
        testItem('Spotify', amount: 10, due: DateTime(2026, 10, 14)),
      ]);

      expect(find.text(r'$25.00 / month'), findsOneWidget);
      expect(find.text(r'$300.00 per year'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('Due tomorrow'), findsOneWidget);
      expect(find.text('In 5 days'), findsOneWidget);
      expect(find.text('Monthly • USD'), findsNWidgets(2));
      expect(find.text('No upcoming charges'), findsNothing);
    });

    tracklyTest('relative labels: today, overdue and a far date',
        (tester) async {
      await pumpTrackly(tester, items: [
        testItem('Overdue', due: DateTime(2026, 10, 7)),
        testItem('Today', due: DateTime(2026, 10, 9)),
        testItem('Far', due: DateTime(2026, 10, 30)),
      ]);

      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Due today'), findsOneWidget);
      expect(find.text('Oct 30'), findsOneWidget);
    });

    tracklyTest('multiple currencies are grouped, never summed',
        (tester) async {
      await pumpTrackly(tester, items: [
        testItem('Netflix', amount: 15),
        testItem('Internet', amount: 30000, currency: 'RWF'),
        testItem('Hosting', amount: 8, currency: 'EUR'),
      ]);

      expect(find.text('RWF 30,000'), findsWidgets);
      expect(find.text('€8.00'), findsWidgets);
      expect(find.text('+ 1 other currency'), findsOneWidget);
      expect(find.textContaining('/ month'), findsNothing);
    });

    tracklyTest('a running trial counts in Trial and is excluded from the total',
        (tester) async {
      await pumpTrackly(tester, items: [
        testItem('Netflix', amount: 15),
        testItem('Canva', amount: 14.99, trialEnd: DateTime(2026, 11, 15)),
      ]);

      expect(find.text(r'$15.00 / month'), findsOneWidget);
      // Trial pill on the Canva row.
      expect(find.text('Trial'), findsNWidgets(2)); // card label + pill
    });

    tracklyTest('only the next 5 upcoming charges are listed', (tester) async {
      await pumpTrackly(tester, items: [
        for (var i = 0; i < 7; i++)
          testItem('Service $i', due: DateTime(2026, 10, 10 + i)),
      ]);

      await tester.scrollUntilVisible(
        find.text('Service 4'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Service 4'), findsOneWidget);
      expect(find.text('Service 5'), findsNothing);
      expect(find.text('Service 6'), findsNothing);
    });
  });

  group('Quick Add', () {
    Finder saveButton() => find.widgetWithText(FilledButton, 'Save');

    Future<void> scrollToQuickAdd(WidgetTester tester) async {
      await tester.scrollUntilVisible(
        find.text('Add a new subscription'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }

    tracklyTest('Save stays disabled until name and amount are valid',
        (tester) async {
      await pumpTrackly(tester);
      await scrollToQuickAdd(tester);
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await tester.enterText(
          find.widgetWithText(TextField, 'Search a service'), 'Gym');
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '0');
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '25');
      await tester.pump();
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNotNull);
    });

    tracklyTest('suggests catalog services and fills the name',
        (tester) async {
      await pumpTrackly(tester);
      await scrollToQuickAdd(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Search a service'), 'net');
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Netflix'), findsOneWidget);

      await tester.tap(find.widgetWithText(ListTile, 'Netflix'));
      await tester.pump();
      expect(find.widgetWithText(ListTile, 'Netflix'), findsNothing);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Search a service')
                .evaluate()
                .isEmpty
                ? find.byType(TextField).first
                : find.widgetWithText(TextField, 'Search a service'))
            .controller!
            .text,
        'Netflix',
      );
    });

    tracklyTest('saving a catalog service adds it to Upcoming', (tester) async {
      final db = await pumpTrackly(tester);
      await scrollToQuickAdd(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Search a service'), 'net');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Netflix'));
      await tester.pump();
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '15.49');
      await tester.pump();

      await tester.tap(saveButton());
      await settle(tester);

      // Start date defaults to today, so the next charge is a month away.
      expect(find.text('Saved — next charge Nov 9'), findsOneWidget);

      final saved =
          await tester.runAsync(() => db.recurringItemsDao.getActive());
      expect(saved, hasLength(1));
      expect(saved!.single.name, 'Netflix');
      expect(saved.single.amount, 15.49);
      expect(saved.single.frequency, BillingFrequency.monthly);
      expect(saved.single.logoKey, 'netflix');
      expect(saved.single.categoryId, 'entertainment');
      expect(saved.single.currencyCode, 'USD');
      expect(saved.single.nextDueDate, DateTime(2026, 11, 9));

      // The form resets and Save is disabled again.
      expect(tester.widget<FilledButton>(saveButton()).onPressed, isNull);

      // 9 Oct + 1 month is 31 days away; it must still be listed in Upcoming.
      await tester.scrollUntilVisible(
        find.text('Nov 9'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Nov 9'), findsOneWidget);
      expect(find.text(r'$15.49'), findsOneWidget);
      expect(find.text('No upcoming charges'), findsNothing);
    });

    tracklyTest('a custom service is saved without a logo key',
        (tester) async {
      final db = await pumpTrackly(tester);
      await scrollToQuickAdd(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Search a service'), 'Gym near home');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '35');
      await tester.pump();
      await tester.tap(saveButton());
      await settle(tester);

      final saved =
          await tester.runAsync(() => db.recurringItemsDao.getActive());
      expect(saved!.single.name, 'Gym near home');
      expect(saved.single.logoKey, isNull);
      expect(saved.single.categoryId, isNull);
    });

    tracklyTest('editing a chosen suggestion makes it a custom service',
        (tester) async {
      final db = await pumpTrackly(tester);
      await scrollToQuickAdd(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Search a service'), 'net');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'Netflix'));
      await tester.pump();
      await tester.enterText(
          find.byType(TextField).first, 'Netflix family');
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '20');
      await tester.pump();
      await tester.tap(saveButton());
      await settle(tester);

      final saved =
          await tester.runAsync(() => db.recurringItemsDao.getActive());
      expect(saved!.single.name, 'Netflix family');
      expect(saved.single.logoKey, isNull);
    });
  });
}
