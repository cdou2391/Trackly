import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/shared/widgets/service_icon.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1400);

final _panel = find.byKey(const Key('add-panel'));
Finder _inPanel(Finder finder) => find.descendant(of: _panel, matching: finder);

Finder row(String name) => find.widgetWithText(ListTile, name);

Finder _field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
  group('the suggestion list', () {
    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(_field('quick-add-name'), text);
      await settle(tester);
    }

    tracklyTest('shows the logo, name and category of a brand', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await type(tester, 'Netfl');

      expect(row('Netflix'), findsOneWidget);
      expect(
        find.descendant(
          of: row('Netflix'),
          matching: find.text('Entertainment'),
        ),
        findsOneWidget,
      );
      final svg = tester.widget<SvgPicture>(
        find.descendant(
          of: find.descendant(
            of: row('Netflix'),
            matching: find.byType(ServiceIcon),
          ),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/logos/netflix.svg',
      );
      expect(
        find.descendant(of: row('Netflix'), matching: find.text('Bill')),
        findsNothing,
      );
    });

    tracklyTest('a service without a logo gets the Trackly mark', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall);
      await type(tester, 'Hulu');

      final svg = tester.widget<SvgPicture>(
        find.descendant(
          of: find.descendant(
            of: row('Hulu'),
            matching: find.byType(ServiceIcon),
          ),
          matching: find.byType(SvgPicture),
        ),
      );
      expect(
        (svg.bytesLoader as SvgAssetLoader).assetName,
        'assets/illustrations/trackly_logo.svg',
      );
    });

    tracklyTest('a bill is tagged, with its category and no mark', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall);
      await type(tester, 'Electric');

      expect(
        find.descendant(of: row('Electricity'), matching: find.text('Bill')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row('Electricity'),
          matching: find.text('Utilities'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row('Electricity'),
          matching: find.byType(SvgPicture),
        ),
        findsNothing,
      );
    });

    tracklyTest('fits a narrow phone with large text', (tester) async {
      // An overflow would fail the test on its own.
      await pumpTrackly(tester, size: const Size(360, 1800), textScale: 1.6);
      await type(tester, 'e');
      expect(row('Electricity'), findsOneWidget);
    });

    tracklyTest('the add form shows the same rows', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await settle(tester);
      await tester.enterText(
        _inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
        'Rent',
      );
      await settle(tester);

      expect(_inPanel(row('Rent')), findsOneWidget);
      expect(
        find.descendant(
          of: _inPanel(row('Rent')),
          matching: find.text('Housing'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: _inPanel(row('Rent')), matching: find.text('Bill')),
        findsOneWidget,
      );
    });
  });

  group('Quick Add', () {
    Future<void> add(
      WidgetTester tester,
      String name, {
      bool tap = true,
    }) async {
      await tester.enterText(_field('quick-add-name'), name);
      await settle(tester);
      if (tap) {
        await tester.tap(find.text(name).first);
        await settle(tester);
      }
      await tester.enterText(_field('quick-add-amount'), '800');
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('quick-add-save')));
      await tester.tap(find.byKey(const Key('quick-add-save')));
      await settle(tester);
    }

    tracklyTest('a tapped bill suggestion is saved as a bill', (tester) async {
      final db = await pumpTrackly(tester, size: _tall);
      await add(tester, 'Rent');

      final item = (await tester.runAsync(() => db.recurringItemsDao.getAll()))!
          .single;
      expect(item.type, RecurringItemType.bill);
      expect(item.categoryId, 'housing');
      expect(item.logoKey, 'rent');
    });

    tracklyTest('a bill typed in full without tapping is a bill too', (
      tester,
    ) async {
      final db = await pumpTrackly(tester, size: _tall);
      await add(tester, 'water', tap: false);

      final item = (await tester.runAsync(() => db.recurringItemsDao.getAll()))!
          .single;
      expect(item.type, RecurringItemType.bill);
      expect(item.categoryId, 'utilities');
    });

    tracklyTest('a brand is still a subscription', (tester) async {
      final db = await pumpTrackly(tester, size: _tall);
      await add(tester, 'Netflix');

      final item = (await tester.runAsync(() => db.recurringItemsDao.getAll()))!
          .single;
      expect(item.type, RecurringItemType.subscription);
    });

    tracklyTest('so is a custom name', (tester) async {
      final db = await pumpTrackly(tester, size: _tall);
      await add(tester, 'My local club', tap: false);

      final item = (await tester.runAsync(() => db.recurringItemsDao.getAll()))!
          .single;
      expect(item.type, RecurringItemType.subscription);
    });
  });

  group('the add form', () {
    Future<void> openAndSearch(WidgetTester tester, String text) async {
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await settle(tester);
      await tester.enterText(
        _inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
        text,
      );
      await settle(tester);
    }

    RecurringItemType selectedType(WidgetTester tester) => tester
        .widget<SegmentedButton<RecurringItemType>>(
          _inPanel(find.byType(SegmentedButton<RecurringItemType>)),
        )
        .selected
        .single;

    tracklyTest('picking Electricity switches the form to Bill', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall);
      await openAndSearch(tester, 'Elec');
      expect(selectedType(tester), RecurringItemType.subscription);

      await tester.tap(_inPanel(find.text('Electricity')));
      await settle(tester);

      expect(selectedType(tester), RecurringItemType.bill);
    });

    tracklyTest('picking a brand switches it back to Subscription', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall);
      await openAndSearch(tester, 'Elec');
      await tester.tap(_inPanel(find.text('Electricity')));
      await settle(tester);
      expect(selectedType(tester), RecurringItemType.bill);

      await tester.enterText(
        _inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
        'Spot',
      );
      await settle(tester);
      await tester.tap(_inPanel(find.text('Spotify')));
      await settle(tester);

      expect(selectedType(tester), RecurringItemType.subscription);
    });
  });
}
