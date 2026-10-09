import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/app.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/features/home/application/home_providers.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

AppDatabase? _openDatabase;

/// Like `testWidgets`, but tears the app and database down inside the test.
///
/// Flutter checks for pending timers before `addTearDown` callbacks run, and
/// Drift schedules fake-async timers when streams are cancelled and when the
/// database closes, so cleanup must happen in the test body.
void tracklyTest(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    await body(tester);

    final db = _openDatabase;
    _openDatabase = null;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(seconds: 1));
    if (db != null) {
      await tester.runAsync(db.close);
      await tester.pump(const Duration(seconds: 1));
    }
  });
}

/// Fixed "today" for widget tests.
final testNow = DateTime(2026, 10, 9, 12);

RecurringItem testItem(
  String name, {
  double amount = 10,
  String currency = 'USD',
  DateTime? due,
  BillingFrequency frequency = BillingFrequency.monthly,
  DateTime? trialEnd,
  String? logoKey,
}) {
  return RecurringItem(
    id: name,
    name: name,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    startDate: DateTime(2026, 1, 1),
    nextDueDate: due ?? DateTime(2026, 10, 20),
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    logoKey: logoKey,
    createdAt: testNow,
    updatedAt: testNow,
  );
}

/// Pumps the whole app on a 390x844 phone with an in-memory database.
Future<AppDatabase> pumpTrackly(
  WidgetTester tester, {
  List<RecurringItem> items = const [],
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  await tester.runAsync(() async {
    for (final item in items) {
      await db.recurringItemsDao.insertItem(item);
    }
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        nowProvider.overrideWithValue(() => testNow),
      ],
      child: const TracklyApp(),
    ),
  );
  await settle(tester);

  _openDatabase = db;
  return db;
}

/// Lets Drift streams emit and animations finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}
