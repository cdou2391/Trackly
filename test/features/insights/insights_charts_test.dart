import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/theme/app_theme.dart';
import 'package:trackly/features/insights/application/insights_summary.dart';
import 'package:trackly/features/insights/presentation/charts/category_donut.dart';
import 'package:trackly/l10n/app_localizations.dart';
import 'package:trackly/features/insights/presentation/charts/paid_weeks_chart.dart';
import 'package:trackly/features/payments/domain/payment.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1800);

/// A chart on its own, with the app's theme and strings.
Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    theme: AppTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: app!,
    ),
    home: Scaffold(body: child),
  );
}

Future<void> _openInsights(WidgetTester tester) async {
  await tester.tap(find.text('Insights').last);
  await settle(tester);
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  tracklyTest('Paid this month shows a bar chart with its legend', (
    tester,
  ) async {
    final db = await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 15, due: DateTime(2026, 10, 20)),
        testItem('Spotify', amount: 10, due: DateTime(2026, 11, 10)),
      ],
    );
    await tester.runAsync(
      () => db.paymentsDao.insertPayment(
        Payment(
          id: 'p1',
          recurringItemId: 'Spotify',
          amount: 10,
          currencyCode: 'USD',
          dueDate: DateTime(2026, 10, 5),
          paidDate: DateTime(2026, 10, 5),
          status: PaymentStatus.paid,
          createdAt: testNow,
        ),
      ),
    );
    await _openInsights(tester);

    expect(find.byType(PaidWeeksChart), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    // The weeks of October are labelled under the bars.
    for (final label in ['1–7', '8–14', '15–21', '22–28', '29–31']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bar chart reads out each week for a screen reader', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const PaidWeeksChart(
          currency: 'USD',
          locale: 'en',
          weeks: [
            WeekBucket(startDay: 1, endDay: 7, total: 10, paid: 5),
            WeekBucket(startDay: 8, endDay: 14, total: 20, paid: 0),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
        RegExp(
          r'1–7: \$5\.00 paid of \$10\.00\. 8–14: \$0\.00 paid of \$20\.00',
        ),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the bars are drawn once the chart has grown in', (tester) async {
    await tester.pumpWidget(
      _host(
        const PaidWeeksChart(
          currency: 'USD',
          locale: 'en',
          weeks: [WeekBucket(startDay: 1, endDay: 7, total: 10, paid: 5)],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a chart with nothing to show draws nothing', (tester) async {
    await tester.pumpWidget(
      _host(
        const PaidWeeksChart(
          currency: 'USD',
          locale: 'en',
          weeks: [WeekBucket(startDay: 1, endDay: 7, total: 0, paid: 0)],
        ),
      ),
    );
    expect(find.text('Planned'), findsNothing);
  });

  tracklyTest('By category shows a donut with the total in the middle', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 10, due: DateTime(2026, 10, 12)),
        testItem('Rent', amount: 90, due: DateTime(2026, 10, 20)),
      ],
    );
    await _openInsights(tester);

    expect(find.byType(CategoryDonut), findsOneWidget);
    expect(find.text('Per month'), findsWidgets);
    expect(find.text(r'$100.00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  tracklyTest('two currencies: both totals, one donut, a chip to switch', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 10, due: DateTime(2026, 10, 12)),
        testItem(
          'Internet',
          amount: 30000,
          currency: 'RWF',
          due: DateTime(2026, 10, 15),
        ),
      ],
    );
    await _openInsights(tester);

    expect(find.byType(CategoryDonut), findsOneWidget);
    // Both totals sit above the chips; neither is merged into the other.
    expect(find.text(r'$10.00'), findsWidgets);
    expect(find.textContaining('30,000'), findsWidgets);
    expect(find.byType(ChoiceChip), findsNWidgets(4));
    // The biggest total is shown first.
    final first = tester.widget<CategoryDonut>(find.byType(CategoryDonut));
    expect(first.total, contains('30,000'));

    await tester.tap(find.widgetWithText(ChoiceChip, 'USD').last);
    await settle(tester);
    final second = tester.widget<CategoryDonut>(find.byType(CategoryDonut));
    expect(second.total, r'$10.00');
    expect(find.byType(CategoryDonut), findsOneWidget);
  });

  tracklyTest('Paid this month: one bar chart, a chip per currency', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem('Netflix', amount: 10, due: DateTime(2026, 10, 12)),
        testItem(
          'Internet',
          amount: 30000,
          currency: 'RWF',
          due: DateTime(2026, 10, 15),
        ),
      ],
    );
    await _openInsights(tester);

    expect(find.byType(PaidWeeksChart), findsOneWidget);
    // The bigger month comes first.
    expect(
      tester.widget<PaidWeeksChart>(find.byType(PaidWeeksChart)).currency,
      'RWF',
    );

    // The first USD chip belongs to Paid this month (it is higher up).
    await tester.tap(find.widgetWithText(ChoiceChip, 'USD').first);
    await settle(tester);
    expect(find.byType(PaidWeeksChart), findsOneWidget);
    expect(
      tester.widget<PaidWeeksChart>(find.byType(PaidWeeksChart)).currency,
      'USD',
    );
  });

  tracklyTest('the charts draw at large text and a narrow screen', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: const Size(320, 1800),
      textScale: 1.6,
      items: [
        testItem('Netflix', amount: 10, due: DateTime(2026, 10, 12)),
        testItem('Rent', amount: 90, due: DateTime(2026, 10, 20)),
      ],
    );
    await _openInsights(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the donut tells a screen reader each category and its share', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const CategoryDonut(
          total: r'$35.00',
          semanticsLabel: r'Monthly cost by category, total $35.00. Entertainment $25.00, 71%',
          slices: [
            DonutSlice(color: Colors.red, value: 25, name: 'Entertainment'),
          ],
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Entertainment \$25\.00, 71%')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the donut is complete at once when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const CategoryDonut(
          total: r'$10.00',
          semanticsLabel: 'x',
          slices: [DonutSlice(color: Colors.red, value: 1)],
        ),
        reduceMotion: true,
      ),
    );
    await tester.pump();
    expect(find.text(r'$10.00'), findsWidgets);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the donut sweeps open over time', (tester) async {
    await tester.pumpWidget(
      _host(
        const CategoryDonut(
          total: r'$10.00',
          semanticsLabel: 'x',
          slices: [DonutSlice(color: Colors.red, value: 1)],
        ),
      ),
    );
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('the legend lists each category with its colour', (tester) async {
    await tester.pumpWidget(
      _host(
        const DonutLegend(
          slices: [
            DonutSlice(color: Colors.red, value: 3, name: 'Entertainment'),
            DonutSlice(color: Colors.blue, value: 1, name: 'Software'),
          ],
        ),
      ),
    );
    expect(find.text('Entertainment'), findsOneWidget);
    expect(find.text('Software'), findsOneWidget);
    final dots = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.color)
        .toList();
    expect(dots, containsAll([Colors.red, Colors.blue]));
  });

  tracklyTest('the legend sits beside the donut on a normal screen', (
    tester,
  ) async {
    await pumpTrackly(
      tester,
      size: _tall,
      items: [
        testItem(
          'Netflix',
          amount: 10,
          due: DateTime(2026, 10, 12),
          categoryId: 'entertainment',
        ),
        testItem(
          'Adobe',
          amount: 30,
          due: DateTime(2026, 10, 15),
          categoryId: 'software',
        ),
      ],
    );
    await _openInsights(tester);

    final donut = tester.getRect(find.byType(CategoryDonut));
    final legend = tester.getRect(find.byType(DonutLegend));
    expect(legend.left, greaterThanOrEqualTo(donut.right));
  });

  tracklyTest(
    'the legend drops below the donut on a narrow, large-text screen',
    (tester) async {
      await pumpTrackly(
        tester,
        size: const Size(320, 2300),
        textScale: 1.6,
        items: [
          testItem(
            'Netflix',
            amount: 10,
            due: DateTime(2026, 10, 12),
            categoryId: 'entertainment',
          ),
          testItem(
            'Adobe',
            amount: 30,
            due: DateTime(2026, 10, 15),
            categoryId: 'software',
          ),
        ],
      );
      await _openInsights(tester);

      final donut = tester.getRect(find.byType(CategoryDonut));
      final legend = tester.getRect(find.byType(DonutLegend));
      expect(legend.top, greaterThanOrEqualTo(donut.bottom));
      // Whole words: nothing is broken across lines.
      expect(find.text('Entertainment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('amounts on the bars', () {
    Widget chart(List<WeekBucket> weeks, {String currency = 'USD'}) => _host(
      SizedBox(
        width: 360,
        child: PaidWeeksChart(weeks: weeks, currency: currency, locale: 'en'),
      ),
    );

    testWidgets('a week still to pay shows its total above the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        chart(const [
          WeekBucket(startDay: 1, endDay: 7, total: 45, paid: 0),
          WeekBucket(startDay: 8, endDay: 14, total: 20, paid: 0),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$45'), findsOneWidget);
      expect(find.text(r'$20'), findsOneWidget);
    });

    testWidgets('a part-paid week shows its paid share inside the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        chart(const [WeekBucket(startDay: 1, endDay: 7, total: 100, paid: 60)]),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$100'), findsOneWidget); // above
      expect(find.text(r'$60'), findsOneWidget); // inside
    });

    testWidgets('a paid share too short for text goes above the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        chart(const [
          WeekBucket(startDay: 1, endDay: 7, total: 100, paid: 2),
          WeekBucket(startDay: 8, endDay: 14, total: 100, paid: 0),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$2'), findsOneWidget);
      expect(find.text(r'$100'), findsNWidgets(2));
    });

    testWidgets('a fully paid week shows one amount, not two', (tester) async {
      await tester.pumpWidget(
        chart(const [WeekBucket(startDay: 1, endDay: 7, total: 30, paid: 30)]),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$30'), findsOneWidget);
    });

    testWidgets('large amounts are shortened and the currency is named', (
      tester,
    ) async {
      await tester.pumpWidget(
        chart(const [
          WeekBucket(startDay: 1, endDay: 7, total: 22900, paid: 0),
        ], currency: 'RWF'),
      );
      await tester.pumpAndSettle();
      expect(find.text('22.9K'), findsOneWidget);
      expect(find.text('RWF'), findsOneWidget);
    });

    testWidgets('weeks with nothing in them show no amount', (tester) async {
      await tester.pumpWidget(
        chart(const [
          WeekBucket(startDay: 1, endDay: 7, total: 10, paid: 0),
          WeekBucket(startDay: 8, endDay: 14, total: 0, paid: 0),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$10'), findsOneWidget);
      expect(find.text(r'$0'), findsNothing);
    });
  });
}
