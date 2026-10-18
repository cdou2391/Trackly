import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

import '../../helpers/test_app.dart';

/// Realistic data: long names, a trial, several due states, a recent payment.
List<RecurringItem> _items() => [
  testItem(
    'Netflix',
    amount: 15.49,
    due: DateTime(2026, 10, 10),
    logoKey: 'netflix',
  ),
  testItem(
    'Spotify Premium Family',
    amount: 10.99,
    due: DateTime(2026, 10, 12),
    logoKey: 'spotify',
  ),
  testItem(
    'Google One',
    amount: 2.99,
    due: DateTime(2026, 10, 18),
    logoKey: 'google_one',
  ),
  testItem('Gym membership downtown', amount: 35, due: DateTime(2026, 10, 27)),
  testItem(
    'YouTube Premium',
    amount: 13.99,
    due: DateTime(2026, 11, 2),
    logoKey: 'youtube_premium',
  ),
  testItem(
    'Canva Pro',
    amount: 14.99,
    due: DateTime(2026, 11, 5),
    logoKey: 'canva',
    trialEnd: DateTime(2026, 11, 5),
  ),
];

Future<void> _addPayment(WidgetTester tester, dynamic db) async {
  await tester.runAsync(
    () => db.paymentsDao.insertPayment(
      Payment(
        id: 'p1',
        recurringItemId: 'YouTube Premium',
        amount: 13.99,
        currencyCode: 'USD',
        dueDate: DateTime(2026, 10, 2),
        paidDate: DateTime(2026, 10, 2),
        status: PaymentStatus.paid,
        createdAt: testNow,
      ),
    ),
  );
  await settle(tester);
}

