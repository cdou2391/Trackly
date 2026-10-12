import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_events.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1400);

class _RecordingAnalytics implements AnalyticsService {
  final events = <(String, Map<String, Object>?)>[];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name, parameters));
  }
}

Future<void> _openSearch(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Search'));
  await settle(tester);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('search-field')), text);
  await settle(tester);
}

void main() {
  final items = [
    testItem('Netflix', categoryId: 'entertainment'),
    testItem('Spotify', categoryId: 'entertainment', notes: 'Family plan'),
    testItem('Notion', categoryId: 'software'),
    testItem('Old gym', status: ItemStatus.cancelled),
  ];

  tracklyTest('the Home search icon opens search, Back returns', (
    tester,
  ) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);

    expect(find.byKey(const Key('search-field')), findsOneWidget);
    expect(find.text('Search by name, category or note.'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byKey(const Key('search-field')), findsNothing);
  });

  tracklyTest('the field is focused so you can type straight away', (
    tester,
  ) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);

    final field = tester.widget<TextField>(
      find.byKey(const Key('search-field')),
    );
    expect(field.autofocus, isTrue);
  });

  tracklyTest('says so when there is nothing to search', (tester) async {
    await pumpTrackly(tester, size: _tall);
    await _openSearch(tester);

    expect(
      find.text('Nothing to search yet. Add a subscription first.'),
      findsOneWidget,
    );
  });

  tracklyTest('shows matching items with their result count', (tester) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);
    await _type(tester, 'flix');

    expect(find.text('1 result'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsNothing);
    expect(find.text('Search by name, category or note.'), findsNothing);
  });

  tracklyTest('matches by category and by note', (tester) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);

    await _type(tester, 'entertainment');
    expect(find.text('2 results'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);

    await _type(tester, 'family');
    expect(find.text('1 result'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);
  });

  tracklyTest('finds cancelled items, marked as cancelled', (tester) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);
    await _type(tester, 'gym');

    expect(find.text('Old gym'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
  });

  tracklyTest('a query with no match says what was searched', (tester) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);
    await _type(tester, 'hulu');

    expect(find.text('No matches for “hulu”'), findsOneWidget);
    expect(find.textContaining('result'), findsNothing);
  });

  tracklyTest('Clear empties the field and returns to the prompt', (
    tester,
  ) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);
    expect(find.byTooltip('Clear search'), findsNothing);

    await _type(tester, 'flix');
    await tester.tap(find.byTooltip('Clear search'));
    await settle(tester);

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('search-field')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Search by name, category or note.'), findsOneWidget);
    expect(find.byTooltip('Clear search'), findsNothing);
  });

  tracklyTest('tapping a result opens the item, Back keeps the search', (
    tester,
  ) async {
    await pumpTrackly(tester, size: _tall, items: items);
    await _openSearch(tester);
    await _type(tester, 'notion');

    await tester.tap(find.text('Notion'));
    await settle(tester);
    expect(find.text('Mark as paid'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byKey(const Key('search-field')), findsOneWidget);
    expect(find.text('Notion'), findsOneWidget);
  });

  tracklyTest('logs opening and opening a result, never the query', (
    tester,
  ) async {
    final analytics = _RecordingAnalytics();
    await pumpTrackly(tester, size: _tall, items: items, analytics: analytics);
    await _openSearch(tester);
    await _type(tester, 'notion');
    await tester.tap(find.text('Notion'));
    await settle(tester);

    final search = [
      for (final e in analytics.events)
        if (e.$1.startsWith('search_')) e,
    ];
    expect(search.map((e) => e.$1), [
      AnalyticsEvents.searchOpened,
      AnalyticsEvents.searchResultOpened,
    ]);
    expect(search.every((e) => e.$2 == null), isTrue);
  });

  group('layout', () {
    for (final (size, scale) in [
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 1.6),
      (const Size(390, 844), 1.6),
    ]) {
      tracklyTest('no overflow at ${size.width}dp, ${scale}x text', (
        tester,
      ) async {
        await pumpTrackly(
          tester,
          size: size,
          textScale: scale,
          items: [
            testItem(
              'A very long subscription name that needs room',
              categoryId: 'entertainment',
            ),
            ...items,
          ],
        );
        await _openSearch(tester);
        await _type(tester, 'a');

        expect(tester.takeException(), isNull);
        expect(find.textContaining('result'), findsOneWidget);
      });
    }
  });
}
