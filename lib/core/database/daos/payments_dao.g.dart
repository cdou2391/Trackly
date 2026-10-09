// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_dao.dart';

// ignore_for_file: type=lint
mixin _$PaymentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $RecurringItemsTable get recurringItems => attachedDatabase.recurringItems;
  $PaymentsTable get payments => attachedDatabase.payments;
  PaymentsDaoManager get managers => PaymentsDaoManager(this);
}

class PaymentsDaoManager {
  final _$PaymentsDaoMixin _db;
  PaymentsDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$RecurringItemsTableTableManager get recurringItems =>
      $$RecurringItemsTableTableManager(
        _db.attachedDatabase,
        _db.recurringItems,
      );
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
}
