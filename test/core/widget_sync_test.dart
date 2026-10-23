import 'dart:ui';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/core/widget/home_widget_gateway.dart';
import 'package:trackly/core/widget/next_payment.dart';
import 'package:trackly/core/widget/widget_sync.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

import '../helpers/test_app.dart' show testItem;

class _FakeGateway implements HomeWidgetGateway {
  Map<String, Object?> data = {};
  int refreshes = 0;

  @override
  Future<void> save(Map<String, Object?> d) async => data = d;

  @override
  Future<void> refresh() async => refreshes++;
}

RecurringItem _withStatus(RecurringItem i, ItemStatus status) => RecurringItem(
  id: i.id,
  name: i.name,
  type: i.type,
  amount: i.amount,
  currencyCode: i.currencyCode,
  frequency: i.frequency,
  startDate: i.startDate,
  nextDueDate: i.nextDueDate,
  status: status,
  createdAt: i.createdAt,
  updatedAt: i.updatedAt,
);

final _syncProvider = Provider(
  (ref) => WidgetSync(ref, locale: () => const Locale('en', 'US')),
);

void main() {
  group('nextPayment', () {
    test('is the soonest due date', () {
      final next = nextPayment([
        testItem('B', due: DateTime(2026, 10, 25)),
        testItem('A', due: DateTime(2026, 10, 22)),
        testItem('C', due: DateTime(2026, 11, 1)),
      ]);
      expect(next?.name, 'A');
    });

    test('an overdue item comes first', () {
      final next = nextPayment([
        testItem('Soon', due: DateTime(2026, 10, 10)),
        testItem('Late', due: DateTime(2026, 10, 1)),
      ]);
      expect(next?.name, 'Late');
    });

    test('ties are broken by name', () {
      final next = nextPayment([
        testItem('Zed', due: DateTime(2026, 10, 20)),
        testItem('abc', due: DateTime(2026, 10, 20)),
      ]);
      expect(next?.name, 'abc');
    });

    test('skips paused and cancelled items', () {
      final next = nextPayment([
        _withStatus(
          testItem('P', due: DateTime(2026, 10, 10)),
          ItemStatus.paused,
        ),
        _withStatus(
          testItem('C', due: DateTime(2026, 10, 11)),
          ItemStatus.cancelled,
        ),
        testItem('Active', due: DateTime(2026, 12, 1)),
      ]);
      expect(next?.name, 'Active');
    });

    test('is null when nothing is active or there are no items', () {
      expect(nextPayment(const []), isNull);
      expect(
        nextPayment([_withStatus(testItem('P'), ItemStatus.paused)]),
        isNull,
      );
    });
  });

  group('WidgetSync', () {
    late AppDatabase db;
    late _FakeGateway gateway;
    late ProviderContainer container;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      gateway = _FakeGateway();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          homeWidgetGatewayProvider.overrideWithValue(gateway),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('writes the next payment and redraws', () async {
      await db.recurringItemsDao.insertItem(
        testItem('Netflix', amount: 15.49, due: DateTime(2026, 10, 25)),
      );
      await db.recurringItemsDao.insertItem(
        testItem('Spotify', amount: 9.99, due: DateTime(2026, 11, 2)),
      );
      await container.read(_syncProvider).update();

      expect(gateway.data['widget_name'], 'Netflix');
      expect(gateway.data['widget_amount'], r'$15.49');
      expect(gateway.data['widget_due'], '2026-10-25');
      expect(gateway.data['widget_due_label'], 'Oct 25, 2026');
      expect(gateway.refreshes, 1);
    });

    test('clears the widget when there is nothing to show', () async {
      await container.read(_syncProvider).update();
      expect(gateway.data['widget_name'], isNull);
      expect(gateway.data['widget_due'], isNull);
      expect(gateway.refreshes, 1);
    });

    test('follows changes in the data', () async {
      await db.recurringItemsDao.insertItem(
        testItem('Netflix', due: DateTime(2026, 10, 25)),
      );
      final sync = container.read(_syncProvider);
      await sync.update();
      expect(gateway.data['widget_name'], 'Netflix');

      await db.recurringItemsDao.insertItem(
        testItem('Earlier', due: DateTime(2026, 10, 12)),
      );
      await sync.update();
      expect(gateway.data['widget_name'], 'Earlier');
    });
  });
}