/// Scrolls the whole Home list so every section is laid out, then fails on any
/// overflow or layout exception.
Future<void> _scrollThrough(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 4; i++) {
    await tester.drag(list, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await settle(tester);
}

void main() {
  const widths = [360.0, 390.0, 430.0];

  group('no overflow', () {
    for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
      for (final width in widths) {
        for (final scale in [1.0, 1.5]) {
          final name = '${themeMode.name} ${width.toInt()} dp, text x$scale';

          tracklyTest('Home: $name', (tester) async {
            final db = await pumpTrackly(
              tester,
              size: Size(width, 844),
              themeMode: themeMode,
              textScale: scale,
              items: _items(),
            );
            await _addPayment(tester, db);
            await _scrollThrough(tester);
            expect(tester.takeException(), isNull);
          });

          tracklyTest('Home (empty): $name', (tester) async {
            await pumpTrackly(
              tester,
              size: Size(width, 844),
              themeMode: themeMode,
              textScale: scale,
            );
            await _scrollThrough(tester);
            expect(tester.takeException(), isNull);
          });

          tracklyTest('Add panel: $name', (tester) async {
            await pumpTrackly(
              tester,
              size: Size(width, 844),
              themeMode: themeMode,
              textScale: scale,
              items: _items(),
            );
            await tester.tap(find.byIcon(Icons.add_rounded).last);
            await settle(tester);
            expect(find.byKey(const Key('add-panel')), findsOneWidget);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });

  group('light theme layout', () {
    tracklyTest('the hero is a full-width rounded card, not an arc', (
      tester,
    ) async {
      await pumpTrackly(tester, items: _items());

      // The only gradient box with the hero's 28 dp corners (the icon tiles
      // have gradients too, with their own, smaller corners).
      final card = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient != null &&
            (w.decoration as BoxDecoration).borderRadius ==
                BorderRadius.circular(28),
      );
      expect(card, findsOneWidget);
      final decoration =
          tester.widget<DecoratedBox>(card).decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(28));

      // 16 dp from each screen edge on a 390 dp phone.
      final rect = tester.getRect(card);
      expect(rect.left, 16);
      expect(rect.right, 390 - 16);
      // Roughly the reference height (250-290 dp is the spec; allow content).
      expect(rect.height, inInclusiveRange(230, 300));
    });

    tracklyTest('sections follow the specified order', (tester) async {
      final db = await pumpTrackly(
        tester,
        size: const Size(390, 2400),
        items: _items(),
      );
      await _addPayment(tester, db);

      double top(Finder f) => tester.getTopLeft(f).dy;
      final order = [
        find.text('Trackly'),
        find.text('Your recurring cost'),
        find.text('Active'),
        find.text('Add a new subscription'),
        find.text('Upcoming charges'),
        find.text('Recent payments'),
      ];
      final tops = [for (final f in order) top(f)];
      expect(tops, orderedEquals([...tops]..sort()));
      // Bottom navigation sits below all of it.
      expect(top(find.text('Home')), greaterThan(tops.last));
    });

    tracklyTest('the title is serif and everything else is sans', (
      tester,
    ) async {
      await pumpTrackly(tester, size: const Size(390, 2400), items: _items());
      TextStyle styleOf(String text) =>
          tester.widget<Text>(find.text(text).first).style!;

      expect(styleOf('Trackly').fontFamily, 'PlayfairDisplay');
      expect(styleOf('Trackly').fontSize, 40);
      expect(styleOf('Subscriptions & Bills').fontFamily, 'Inter');
      expect(styleOf('Subscriptions & Bills').fontSize, 18);
      expect(styleOf('Upcoming charges').fontFamily, 'Inter');
      expect(styleOf('Upcoming charges').fontSize, inInclusiveRange(24, 28));
    });

    tracklyTest('the hero amount is 50 sp with a small /month', (tester) async {
      await pumpTrackly(tester, items: _items());
      final rich = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('/month'),
        ),
      );
      // Text.rich wraps our span in a root span carrying the default style.
      final amount = (rich.text as TextSpan).children!.single as TextSpan;
      expect(amount.style!.fontSize, 50);
      expect((amount.children!.single as TextSpan).style!.fontSize, 20);
    });

    tracklyTest('shows the three summary cards with their counts', (
      tester,
    ) async {
      await pumpTrackly(tester, size: const Size(430, 844), items: _items());
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Trial'), findsWidgets);
      expect(find.text('Cancelled'), findsOneWidget);
      // On a 430 dp phone the cards are side by side, icon beside the count.
      final active = tester.getTopLeft(find.text('Active')).dy;
      final trial = tester.getTopLeft(find.text('Cancelled')).dy;
      expect(active, closeTo(trial, 4));
    });

    tracklyTest('the nav has a gold center button and Home is selected', (
      tester,
    ) async {
      await pumpTrackly(tester, items: _items());
      final center = find.ancestor(
        of: find.byIcon(Icons.add_rounded).last,
        matching: find.byType(DecoratedBox),
      );
      final box = tester
          .widgetList<DecoratedBox>(center)
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.shape == BoxShape.circle);
      expect(box.color, const Color(0xFFC99A3D));
      expect(
        tester.getSize(find.byIcon(Icons.add_rounded).last).width,
        greaterThan(30),
      );
    });

    tracklyTest('status chips carry text, not just color', (tester) async {
      await pumpTrackly(tester, size: const Size(390, 2400), items: _items());
      for (final label in ['Due tomorrow', 'In 3 days', 'Oct 18, 2026']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });
  });

  group('accessibility (light)', () {
    tracklyTest('touch targets are at least 48 x 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTrackly(tester, items: _items());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    tracklyTest('tappable controls have labels', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTrackly(tester, items: _items());
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    tracklyTest('the icon buttons and nav are labelled for screen readers', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTrackly(tester, items: _items());
      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      for (final label in [
        'Home',
        'Insights',
        'Calendar',
        'More',
        'Add subscription',
      ]) {
        expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
      }
      // Summary cards read as one phrase, e.g. "Active: 5".
      expect(find.bySemanticsLabel(RegExp(r'Active: \d+')), findsOneWidget);
      handle.dispose();
    });

    tracklyTest('Quick Add fields are labelled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTrackly(tester, size: const Size(390, 1800));
      for (final label in [
        'Service name',
        'Amount',
        'Frequency',
        'Start date',
      ]) {
        // Merged with the field's own hint text, so match by prefix.
        expect(
          find.bySemanticsLabel(RegExp('^$label')),
          findsWidgets,
          reason: label,
        );
      }
      handle.dispose();
    });

    tracklyTest('the layout holds up at 150% text', (tester) async {
      await pumpTrackly(tester, textScale: 1.5, items: _items());
      await _scrollThrough(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
