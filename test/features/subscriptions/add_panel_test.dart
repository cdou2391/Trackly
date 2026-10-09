import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

final _panel = find.byKey(const Key('add-panel'));
Finder _inPanel(Finder finder) => find.descendant(of: _panel, matching: finder);
Finder _plus() => find.byIcon(Icons.add_rounded).last;
Finder _save() => _inPanel(find.widgetWithText(FilledButton, 'Save'));

/// Scrolls [finder] into view, taps it and lets animations finish.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await settle(tester);
}

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(_plus());
  await settle(tester);
}

Future<void> _fillBasics(
  WidgetTester tester, {
  String name = 'Gym',
  String amount = '35',
}) async {
  await tester.enterText(
    _inPanel(find.widgetWithText(TextField, 'Search a service or type a name')),
    name,
  );
  await tester.enterText(
    _inPanel(find.widgetWithText(TextField, 'Amount')),
    amount,
  );
  await tester.pump();
}

/// Opens a dropdown inside the panel and picks [option].
Future<void> _choose(
  WidgetTester tester, {
  required String field,
  required String option,
}) async {
  await _tap(tester, _inPanel(find.text(field)));
  await tester.tap(find.text(option).last);
  await settle(tester);
}

void main() {
  group('opening and closing', () {
    tracklyTest('is not built until the + is tapped', (tester) async {
      await pumpTrackly(tester);
      expect(_panel, findsNothing);

      await _openPanel(tester);
      expect(_panel, findsOneWidget);
      expect(_inPanel(find.text('Add subscription')), findsOneWidget);
    });

    tracklyTest('slides up above the navigation bar, which stays visible', (
      tester,
    ) async {
      await pumpTrackly(tester);
      await _openPanel(tester);

      final nav = tester.getTopLeft(find.text('Home')).dy;
      final panelBottom = tester.getBottomLeft(_panel).dy;
      expect(panelBottom, lessThanOrEqualTo(nav));
      for (final label in ['Home', 'Insights', 'Calendar', 'More']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    tracklyTest('the + turns into a cross while open', (tester) async {
      await pumpTrackly(tester);
      RotationTransition rotation() => tester.widget<RotationTransition>(
        find.ancestor(of: _plus(), matching: find.byType(RotationTransition)),
      );

      expect(rotation().turns.value, 0);
      await _openPanel(tester);
      expect(rotation().turns.value, 0.125);
    });

    tracklyTest('the + closes it again', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await tester.tap(_plus());
      await settle(tester);
      expect(_panel, findsNothing);
    });

    tracklyTest('the close button closes it', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await tester.tap(find.byTooltip('Close'));
      await settle(tester);
      expect(_panel, findsNothing);
    });

    tracklyTest('tapping outside closes it', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await tester.tapAt(const Offset(195, 60));
      await settle(tester);
      expect(_panel, findsNothing);
    });

    tracklyTest('the system back gesture closes it', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(_panel, findsNothing);
    });

    tracklyTest('switching tabs closes it', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await tester.tap(find.text('Insights'));
      await settle(tester);
      expect(_panel, findsNothing);
      expect(find.text('Insights'), findsWidgets);
    });

    tracklyTest('the empty-state button opens it', (tester) async {
      await pumpTrackly(tester);
      await _tap(
        tester,
        find.widgetWithText(OutlinedButton, 'Add subscription'),
      );
      expect(_panel, findsOneWidget);
    });

    tracklyTest('starts blank every time it is opened', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await _fillBasics(tester);
      await tester.tap(find.byTooltip('Close'));
      await settle(tester);

      await _openPanel(tester);
      final name = tester.widget<TextField>(
        _inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
      );
      expect(name.controller!.text, isEmpty);
      expect(tester.widget<FilledButton>(_save()).onPressed, isNull);
    });
  });

  group('validation', () {
    tracklyTest('Save needs a name and a positive amount', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      bool enabled() => tester.widget<FilledButton>(_save()).onPressed != null;

      expect(enabled(), isFalse);
      await _fillBasics(tester, name: 'Gym', amount: '');
      expect(enabled(), isFalse);
      await _fillBasics(tester, name: 'Gym', amount: '0');
      expect(enabled(), isFalse);
      await _fillBasics(tester, name: '   ', amount: '35');
      expect(enabled(), isFalse);
      await _fillBasics(tester, name: 'Gym', amount: '35');
      expect(enabled(), isTrue);
    });

    tracklyTest('a free trial also needs an end date', (tester) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await _fillBasics(tester);
      await _tap(tester, _inPanel(find.byType(Switch)).first);

      expect(_inPanel(find.text('Trial ends')), findsOneWidget);
      expect(_inPanel(find.text('Start date')), findsNothing);
      expect(tester.widget<FilledButton>(_save()).onPressed, isNull);

      await _tap(tester, _inPanel(find.text('Trial ends')));
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(tester.widget<FilledButton>(_save()).onPressed, isNotNull);
    });
  });

  group('saving', () {
    tracklyTest('saves every field, closes, and confirms with a snack bar', (
      tester,
    ) async {
      final db = await pumpTrackly(tester);
      await _openPanel(tester);

      await _fillBasics(tester, name: 'Gym near home', amount: '35,50');
      await tester.tap(_inPanel(find.text('Bill')));
      await settle(tester);
      await _choose(tester, field: 'USD', option: 'EUR');
      await _choose(tester, field: 'Monthly', option: 'Quarterly');
      await _tap(tester, _inPanel(find.text('7 days before')));
      await _tap(tester, _inPanel(find.text('More details')));
      await _choose(tester, field: 'Category', option: 'Fitness');
      await tester.enterText(
        _inPanel(find.widgetWithText(TextField, 'Notes')),
        'Annual contract',
      );
      await tester.pump();

      await tester.tap(_save());
      await settle(tester);

      expect(_panel, findsNothing);
      // Quarterly from 9 Oct is 9 Jan.
      expect(find.text('Saved — next charge Jan 9'), findsOneWidget);

      final saved = (await tester.runAsync(
        () => db.recurringItemsDao.getActive(),
      ))!.single;
      expect(saved.name, 'Gym near home');
      expect(saved.type, RecurringItemType.bill);
      expect(saved.amount, 35.5);
      expect(saved.currencyCode, 'EUR');
      expect(saved.frequency, BillingFrequency.quarterly);
      expect(saved.nextDueDate, DateTime(2027, 1, 9));
      expect(saved.reminderDaysBefore, 7);
      expect(saved.remindersEnabled, isTrue);
      expect(saved.categoryId, 'fitness');
      expect(saved.notes, 'Annual contract');
      expect(saved.logoKey, isNull);
      expect(saved.isTrial, isFalse);
    });

    tracklyTest('a catalog suggestion fills the name, logo and category', (
      tester,
    ) async {
      final db = await pumpTrackly(tester);
      await _openPanel(tester);

      await tester.enterText(
        _inPanel(
          find.widgetWithText(TextField, 'Search a service or type a name'),
        ),
        'net',
      );
      await tester.pump();
      await tester.tap(_inPanel(find.widgetWithText(ListTile, 'Netflix')));
      await tester.pump();
      await tester.enterText(
        _inPanel(find.widgetWithText(TextField, 'Amount')),
        '15.49',
      );
      await tester.pump();
      await tester.tap(_save());
      await settle(tester);

      final saved = (await tester.runAsync(
        () => db.recurringItemsDao.getActive(),
      ))!.single;
      expect(saved.name, 'Netflix');
      expect(saved.logoKey, 'netflix');
      expect(saved.categoryId, 'entertainment');
      expect(saved.nextDueDate, DateTime(2026, 11, 9));
    });

    tracklyTest('turning reminders off is saved', (tester) async {
      final db = await pumpTrackly(tester);
      await _openPanel(tester);
      await _fillBasics(tester);

      // The second switch is "Remind me".
      await _tap(tester, _inPanel(find.byType(Switch)).at(1));
      expect(_inPanel(find.text('Same day')), findsNothing);
      await tester.tap(_save());
      await settle(tester);

      final saved = (await tester.runAsync(
        () => db.recurringItemsDao.getActive(),
      ))!.single;
      expect(saved.remindersEnabled, isFalse);
    });

    tracklyTest('a free trial is saved as a trial and counted separately', (
      tester,
    ) async {
      final db = await pumpTrackly(tester);
      await _openPanel(tester);
      await _fillBasics(tester, name: 'Canva Pro', amount: '14.99');

      await _tap(tester, _inPanel(find.byType(Switch)).first);
      await _tap(tester, _inPanel(find.text('Trial ends')));
      await tester.tap(find.text('OK')); // today
      await settle(tester);
      await tester.tap(_save());
      await settle(tester);

      final saved = (await tester.runAsync(
        () => db.recurringItemsDao.getActive(),
      ))!.single;
      expect(saved.isTrial, isTrue);
      expect(saved.trialEndDate, DateTime(2026, 10, 9));
      expect(saved.nextDueDate, DateTime(2026, 10, 9));

      // Home: the trial counts in Trial, not Active, and not in the total.
      expect(find.text(r'$0.00 / month'), findsOneWidget);
      expect(find.text('Trial'), findsWidgets);
    });

    tracklyTest('the new item shows up on Home behind the closed panel', (
      tester,
    ) async {
      await pumpTrackly(tester);
      await _openPanel(tester);
      await _fillBasics(tester, name: 'Gym', amount: '35');
      await tester.tap(_save());
      await settle(tester);

      expect(find.text(r'$35.00 / month'), findsOneWidget);
      expect(find.text('Gym'), findsWidgets);
    });
  });
}
