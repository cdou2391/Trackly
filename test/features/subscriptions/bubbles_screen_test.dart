import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/home/widgets/subscription_row.dart';
import 'package:trackly/features/settings/application/settings_store.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/presentation/subscription_bubbles.dart';

import '../../helpers/test_app.dart';

final _items = [
  testItem('Netflix', amount: 15, due: DateTime(2026, 10, 15)),
  testItem('Spotify', amount: 10, due: DateTime(2026, 10, 18)),
  testItem(
    'Canva',
    amount: 12,
    due: DateTime(2026, 11, 5),
    trialEnd: DateTime(2026, 11, 5),
  ),
  testItem('Gym', amount: 35, status: ItemStatus.cancelled),
];

/// Bubbles that stand still, so tests can settle. Anyone who asks their phone
/// to reduce motion gets exactly this.
void _reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

Future<void> _openAll(WidgetTester tester) async {
  await tester.tap(find.text('More').last);
  await settle(tester);
  await tester.tap(find.text('All subscriptions'));
  await settle(tester);
}

void main() {
  tracklyTest('opens as bubbles by default', (tester) async {
    _reduceMotion(tester);
    await pumpTrackly(tester, items: _items, itemsAsBubbles: null);
    await _openAll(tester);

    expect(find.byType(SubscriptionBubbles), findsOneWidget);
    expect(find.byType(SubscriptionRow), findsNothing);
    for (final name in ['Netflix', 'Spotify', 'Canva', 'Gym']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });

  tracklyTest('tapping a bubble opens that subscription', (tester) async {
    _reduceMotion(tester);
    await pumpTrackly(tester, items: _items, itemsAsBubbles: true);
    await _openAll(tester);

    await tester.tap(find.text('Spotify'));
    await settle(tester);

    expect(find.text('Mark as paid'), findsOneWidget); // the item screen
  });

  tracklyTest('the switch toggles between bubbles and the list', (
    tester,
  ) async {
    _reduceMotion(tester);
    final store = InMemorySettingsStore();
    await pumpTrackly(
      tester,
      items: _items,
      settings: store,
      itemsAsBubbles: true,
    );
    await _openAll(tester);
    expect(find.byType(SubscriptionBubbles), findsOneWidget);

    await tester.tap(find.byTooltip('Show as list'));
    await settle(tester);

    expect(find.byType(SubscriptionBubbles), findsNothing);
    expect(find.byType(SubscriptionRow), findsNWidgets(_items.length));
    expect(store.itemsAsBubbles, isFalse);

    await tester.tap(find.byTooltip('Show as bubbles'));
    await settle(tester);

    expect(find.byType(SubscriptionBubbles), findsOneWidget);
    expect(store.itemsAsBubbles, isTrue);
  });

  tracklyTest('remembers the choice for next time', (tester) async {
    _reduceMotion(tester);
    final store = InMemorySettingsStore();
    await store.setItemsAsBubbles(false);
    await pumpTrackly(
      tester,
      items: _items,
      settings: store,
      itemsAsBubbles: null,
    );
    await _openAll(tester);

    expect(find.byType(SubscriptionRow), findsNWidgets(_items.length));
    expect(find.byType(SubscriptionBubbles), findsNothing);
  });

  tracklyTest('the tabs still filter the bubbles', (tester) async {
    _reduceMotion(tester);
    await pumpTrackly(tester, items: _items, itemsAsBubbles: true);
    await _openAll(tester);

    await tester.tap(find.widgetWithText(Tab, 'Cancelled'));
    await settle(tester);

    expect(find.text('Gym').hitTestable(), findsOneWidget);
    expect(find.text('Netflix').hitTestable(), findsNothing);
  });

  tracklyTest('an empty tab says so', (tester) async {
    _reduceMotion(tester);
    await pumpTrackly(
      tester,
      items: [testItem('Netflix')],
      itemsAsBubbles: true,
    );
    await _openAll(tester);

    await tester.tap(find.widgetWithText(Tab, 'Trial'));
    await settle(tester);

    expect(find.text('Nothing here yet.'), findsOneWidget);
  });

  tracklyTest('a screen reader hears the name, cost and status', (
    tester,
  ) async {
    _reduceMotion(tester);
    await pumpTrackly(tester, items: _items, itemsAsBubbles: true);
    await _openAll(tester);

    expect(
      find.bySemanticsLabel(RegExp(r'^Netflix, \$15\.00, ')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'^Gym, \$35\.00, .*Cancelled')),
      findsOneWidget,
    );
  });

  tracklyTest('the bubbles drift when motion is allowed', (tester) async {
    await pumpTrackly(tester, items: _items, itemsAsBubbles: true);
    // Bounded pumps: the drift never "settles", by design.
    await tester.tap(find.text('More').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('All subscriptions'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final before = tester.getCenter(find.text('Netflix'));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final after = tester.getCenter(find.text('Netflix'));

    expect((after - before).distance, greaterThan(5));
  });

  tracklyTest('a bubble that has drifted away still takes the tap', (
    tester,
  ) async {
    await pumpTrackly(tester, items: _items, itemsAsBubbles: true);
    await tester.tap(find.text('More').last);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('All subscriptions'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final start = tester.getCenter(find.text('Spotify'));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Six seconds on, it is somewhere else.
    expect(tester.getCenter(find.text('Spotify')), isNot(start));

    await tester.tap(find.text('Spotify'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Mark as paid'), findsOneWidget);
  });

  tracklyTest('they stand still when the phone asks to reduce motion', (
    tester,
  ) async {
    _reduceMotion(tester);
    await pumpTrackly(tester, items: _items, itemsAsBubbles: true);
    await _openAll(tester);

    final before = tester.getCenter(find.text('Netflix'));
    await tester.pump(const Duration(seconds: 5));
    final after = tester.getCenter(find.text('Netflix'));

    expect(after, before);
  });

  tracklyTest('many items scroll instead of shrinking', (tester) async {
    _reduceMotion(tester);
    await pumpTrackly(
      tester,
      items: [
        for (var i = 0; i < 60; i++) testItem('Service $i', amount: 5.0 + i),
      ],
      itemsAsBubbles: true,
    );
    await _openAll(tester);

    expect(find.byType(SingleChildScrollView), findsWidgets);
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SubscriptionBubbles),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scroll.position.maxScrollExtent, greaterThan(0));
  });

  tracklyTest('fits a narrow screen with large text', (tester) async {
    _reduceMotion(tester);
    await pumpTrackly(
      tester,
      size: const Size(320, 640),
      textScale: 2.0,
      items: _items,
      itemsAsBubbles: true,
    );
    await _openAll(tester);

    expect(find.byType(SubscriptionBubbles), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
