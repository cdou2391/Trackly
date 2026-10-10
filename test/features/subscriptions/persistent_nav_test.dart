import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/navigation/app_bottom_navigation.dart';

import '../../helpers/test_app.dart';

const _size = Size(390, 1400);

Future<void> _openNetflix(WidgetTester tester) async {
  await pumpTrackly(
    tester,
    size: _size,
    items: [testItem('Netflix', amount: 15.49, due: DateTime(2026, 10, 15))],
  );
  await tester.tap(find.text('Netflix'));
  await settle(tester);
}

Finder get _nav => find.byType(AppBottomNavigation);

/// The tab labels in the bar (the page title may repeat a name, e.g. "More").
Finder _tab(String label) =>
    find.descendant(of: _nav, matching: find.text(label));

/// Index of the highlighted tab: the one whose label uses the accent color.
int _selectedTab(WidgetTester tester) {
  final labels = ['Home', 'Insights', 'Calendar', 'More'];
  final styles = [for (final l in labels) tester.widget<Text>(_tab(l)).style!];
  // The selected label is the only semi-bold one.
  return styles.indexWhere((s) => s.fontWeight == FontWeight.w600);
}

void main() {
  group('the bar is always visible', () {
    tracklyTest('on the item detail screen', (tester) async {
      await _openNetflix(tester);

      expect(find.text('Mark as paid'), findsOneWidget); // really on detail
      expect(_nav, findsOneWidget);
      for (final label in ['Home', 'Insights', 'Calendar', 'More']) {
        expect(_tab(label), findsOneWidget, reason: label);
      }
    });

    tracklyTest('on All subscriptions and Payment history', (tester) async {
      await pumpTrackly(tester, size: _size, items: [testItem('Netflix')]);
      await tester.tap(find.text('More').last);
      await settle(tester);

      await tester.tap(find.text('All subscriptions'));
      await settle(tester);
      expect(find.text('Netflix'), findsOneWidget);
      expect(_nav, findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);

      await tester.tap(find.text('Payment history'));
      await settle(tester);
      expect(
        find.text('Payments you mark as paid will show up here.'),
        findsOneWidget,
      );
      expect(_nav, findsOneWidget);
    });

    tracklyTest('and does not move when opening a screen', (tester) async {
      await pumpTrackly(tester, size: _size, items: [testItem('Netflix')]);
      final before = tester.getTopLeft(_nav);
      await tester.tap(find.text('Netflix'));
      await settle(tester);
      expect(tester.getTopLeft(_nav), before);
    });
  });

  group('tabs', () {
    tracklyTest('keep the origin tab highlighted inside a screen', (
      tester,
    ) async {
      await _openNetflix(tester); // opened from Home
      expect(_selectedTab(tester), 0);
    });

    tracklyTest('opened from More, More stays highlighted', (tester) async {
      await pumpTrackly(tester, size: _size, items: [testItem('Netflix')]);
      await tester.tap(find.text('More').last);
      await settle(tester);
      await tester.tap(find.text('All subscriptions'));
      await settle(tester);
      expect(_selectedTab(tester), 3);
    });

    tracklyTest('tapping a tab from the detail screen leaves the item', (
      tester,
    ) async {
      await _openNetflix(tester);

      await tester.tap(_tab('Insights'));
      await settle(tester);
      expect(find.text('Mark as paid'), findsNothing);
      expect(_selectedTab(tester), 1);

      await tester.tap(_tab('Home'));
      await settle(tester);
      expect(find.text('Your recurring cost'), findsOneWidget);
      expect(_selectedTab(tester), 0);
    });

    tracklyTest('tapping Home from the detail screen returns to Home', (
      tester,
    ) async {
      await _openNetflix(tester);
      await tester.tap(_tab('Home'));
      await settle(tester);
      expect(find.text('Your recurring cost'), findsOneWidget);
      expect(find.text('Mark as paid'), findsNothing);
    });

    tracklyTest('back from a screen returns to the tab it came from', (
      tester,
    ) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.text('Your recurring cost'), findsOneWidget);
      expect(_selectedTab(tester), 0);
    });
  });

  group('the add and edit panels rise from the bar', () {
    final panel = find.byKey(const Key('add-panel'));

    tracklyTest('the + on the detail screen opens the add panel', (
      tester,
    ) async {
      await _openNetflix(tester);

      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await settle(tester);

      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('Add subscription')),
        findsOneWidget,
      );
      // It sits directly above the bar, which stays visible.
      expect(
        tester.getBottomLeft(panel).dy,
        lessThanOrEqualTo(tester.getTopLeft(_nav).dy + 0.5),
      );
      expect(_nav, findsOneWidget);
    });

    tracklyTest('Edit opens the filled-in panel above the bar', (tester) async {
      await _openNetflix(tester);

      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      expect(panel, findsOneWidget);
      expect(
        find.descendant(of: panel, matching: find.text('Edit subscription')),
        findsOneWidget,
      );
      expect(
        tester.getBottomLeft(panel).dy,
        lessThanOrEqualTo(tester.getTopLeft(_nav).dy + 0.5),
      );
      // The + shows as a cross while the panel is open.
      final rotation = tester.widget<RotationTransition>(
        find.ancestor(
          of: find.byIcon(Icons.add_rounded).last,
          matching: find.byType(RotationTransition),
        ),
      );
      expect(rotation.turns.value, 0.125);
    });

    tracklyTest('the + closes an open edit panel and a later add is blank', (
      tester,
    ) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      await tester.tap(find.byIcon(Icons.add_rounded).last); // the cross
      await settle(tester);
      expect(panel, findsNothing);

      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await settle(tester);
      final name = tester.widget<TextField>(
        find.descendant(
          of: panel,
          matching: find.widgetWithText(
            TextField,
            'Search a service or type a name',
          ),
        ),
      );
      expect(name.controller!.text, isEmpty);
    });

    tracklyTest('switching tabs closes an open edit panel', (tester) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      await tester.tap(_tab('Calendar'));
      await settle(tester);

      expect(panel, findsNothing);
      expect(_selectedTab(tester), 2);
    });

    tracklyTest('the system back closes the panel before leaving the screen', (
      tester,
    ) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(panel, findsNothing);
      expect(find.text('Mark as paid'), findsOneWidget); // still on the item

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Your recurring cost'), findsOneWidget);
    });

    tracklyTest('saving an edit shows the message above the bar', (
      tester,
    ) async {
      await _openNetflix(tester);
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      await tester.enterText(
        find.descendant(
          of: panel,
          matching: find.widgetWithText(TextField, 'Amount'),
        ),
        '20',
      );
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: panel,
          matching: find.widgetWithText(FilledButton, 'Save changes'),
        ),
      );
      await settle(tester);

      expect(find.text('Changes saved'), findsOneWidget);
      expect(
        tester.getBottomLeft(find.byType(SnackBar)).dy,
        lessThanOrEqualTo(tester.getTopLeft(_nav).dy + 0.5),
      );
    });
  });
}
