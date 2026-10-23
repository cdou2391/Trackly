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

  tracklyTest('each currency gets its own donut', (tester) async {
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

    expect(find.byType(CategoryDonut), findsNWidgets(2));
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
    expect(find.text(r'$10.00'), findsOneWidget);
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
}
