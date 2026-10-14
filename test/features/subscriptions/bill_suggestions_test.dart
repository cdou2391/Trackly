import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1400);

final _panel = find.byKey(const Key('add-panel'));
Finder _inPanel(Finder finder) => find.descendant(of: _panel, matching: finder);

Finder _field(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

void main() {
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
