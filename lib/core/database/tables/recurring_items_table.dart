// Column constraints refer to their own column inside check(); that is
// Drift's documented pattern, so the lint does not apply here.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../../../features/subscriptions/domain/recurring_enums.dart';
import '../../../features/subscriptions/domain/recurring_item.dart';
import '../converters.dart';
import 'categories_table.dart';

/// Rows map straight onto the [RecurringItem] domain class.
///
/// Enums are stored by name, so renaming an enum value needs a migration.
@UseRowClass(RecurringItem)
@TableIndex(name: 'idx_recurring_items_next_due', columns: {#nextDueDate})
@TableIndex(name: 'idx_recurring_items_status', columns: {#status})
class RecurringItems extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();
  TextColumn get type => textEnum<RecurringItemType>()();

  RealColumn get amount => real().check(amount.isBiggerOrEqualValue(0))();
  TextColumn get currencyCode => text()();

  TextColumn get frequency => textEnum<BillingFrequency>()();
  IntColumn get interval => integer()
      .withDefault(const Constant(1))
      .check(interval.isBiggerOrEqualValue(1))();

  TextColumn get startDate => text().map(const DateOnlyConverter())();
  TextColumn get nextDueDate => text().map(const DateOnlyConverter())();

  TextColumn get status => textEnum<ItemStatus>()();

  BoolColumn get isTrial => boolean().withDefault(const Constant(false))();
  TextColumn get trialEndDate =>
      text().map(const DateOnlyConverter()).nullable()();

  BoolColumn get remindersEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get reminderDaysBefore => integer()
      .withDefault(const Constant(3))
      .check(reminderDaysBefore.isBiggerOrEqualValue(0))();

  TextColumn get categoryId => text()
      .nullable()
      .references(Categories, #id, onDelete: KeyAction.setNull)();
  TextColumn get notes => text().nullable()();

  /// Key into the bundled service catalog. Null for custom services.
  TextColumn get logoKey => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
