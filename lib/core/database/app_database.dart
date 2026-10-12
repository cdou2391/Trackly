import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/payments/domain/payment.dart';
import '../../features/subscriptions/domain/recurring_enums.dart';
import '../../features/subscriptions/domain/recurring_item.dart';
import 'converters.dart';
import 'daos/categories_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/recurring_items_dao.dart';
import 'tables/categories_table.dart';
import 'tables/payments_table.dart';
import 'tables/recurring_items_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [RecurringItems, Payments, Categories],
  daos: [RecurringItemsDao, PaymentsDao, CategoriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database file: `trackly.db`.
  AppDatabase.open() : super(driftDatabase(name: 'trackly'));

  /// Removes every subscription, bill and trial, and every payment (payments
  /// go with their item). The built-in categories stay.
  Future<void> deleteAllUserData() {
    return transaction(() async {
      await paymentsDao.clearHistory();
      await recurringItemsDao.deleteAll();
    });
  }

  /// Bump on every schema change, add a step to [migration], and dump the new
  /// schema with `dart run drift_dev schema dump` (see drift_schemas/).
  /// Never delete the database to migrate.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await batch((b) {
          b.insertAll(categories, [
            for (final (index, category) in systemCategories.indexed)
              CategoriesCompanion.insert(
                id: category.id,
                name: category.name,
                icon: Value(category.icon),
                sortOrder: index,
                isSystem: true,
              ),
          ]);
        });
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Reminders gained a time of day; existing items keep 09:00.
          await m.addColumn(recurringItems, recurringItems.reminderMinuteOfDay);
        }
      },
      beforeOpen: (details) async {
        // Needed for cascade deletes and category set-null to work.
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});
