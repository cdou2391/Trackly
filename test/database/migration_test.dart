import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/app_database.dart';

import 'generated/schema.dart';

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

  test('a fresh database matches the committed v1 schema', () async {
    final connection = await verifier.startAt(1);
    final db = AppDatabase(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });

  test('schemaVersion matches the latest dumped schema', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 1);
  });
}
