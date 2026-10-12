import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;

/// Guards the on-device schema.
///
/// When the schema changes: bump `schemaVersion`, add a migration step, run
///   dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
///   dart run drift_dev schema generate drift_schemas/ test/database/generated/
/// and add an upgrade test from the previous version below.
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('a fresh database matches the committed v2 schema', () async {
    final connection = await verifier.startAt(2);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 2);
  });

  test('schemaVersion matches the latest dumped schema', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 2);
    expect(GeneratedHelper.versions.last, db.schemaVersion);
  });

  group('v1 to v2: reminders get a time of day', () {
    /// A database as v1 left it, with one subscription in it.
    Future<void> insertV1Item(QueryExecutor connection) async {
      final old = v1.DatabaseAtV1(connection);
      await old.customStatement(
        'INSERT INTO recurring_items '
        '(id, name, type, amount, currency_code, frequency, interval, '
        'start_date, next_due_date, status, is_trial, reminders_enabled, '
        'reminder_days_before, created_at, updated_at) '
        "VALUES ('old', 'Netflix', 'subscription', 15.49, 'USD', 'monthly', 1, "
        "'2026-01-15', '2026-10-15', 'active', 0, 1, 5, 1760000000, 1760000000)",
      );
      await old.close();
    }

    test('the schema matches v2 after upgrading', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 2);
    });

    test('existing items keep their data and get 9:00', () async {
      final schema = await verifier.schemaAt(1);
      await insertV1Item(schema.newConnection());

      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);

      final item = await db.recurringItemsDao.getById('old');
      expect(item, isNotNull);
      expect(item!.name, 'Netflix');
      expect(item.amount, 15.49);
      expect(item.reminderDaysBefore, 5);
      expect(item.remindersEnabled, isTrue);
      // What they always had: a reminder at 9:00.
      expect(item.reminderMinuteOfDay, 9 * 60);
    });

    test('the upgraded database still rejects a time that is not a time', () async {
      final schema = await verifier.schemaAt(1);
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);

      Future<void> insertWithMinute(int minute) => db.customStatement(
        'INSERT INTO recurring_items '
        '(id, name, type, amount, currency_code, frequency, interval, '
        'start_date, next_due_date, status, is_trial, reminders_enabled, '
        'reminder_days_before, reminder_minute_of_day, created_at, updated_at) '
        "VALUES ('x$minute', 'X', 'bill', 1, 'USD', 'monthly', 1, "
        "'2026-01-15', '2026-10-15', 'active', 0, 1, 3, $minute, 1, 1)",
      );

      await insertWithMinute(0);
      await insertWithMinute(1439);
      await expectLater(insertWithMinute(1440), throwsA(anything));
      await expectLater(insertWithMinute(-1), throwsA(anything));
    });
  });
}
