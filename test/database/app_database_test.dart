import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/core/database/converters.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _stamp = DateTime.utc(2026, 10, 9, 12);

RecurringItem item(
  String id, {
  String name = 'Netflix',
  double amount = 15.49,
  DateTime? nextDueDate,
  ItemStatus status = ItemStatus.active,
  bool isTrial = false,
  DateTime? trialEndDate,
  String? categoryId,
  String? logoKey,
  int interval = 1,
}) {
  return RecurringItem(
    id: id,
    name: name,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: 'USD',
    frequency: BillingFrequency.monthly,
    interval: interval,
    startDate: DateTime(2026, 1, 15),
    nextDueDate: nextDueDate ?? DateTime(2026, 10, 15),
    status: status,
    isTrial: isTrial,
    trialEndDate: trialEndDate,
    categoryId: categoryId,
    logoKey: logoKey,
    createdAt: _stamp,
    updatedAt: _stamp,
  );
}

Payment payment(
  String id,
  String itemId, {
  required DateTime dueDate,
  DateTime? paidDate,
  PaymentStatus status = PaymentStatus.paid,
  DateTime? createdAt,
}) {
  return Payment(
    id: id,
    recurringItemId: itemId,
    amount: 15.49,
    currencyCode: 'USD',
    dueDate: dueDate,
    paidDate: paidDate,
    status: status,
    createdAt: createdAt ?? _stamp,
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('date converter', () {
    test('formats and parses YYYY-MM-DD', () {
      const converter = DateOnlyConverter();
      expect(converter.toSql(DateTime(2026, 3, 5)), '2026-03-05');
      expect(converter.fromSql('2026-03-05'), DateTime(2026, 3, 5));
    });

    test('ignores time of day when writing', () {
      expect(
        const DateOnlyConverter().toSql(DateTime(2026, 12, 31, 23, 59)),
        '2026-12-31',
      );
    });

    test('rejects malformed text', () {
      expect(
        () => const DateOnlyConverter().fromSql('15/10/2026'),
        throwsFormatException,
      );
    });
  });

  group('seeding', () {
    test('creates the 11 system categories in order', () async {
      final categories = await db.categoriesDao.watchAll().first;
      expect(categories, hasLength(11));
      expect(categories.first.id, 'entertainment');
      expect(categories.last.id, 'other');
      expect(categories.every((c) => c.isSystem), isTrue);
      expect([
        for (final c in categories) c.sortOrder,
      ], List.generate(11, (i) => i));
    });
  });

  group('recurring items', () {
    test('round-trips every field', () async {
      final original = RecurringItem(
        id: 'a',
        name: 'Canva Pro',
        type: RecurringItemType.bill,
        amount: 14.99,
        currencyCode: 'EUR',
        frequency: BillingFrequency.quarterly,
        interval: 2,
        startDate: DateTime(2026, 1, 31),
        nextDueDate: DateTime(2026, 11, 30),
        status: ItemStatus.paused,
        isTrial: true,
        trialEndDate: DateTime(2026, 11, 15),
        remindersEnabled: false,
        reminderDaysBefore: 7,
        categoryId: 'software',
        notes: 'Annual plan',
        logoKey: 'canva',
        createdAt: _stamp,
        updatedAt: _stamp,
      );
      await db.recurringItemsDao.insertItem(original);

      final loaded = await db.recurringItemsDao.getById('a');
      expect(loaded, isNotNull);
      expect(loaded!.name, 'Canva Pro');
      expect(loaded.type, RecurringItemType.bill);
      expect(loaded.amount, 14.99);
      expect(loaded.currencyCode, 'EUR');
      expect(loaded.frequency, BillingFrequency.quarterly);
      expect(loaded.interval, 2);
      expect(loaded.startDate, DateTime(2026, 1, 31));
      expect(loaded.nextDueDate, DateTime(2026, 11, 30));
      expect(loaded.status, ItemStatus.paused);
      expect(loaded.isTrial, isTrue);
      expect(loaded.trialEndDate, DateTime(2026, 11, 15));
      expect(loaded.remindersEnabled, isFalse);
      expect(loaded.reminderDaysBefore, 7);
      expect(loaded.categoryId, 'software');
      expect(loaded.notes, 'Annual plan');
      expect(loaded.logoKey, 'canva');
      expect(loaded.createdAt.toUtc(), _stamp);
    });

    test('stores calendar dates as plain text', () async {
      await db.recurringItemsDao.insertItem(item('a'));
      final row = await db
          .customSelect('SELECT start_date, next_due_date FROM recurring_items')
          .getSingle();
      expect(row.read<String>('start_date'), '2026-01-15');
      expect(row.read<String>('next_due_date'), '2026-10-15');
    });

    test('nullable fields stay null', () async {
      await db.recurringItemsDao.insertItem(item('a'));
      final loaded = (await db.recurringItemsDao.getById('a'))!;
      expect(loaded.trialEndDate, isNull);
      expect(loaded.categoryId, isNull);
      expect(loaded.notes, isNull);
      expect(loaded.logoKey, isNull);
    });

    test('update replaces the row', () async {
      await db.recurringItemsDao.insertItem(item('a'));
      final changed = await db.recurringItemsDao.updateItem(
        item('a', nextDueDate: DateTime(2026, 11, 15)),
      );
      expect(changed, isTrue);
      final loaded = (await db.recurringItemsDao.getById('a'))!;
      expect(loaded.nextDueDate, DateTime(2026, 11, 15));
    });

    test('delete removes the row', () async {
      await db.recurringItemsDao.insertItem(item('a'));
      expect(await db.recurringItemsDao.deleteItem('a'), 1);
      expect(await db.recurringItemsDao.getById('a'), isNull);
    });

    test('rejects a duplicate id', () async {
      await db.recurringItemsDao.insertItem(item('a'));
      expect(db.recurringItemsDao.insertItem(item('a')), throwsA(anything));
    });

    test('rejects an unknown category', () async {
      expect(
        db.recurringItemsDao.insertItem(item('a', categoryId: 'nope')),
        throwsA(anything),
      );
    });

    test('database rejects a negative amount', () async {
      expect(
        db.customStatement(
          "INSERT INTO recurring_items (id, name, type, amount, currency_code, "
          "frequency, interval, start_date, next_due_date, status, created_at, "
          "updated_at) VALUES ('x', 'x', 'bill', -1, 'USD', 'monthly', 1, "
          "'2026-01-01', '2026-02-01', 'active', 0, 0)",
        ),
        throwsA(anything),
      );
    });

    test('database rejects an interval below 1', () async {
      expect(
        db.customStatement(
          "INSERT INTO recurring_items (id, name, type, amount, currency_code, "
          "frequency, interval, start_date, next_due_date, status, created_at, "
          "updated_at) VALUES ('x', 'x', 'bill', 1, 'USD', 'monthly', 0, "
          "'2026-01-01', '2026-02-01', 'active', 0, 0)",
        ),
        throwsA(anything),
      );
    });

    test(
      'deleting a category clears it on items instead of deleting them',
      () async {
        await db.recurringItemsDao.insertItem(
          item('a', categoryId: 'entertainment'),
        );
        await (db.delete(
          db.categories,
        )..where((t) => t.id.equals('entertainment'))).go();
        final loaded = await db.recurringItemsDao.getById('a');
        expect(loaded, isNotNull);
        expect(loaded!.categoryId, isNull);
      },
    );
  });

  group('upcoming query', () {
    test('returns active items due by the cutoff, soonest first', () async {
      final dao = db.recurringItemsDao;
      await dao.insertItem(
        item('late', name: 'Late', nextDueDate: DateTime(2026, 11, 5)),
      );
      await dao.insertItem(
        item('soon', name: 'Soon', nextDueDate: DateTime(2026, 10, 10)),
      );
      await dao.insertItem(
        item('mid', name: 'Mid', nextDueDate: DateTime(2026, 10, 20)),
      );
      await dao.insertItem(
        item('beyond', name: 'Beyond', nextDueDate: DateTime(2026, 12, 1)),
      );

      final upcoming = await dao
          .watchUpcoming(until: DateTime(2026, 11, 8))
          .first;
      expect([for (final i in upcoming) i.id], ['soon', 'mid', 'late']);
    });

    test('includes an item due exactly on the cutoff day', () async {
      await db.recurringItemsDao.insertItem(
        item('a', nextDueDate: DateTime(2026, 11, 8)),
      );
      final upcoming = await db.recurringItemsDao
          .watchUpcoming(until: DateTime(2026, 11, 8, 18))
          .first;
      expect(upcoming, hasLength(1));
    });

    test('excludes paused and cancelled items', () async {
      final dao = db.recurringItemsDao;
      await dao.insertItem(item('active'));
      await dao.insertItem(item('paused', status: ItemStatus.paused));
      await dao.insertItem(item('cancelled', status: ItemStatus.cancelled));
      final upcoming = await dao
          .watchUpcoming(until: DateTime(2026, 12, 31))
          .first;
      expect([for (final i in upcoming) i.id], ['active']);
    });

    test('respects the limit', () async {
      for (var i = 0; i < 8; i++) {
        await db.recurringItemsDao.insertItem(
          item('i$i', nextDueDate: DateTime(2026, 10, 10 + i)),
        );
      }
      final upcoming = await db.recurringItemsDao
          .watchUpcoming(until: DateTime(2026, 12, 31), limit: 5)
          .first;
      expect(upcoming, hasLength(5));
      expect(upcoming.first.id, 'i0');
    });

    test('sorts correctly across a year boundary', () async {
      final dao = db.recurringItemsDao;
      await dao.insertItem(item('jan', nextDueDate: DateTime(2027, 1, 2)));
      await dao.insertItem(item('dec', nextDueDate: DateTime(2026, 12, 30)));
      final upcoming = await dao
          .watchUpcoming(until: DateTime(2027, 1, 31))
          .first;
      expect([for (final i in upcoming) i.id], ['dec', 'jan']);
    });

    test('emits again when an item is added', () async {
      final stream = db.recurringItemsDao
          .watchUpcoming(until: DateTime(2026, 12, 31))
          .map((items) => items.length);
      final emissions = expectLater(stream, emitsInOrder([0, 1]));
      await Future<void>.delayed(Duration.zero);
      await db.recurringItemsDao.insertItem(item('a'));
      await emissions;
    });
  });

  test('getActive returns only active items', () async {
    final dao = db.recurringItemsDao;
    await dao.insertItem(item('a'));
    await dao.insertItem(item('b', status: ItemStatus.paused));
    await dao.insertItem(item('c', status: ItemStatus.cancelled));
    expect([for (final i in await dao.getActive()) i.id], ['a']);
  });

  group('payments', () {
    setUp(() async {
      await db.recurringItemsDao.insertItem(item('a'));
      await db.recurringItemsDao.insertItem(item('b', name: 'Spotify'));
    });

    test('round-trips a paid payment', () async {
      await db.paymentsDao.insertPayment(
        payment(
          'p1',
          'a',
          dueDate: DateTime(2026, 10, 15),
          paidDate: DateTime(2026, 10, 18),
        ),
      );
      final loaded = (await db.paymentsDao.watchForItem('a').first).single;
      expect(loaded.dueDate, DateTime(2026, 10, 15));
      expect(loaded.paidDate, DateTime(2026, 10, 18));
      expect(loaded.status, PaymentStatus.paid);
      expect(loaded.amount, 15.49);
    });

    test(
      'recent payments are newest paid first and skip skipped ones',
      () async {
        final dao = db.paymentsDao;
        await dao.insertPayment(
          payment(
            'old',
            'a',
            dueDate: DateTime(2026, 8, 15),
            paidDate: DateTime(2026, 8, 15),
          ),
        );
        await dao.insertPayment(
          payment(
            'new',
            'b',
            dueDate: DateTime(2026, 10, 2),
            paidDate: DateTime(2026, 10, 2),
          ),
        );
        await dao.insertPayment(
          payment(
            'skipped',
            'a',
            dueDate: DateTime(2026, 10, 15),
            status: PaymentStatus.skipped,
          ),
        );

        final recent = await dao.watchRecentPaid().first;
        expect([for (final p in recent) p.id], ['new', 'old']);
      },
    );

    test('recent payments respect the limit', () async {
      for (var i = 1; i <= 7; i++) {
        await db.paymentsDao.insertPayment(
          payment(
            'p$i',
            'a',
            dueDate: DateTime(2026, 1, i),
            paidDate: DateTime(2026, 1, i),
          ),
        );
      }
      final recent = await db.paymentsDao.watchRecentPaid(limit: 3).first;
      expect([for (final p in recent) p.id], ['p7', 'p6', 'p5']);
    });

    test(
      'item history is newest due date first and scoped to the item',
      () async {
        final dao = db.paymentsDao;
        await dao.insertPayment(
          payment(
            'p1',
            'a',
            dueDate: DateTime(2026, 8, 15),
            paidDate: DateTime(2026, 8, 15),
          ),
        );
        await dao.insertPayment(
          payment(
            'p2',
            'a',
            dueDate: DateTime(2026, 9, 15),
            paidDate: DateTime(2026, 9, 15),
          ),
        );
        await dao.insertPayment(
          payment(
            'other',
            'b',
            dueDate: DateTime(2026, 9, 1),
            paidDate: DateTime(2026, 9, 1),
          ),
        );

        final history = await dao.watchForItem('a').first;
        expect([for (final p in history) p.id], ['p2', 'p1']);
      },
    );

    test('deleting an item deletes its payment history', () async {
      await db.paymentsDao.insertPayment(
        payment(
          'p1',
          'a',
          dueDate: DateTime(2026, 8, 15),
          paidDate: DateTime(2026, 8, 15),
        ),
      );
      await db.paymentsDao.insertPayment(
        payment(
          'p2',
          'b',
          dueDate: DateTime(2026, 8, 15),
          paidDate: DateTime(2026, 8, 15),
        ),
      );

      await db.recurringItemsDao.deleteItem('a');

      expect(await db.paymentsDao.watchForItem('a').first, isEmpty);
      expect(await db.paymentsDao.watchForItem('b').first, hasLength(1));
    });

    test('rejects a payment for an unknown item', () async {
      expect(
        db.paymentsDao.insertPayment(
          payment('p', 'ghost', dueDate: DateTime(2026, 8, 15)),
        ),
        throwsA(anything),
      );
    });

    test('clearHistory removes payments but keeps items', () async {
      await db.paymentsDao.insertPayment(
        payment(
          'p1',
          'a',
          dueDate: DateTime(2026, 8, 15),
          paidDate: DateTime(2026, 8, 15),
        ),
      );
      await db.paymentsDao.clearHistory();
      expect(await db.paymentsDao.watchRecentPaid().first, isEmpty);
      expect(await db.recurringItemsDao.getById('a'), isNotNull);
    });
  });

  test('timezone does not shift stored calendar dates', () async {
    // Insert at a late local time; the stored date must be the local day.
    await db.recurringItemsDao.insertItem(
      item('a', nextDueDate: DateTime(2026, 3, 31, 23, 30)),
    );
    final row = await db
        .customSelect('SELECT next_due_date FROM recurring_items')
        .getSingle();
    expect(row.read<String>('next_due_date'), '2026-03-31');
  });
}
