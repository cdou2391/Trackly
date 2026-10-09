// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_items_dao.dart';

// ignore_for_file: type=lint
mixin _$RecurringItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoriesTable get categories => attachedDatabase.categories;
  $RecurringItemsTable get recurringItems => attachedDatabase.recurringItems;
  RecurringItemsDaoManager get managers => RecurringItemsDaoManager(this);
}

class RecurringItemsDaoManager {
  final _$RecurringItemsDaoMixin _db;
  RecurringItemsDaoManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$RecurringItemsTableTableManager get recurringItems =>
      $$RecurringItemsTableTableManager(
        _db.attachedDatabase,
        _db.recurringItems,
      );
}
