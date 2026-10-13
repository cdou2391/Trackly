import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';
import 'package:trackly/features/export/application/data_export.dart';
import 'package:trackly/features/home/application/home_providers.dart';
import 'package:trackly/features/import/application/data_import.dart';
import 'package:trackly/features/import/application/import_plan.dart';
import 'package:trackly/features/payments/domain/payment.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 13, 15, 30);

RecurringItem item(
  String id,
  String name, {
  double amount = 15.49,
  String currency = 'USD',
  BillingFrequency frequency = BillingFrequency.monthly,
  int interval = 1,
  ItemStatus status = ItemStatus.active,
  RecurringItemType type = RecurringItemType.subscription,
  DateTime? trialEnd,
  bool reminders = true,
  int reminderDays = 3,
  int reminderMinute = 540,
  String? category,
  String? notes,
}) {
  return RecurringItem(
    id: id,
    name: name,
    type: type,
    amount: amount,
    currencyCode: currency,
    frequency: frequency,
    interval: interval,
    startDate: DateTime(2026, 1, 5),
    nextDueDate: DateTime(2026, 10, 20),
    status: status,
    isTrial: trialEnd != null,
    trialEndDate: trialEnd,
    remindersEnabled: reminders,
    reminderDaysBefore: reminderDays,
    reminderMinuteOfDay: reminderMinute,
    categoryId: category,
    notes: notes,
    createdAt: DateTime(2026, 2, 3, 14, 30),
    updatedAt: _now,
  );
}

Payment payment(
  String id,
  String itemId,
  DateTime due, {
  PaymentStatus status = PaymentStatus.paid,
  double amount = 15.49,
  String currency = 'USD',
}) {
  return Payment(
    id: id,
    recurringItemId: itemId,
    amount: amount,
    currencyCode: currency,
    dueDate: due,
    paidDate: status == PaymentStatus.paid ? due : null,
    status: status,
    createdAt: DateTime(2026, 9, 1, 8),
  );
}

PickedCsv file(String name, String text) =>
    PickedCsv(name: name, bytes: Uint8List.fromList(utf8.encode(text)));

