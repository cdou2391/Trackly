import 'package:drift/drift.dart';

import '../../../features/subscriptions/domain/recurring_enums.dart';
import '../../../features/subscriptions/domain/recurring_item.dart';
import '../app_database.dart';
import '../converters.dart';
import '../tables/recurring_items_table.dart';

part 'recurring_items_dao.g.dart';

@DriftAccessor(tables: [RecurringItems])
class RecurringItemsDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringItemsDaoMixin {
  RecurringItemsDao(super.db);

  /// All items, soonest due date first.
  Stream<List<RecurringItem>> watchAll() {
    final query = select(recurringItems)
      ..orderBy([
        (t) => OrderingTerm.asc(t.nextDueDate),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.watch();
  }

  Stream<RecurringItem?> watchById(String id) {
    return (select(
      recurringItems,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<RecurringItem?> getById(String id) {
    return (select(
      recurringItems,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Active items, used for reminder reconciliation and totals.
  Future<List<RecurringItem>> getActive() {
    return (select(
      recurringItems,
    )..where((t) => t.status.equalsValue(ItemStatus.active))).get();
  }

  /// Active items due on or before [until], soonest first.
  Stream<List<RecurringItem>> watchUpcoming({
    required DateTime until,
    int limit = 5,
  }) {
    final query = select(recurringItems)
      ..where(
        (t) =>
            t.status.equalsValue(ItemStatus.active) &
            t.nextDueDate.isSmallerOrEqualValue(formatDateOnly(until)),
      )
      ..orderBy([
        (t) => OrderingTerm.asc(t.nextDueDate),
        (t) => OrderingTerm.asc(t.name),
      ])
      ..limit(limit);
    return query.watch();
  }

  Future<void> insertItem(RecurringItem item) {
    return into(recurringItems).insert(item.toCompanion());
  }

  Future<bool> updateItem(RecurringItem item) {
    return update(recurringItems).replace(item.toCompanion());
  }

  Future<int> deleteItem(String id) {
    return (delete(recurringItems)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteAll() => delete(recurringItems).go();
}

extension RecurringItemToCompanion on RecurringItem {
  RecurringItemsCompanion toCompanion() {
    return RecurringItemsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      amount: Value(amount),
      currencyCode: Value(currencyCode),
      frequency: Value(frequency),
      interval: Value(interval),
      startDate: Value(startDate),
      nextDueDate: Value(nextDueDate),
      status: Value(status),
      isTrial: Value(isTrial),
      trialEndDate: Value(trialEndDate),
      remindersEnabled: Value(remindersEnabled),
      reminderDaysBefore: Value(reminderDaysBefore),
      categoryId: Value(categoryId),
      notes: Value(notes),
      logoKey: Value(logoKey),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}
