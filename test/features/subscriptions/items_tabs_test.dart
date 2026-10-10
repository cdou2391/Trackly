import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/subscriptions/application/items_filter.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

const _size = Size(390, 1400);

Future<void> _openAllSubscriptions(
  WidgetTester tester, {
  Size size = _size,
  double textScale = 1.0,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await pumpTrackly(
    tester,
    size: size,
    textScale: textScale,
    themeMode: themeMode,
    items: [
      testItem('Netflix', due: DateTime(2026, 10, 15)),
      testItem('Spotify', due: DateTime(2026, 10, 18)),
      testItem(
        'Canva',
        due: DateTime(2026, 11, 5),
        trialEnd: DateTime(2026, 11, 5),
      ),
      testItem('Gym', status: ItemStatus.cancelled),
    ],
  );
  await tester.tap(find.text('More').last);
  await settle(tester);
  await tester.tap(find.text('All subscriptions'));
  await settle(tester);
}

TabController _controller(WidgetTester tester) =>
    tester.widget<TabBar>(find.byType(TabBar)).controller!;

Finder _tab(String label) => find.widgetWithText(Tab, label);

/// The names of the rows shown on the visible page.
List<String> _visible(WidgetTester tester, List<String> names) => [
  for (final name in names)
    if (find.text(name).hitTestable().evaluate().isNotEmpty) name,
];

void main() {
  group('tabs', () {
    tracklyTest('are real tabs: All, Active, Trial, Cancelled', (tester) async {
      await _openAllSubscriptions(tester);

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
      for (final label in ['All', 'Active', 'Trial', 'Cancelled']) {
        expect(_tab(label), findsOneWidget, reason: label);
      }
      // All is selected to begin with.
      expect(_controller(tester).index, ItemFilter.all.index);
    });

    tracklyTest('open on the filter from the Home card', (tester) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [
          testItem('Netflix', due: DateTime(2026, 10, 15)),
          testItem(
            'Canva',
            due: DateTime(2026, 11, 5),
            trialEnd: DateTime(2026, 11, 5),
          ),
        ],
      );
      await tester.tap(find.text('Trial').first);
      await settle(tester);

      expect(_controller(tester).index, ItemFilter.trial.index);
      expect(find.text('Canva'), findsOneWidget);
    });

    tracklyTest('each tab shows its own list', (tester) async {
      await _openAllSubscriptions(tester);
      const all = ['Netflix', 'Spotify', 'Canva', 'Gym'];

      expect(_visible(tester, all), ['Netflix', 'Spotify', 'Canva', 'Gym']);

      await tester.tap(_tab('Active'));
      await settle(tester);
      expect(_visible(tester, all), ['Netflix', 'Spotify']);

      await tester.tap(_tab('Trial'));
      await settle(tester);
      expect(_visible(tester, all), ['Canva']);

      await tester.tap(_tab('Cancelled'));
      await settle(tester);
      expect(_visible(tester, all), ['Gym']);

      await tester.tap(_tab('All'));
      await settle(tester);
      expect(_visible(tester, all), hasLength(4));
    });

    tracklyTest('an empty tab says so', (tester) async {
      await pumpTrackly(
        tester,
        size: _size,
        items: [testItem('Netflix', due: DateTime(2026, 10, 15))],
      );
      await tester.tap(find.text('More').last);
      await settle(tester);
      await tester.tap(find.text('All subscriptions'));
      await settle(tester);

      await tester.tap(_tab('Cancelled'));
      await settle(tester);
      expect(find.text('Nothing here yet.'), findsOneWidget);
    });

    tracklyTest('tapping a row still opens the item', (tester) async {
      await _openAllSubscriptions(tester);
      await tester.tap(_tab('Trial'));
      await settle(tester);
      await tester.tap(find.text('Canva'));
      await settle(tester);
      expect(find.text('Mark as paid'), findsOneWidget);
    });
  });

  group('transition', () {
    tracklyTest('tapping a tab slides over time, not in one jump', (
      tester,
    ) async {
      await _openAllSubscriptions(tester);
      final controller = _controller(tester);
      expect(controller.animation!.value, 0);

      await tester.tap(_tab('Trial'));
      await tester.pump(); // the animation starts on this frame
      // Part-way through: the animation is between the two tabs.
      await tester.pump(const Duration(milliseconds: 80));
      final partway = controller.animation!.value;
      expect(partway, greaterThan(0));
      expect(partway, lessThan(ItemFilter.trial.index.toDouble()));

      // Later it has moved further, in the same direction.
      await tester.pump(const Duration(milliseconds: 80));
      expect(controller.animation!.value, greaterThan(partway));

      await settle(tester);
      expect(controller.animation!.value, ItemFilter.trial.index.toDouble());
      expect(controller.index, ItemFilter.trial.index);
    });

    tracklyTest('both lists are on screen while sliding', (tester) async {
      await _openAllSubscriptions(tester);
      await tester.tap(_tab('Active'));
      await tester.pump(); // the animation starts on this frame
      await tester.pump(const Duration(milliseconds: 100));

      // Netflix is in both lists: the outgoing page and the incoming one are
      // both laid out at once while they slide past each other.
      expect(find.text('Netflix'), findsNWidgets(2));
      // Canva is only in the outgoing list, still partly visible.
      expect(find.text('Canva'), findsOneWidget);

      await settle(tester);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Canva'), findsNothing);
    });

    tracklyTest('the underline moves with the tabs', (tester) async {
      await _openAllSubscriptions(tester);
      double centerX(String label) => tester.getCenter(_tab(label)).dx;

      expect(centerX('All'), lessThan(centerX('Active')));
      expect(centerX('Active'), lessThan(centerX('Trial')));
      expect(centerX('Trial'), lessThan(centerX('Cancelled')));

      // Four equal slots fill the width: evenly spaced centers.
      final centers = [
        for (final l in ['All', 'Active', 'Trial', 'Cancelled']) centerX(l),
      ];
      final gaps = [
        for (var i = 1; i < centers.length; i++) centers[i] - centers[i - 1],
      ];
      for (final gap in gaps) {
        expect(gap, closeTo(gaps.first, 1));
      }
    });

    tracklyTest('swiping sideways moves to the next tab', (tester) async {
      await _openAllSubscriptions(tester);
      final controller = _controller(tester);

      await tester.drag(find.byType(TabBarView), const Offset(-320, 0));
      await settle(tester);
      expect(controller.index, ItemFilter.active.index);

      await tester.drag(find.byType(TabBarView), const Offset(-320, 0));
      await settle(tester);
      expect(controller.index, ItemFilter.trial.index);

      // And back the other way.
      await tester.drag(find.byType(TabBarView), const Offset(320, 0));
      await settle(tester);
      expect(controller.index, ItemFilter.active.index);
    });

    tracklyTest('cannot swipe past the first or last tab', (tester) async {
      await _openAllSubscriptions(tester);
      final controller = _controller(tester);

      await tester.drag(find.byType(TabBarView), const Offset(320, 0));
      await settle(tester);
      expect(controller.index, 0);

      await tester.tap(_tab('Cancelled'));
      await settle(tester);
      await tester.drag(find.byType(TabBarView), const Offset(-320, 0));
      await settle(tester);
      expect(controller.index, ItemFilter.cancelled.index);
    });

    tracklyTest('a half-finished swipe settles back', (tester) async {
      await _openAllSubscriptions(tester);
      final controller = _controller(tester);

      // Drag only a little, then let go: it returns to the same tab.
      await tester.drag(find.byType(TabBarView), const Offset(-40, 0));
      await settle(tester);
      expect(controller.index, 0);
      expect(controller.animation!.value, 0);
    });
  });

  group('look', () {
    tracklyTest(
      'the tab bar uses the accent underline and a hairline divider',
      (tester) async {
        await _openAllSubscriptions(tester);
        final bar = tester.widget<TabBar>(find.byType(TabBar));
        // Light theme: gold accent; selected label is the dark text color.
        final theme = Theme.of(tester.element(find.byType(TabBar)));
        expect(theme.tabBarTheme.indicatorColor, const Color(0xFFC99A3D));
        expect(theme.tabBarTheme.labelColor, theme.colorScheme.onSurface);
        expect(bar.isScrollable, isFalse);
      },
    );

    tracklyTest('tabs are tall and wide enough to tap', (tester) async {
      await _openAllSubscriptions(tester);
      final slot = tester.getSize(find.byType(TabBar)).width / 4;
      expect(slot, greaterThanOrEqualTo(48));
      for (final label in ['All', 'Active', 'Trial', 'Cancelled']) {
        expect(tester.getSize(_tab(label)).height, greaterThanOrEqualTo(48));
      }
    });

    tracklyTest('with large text the tabs scroll instead of squeezing', (
      tester,
    ) async {
      await _openAllSubscriptions(
        tester,
        size: const Size(360, 1400),
        textScale: 1.5,
      );
      expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);
      expect(tester.takeException(), isNull);

      // The last tab can still be reached.
      await tester.ensureVisible(_tab('Cancelled'));
      await tester.tap(_tab('Cancelled'));
      await settle(tester);
      expect(_controller(tester).index, ItemFilter.cancelled.index);
    });

    tracklyTest('works in the dark theme too', (tester) async {
      await _openAllSubscriptions(tester, themeMode: ThemeMode.dark);
      await tester.tap(_tab('Trial'));
      await settle(tester);
      expect(find.text('Canva'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