void main() {
  group('decodeCsvBytes', () {
    test('reads UTF-8, accents and other scripts included', () {
      expect(decodeCsvBytes(utf8.encode('Café 音楽')), 'Café 音楽');
    });

    test('reads UTF-16 with either byte order mark', () {
      final units = 'Café,€1'.codeUnits;
      final little = [
        0xFF,
        0xFE,
        for (final u in units) ...[u & 0xFF, u >> 8],
      ];
      final big = [
        0xFE,
        0xFF,
        for (final u in units) ...[u >> 8, u & 0xFF],
      ];
      expect(decodeCsvBytes(little), 'Café,€1');
      expect(decodeCsvBytes(big), 'Café,€1');
    });

    test('refuses a Windows-1252 file instead of guessing', () {
      // "Café" saved by Excel as plain "CSV": é is the single byte 0xE9.
      expect(
        () => decodeCsvBytes([0x43, 0x61, 0x66, 0xE9]),
        throwsA(isA<CsvDecodeException>()),
      );
    });

    test('empty bytes are empty text', () {
      expect(decodeCsvBytes(const []), '');
    });
  });

  group('with a database', () {
    late AppDatabase db;
    late ProviderContainer container;
    late DataImporter importer;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          nowProvider.overrideWithValue(() => _now),
        ],
      );
      importer = container.read(dataImporterProvider);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test(
      'plans files that were too large or not text as file problems',
      () async {
        final plan = await importer.planFor([
          PickedCsv(name: 'big.csv', bytes: Uint8List(0), tooLarge: true),
          PickedCsv(name: 'old.csv', bytes: Uint8List.fromList([0x43, 0xE9])),
          file(
            'good.csv',
            'name,amount,currency,frequency,next_due_date\n'
                'Netflix,15.49,USD,monthly,2026-11-02',
          ),
        ]);

        expect(plan.newItems, hasLength(1));
        expect(plan.fileProblems.map((i) => (i.kind, i.file)), [
          (ImportIssueKind.fileTooLarge, 'big.csv'),
          (ImportIssueKind.notUtf8, 'old.csv'),
        ]);
      },
    );

    test('apply writes items and payments and gives catalog logos', () async {
      final plan = await importer.planFor([
        file(
          'subs.csv',
          'name,amount,currency,frequency,next_due_date,id\n'
              'Netflix,15.49,USD,monthly,2026-11-02,nf-1\n'
              'My gym,30,USD,monthly,2026-11-05,gym-1',
        ),
        file(
          'pays.csv',
          'subscription_id,due_date,paid_date,status,amount\n'
              'nf-1,2026-10-02,2026-10-02,paid,15.49',
        ),
      ]);

      final result = await importer.apply(plan);

      expect((result.items, result.payments), (2, 1));
      final items = {
        for (final i in await db.recurringItemsDao.getAll()) i.id: i,
      };
      expect(items.keys, containsAll(['nf-1', 'gym-1']));
      expect(
        items['nf-1']!.logoKey,
        isNotNull,
        reason: 'Netflix is in the catalog',
      );
      expect(items['gym-1']!.logoKey, isNull);
      final payments = await db.paymentsDao.getAll();
      expect(payments.single.recurringItemId, 'nf-1');
    });

    test('nothing is written if any write fails', () async {
      final a = item('same-id', 'A');
      final b = item(
        'same-id',
        'B',
      ); // the second insert breaks the primary key
      final plan = ImportPlan(
        newItems: [a, b],
        newPayments: [payment('p1', 'same-id', DateTime(2026, 9, 1))],
        duplicateItems: 0,
        duplicatePayments: 0,
        problems: const [],
        warnings: const [],
        fileProblems: const [],
      );

      await expectLater(importer.apply(plan), throwsA(anything));

      expect(await db.recurringItemsDao.getAll(), isEmpty);
      expect(await db.paymentsDao.getAll(), isEmpty);
    });

    test('an existing item is never changed by an import', () async {
      await db.recurringItemsDao.insertItem(
        item('nf-1', 'Netflix', notes: 'mine'),
      );
      final plan = await importer.planFor([
        file(
          'subs.csv',
          'name,amount,currency,frequency,next_due_date,notes,id\n'
              'Netflix,99,EUR,yearly,2030-01-01,overwritten,nf-1',
        ),
      ]);
      expect(plan.hasAnythingToImport, isFalse);

      final after = await db.recurringItemsDao.getById('nf-1');
      expect(after!.notes, 'mine');
      expect(after.amount, 15.49);
    });

    test('an export imports back unchanged: export, wipe, import', () async {
      final items = [
        item('i1', 'Netflix', category: 'entertainment', notes: 'Family plan'),
        item(
          'i2',
          'Café, "Pro" 音楽',
          amount: 1234.5,
          currency: 'RWF',
          frequency: BillingFrequency.custom,
          interval: 45,
          notes: 'line one\nline two, with a comma and a "quote"',
          reminders: false,
          reminderDays: 7,
          reminderMinute: 18 * 60 + 5,
        ),
        item('i3', '=HYPERLINK("http://x")', notes: '@mention'),
        item('i4', "'=quoted", notes: "'-5"),
        item('i5', "'tis the season", status: ItemStatus.paused),
        item(
          'i6',
          'Trial app',
          trialEnd: DateTime(2026, 11, 1),
          frequency: BillingFrequency.yearly,
        ),
        item(
          'i7',
          'Rent',
          type: RecurringItemType.bill,
          status: ItemStatus.cancelled,
        ),
        item('i8', '-Gym', frequency: BillingFrequency.weekly),
      ];
      final payments = [
        payment('p1', 'i1', DateTime(2026, 9, 20)),
        payment(
          'p2',
          'i1',
          DateTime(2026, 8, 20),
          status: PaymentStatus.skipped,
        ),
        payment(
          'p3',
          'i2',
          DateTime(2026, 9, 1),
          amount: 1234.5,
          currency: 'RWF',
        ),
        payment('p4', 'i3', DateTime(2026, 9, 2)),
      ];
      for (final i in items) {
        await db.recurringItemsDao.insertItem(i);
      }
      for (final p in payments) {
        await db.paymentsDao.insertPayment(p);
      }

      // Export exactly as the app does.
      final categories = await db.categoriesDao.getAll();
      final exported = buildExportFiles(
        items: await db.recurringItemsDao.getAll(),
        payments: await db.paymentsDao.getAll(),
        categoryNames: {for (final c in categories) c.id: c.name},
        now: _now,
      );

      await db.deleteAllUserData();
      expect(await db.recurringItemsDao.getAll(), isEmpty);

      final plan = await importer.planFor([
        PickedCsv(
          name: exported[0].name,
          bytes: Uint8List.fromList(exported[0].bytes),
        ),
        PickedCsv(
          name: exported[1].name,
          bytes: Uint8List.fromList(exported[1].bytes),
        ),
      ]);
      expect(
        plan.problems,
        isEmpty,
        reason: '${plan.problems.map((p) => p.kind)}',
      );
      expect(plan.fileProblems, isEmpty);
      expect(plan.warnings, isEmpty);
      await importer.apply(plan);

      final back = {
        for (final i in await db.recurringItemsDao.getAll()) i.id: i,
      };
      expect(back.keys.toSet(), items.map((i) => i.id).toSet());
      for (final original in items) {
        final got = back[original.id]!;
        final why = original.name;
        expect(got.name, original.name, reason: why);
        expect(got.type, original.type, reason: why);
        expect(got.status, original.status, reason: why);
        expect(got.amount, original.amount, reason: why);
        expect(got.currencyCode, original.currencyCode, reason: why);
        expect(got.frequency, original.frequency, reason: why);
        expect(got.interval, original.interval, reason: why);
        expect(got.startDate, original.startDate, reason: why);
        expect(got.nextDueDate, original.nextDueDate, reason: why);
        expect(got.isTrial, original.isTrial, reason: why);
        expect(got.trialEndDate, original.trialEndDate, reason: why);
        expect(got.remindersEnabled, original.remindersEnabled, reason: why);
        expect(
          got.reminderDaysBefore,
          original.reminderDaysBefore,
          reason: why,
        );
        expect(
          got.reminderMinuteOfDay,
          original.reminderMinuteOfDay,
          reason: why,
        );
        expect(got.categoryId, original.categoryId, reason: why);
        expect(got.notes, original.notes, reason: why);
        expect(got.createdAt, DateTime(2026, 2, 3), reason: 'date only: $why');
      }

      final backPayments = {
        for (final p in await db.paymentsDao.getAll()) p.id: p,
      };
      expect(backPayments.keys.toSet(), payments.map((p) => p.id).toSet());
      for (final original in payments) {
        final got = backPayments[original.id]!;
        expect(got.recurringItemId, original.recurringItemId);
        expect(got.amount, original.amount);
        expect(got.currencyCode, original.currencyCode);
        expect(got.dueDate, original.dueDate);
        expect(got.paidDate, original.paidDate);
        expect(got.status, original.status);
      }

      // Importing the same files again changes nothing.
      final again = await importer.planFor([
        PickedCsv(
          name: exported[0].name,
          bytes: Uint8List.fromList(exported[0].bytes),
        ),
        PickedCsv(
          name: exported[1].name,
          bytes: Uint8List.fromList(exported[1].bytes),
        ),
      ]);
      expect(again.hasAnythingToImport, isFalse);
      expect(again.duplicateItems, items.length);
      expect(again.duplicatePayments, payments.length);
    });

    test(
      'importing into a database that already has some of it fills the gaps',
      () async {
        await db.recurringItemsDao.insertItem(item('i1', 'Netflix'));
        final plan = await importer.planFor([
          file(
            'subs.csv',
            'name,amount,currency,frequency,next_due_date,id\n'
                'Netflix,15.49,USD,monthly,2026-10-20,i1\n'
                'Gym,30,USD,monthly,2026-10-25,i2',
          ),
          file(
            'pays.csv',
            'subscription_id,due_date,paid_date,status,amount,id\n'
                'i1,2026-09-20,2026-09-20,paid,15.49,p1\n'
                'i2,2026-09-25,2026-09-25,paid,30,p2',
          ),
        ]);

        expect(plan.newItems.map((i) => i.id), ['i2']);
        expect(plan.duplicateItems, 1);
        expect(plan.newPayments.map((p) => p.id), ['p1', 'p2']);
      },
    );
  });
}
