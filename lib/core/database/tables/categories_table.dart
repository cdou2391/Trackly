import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// Icon key resolved to an icon in the UI layer, not a path.
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isSystem => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Seeded when the database is created. Ids are permanent.
const systemCategories = <({String id, String name, String icon})>[
  (id: 'entertainment', name: 'Entertainment', icon: 'movie'),
  (id: 'software', name: 'Software', icon: 'apps'),
  (id: 'utilities', name: 'Utilities', icon: 'bolt'),
  (id: 'housing', name: 'Housing', icon: 'home'),
  (id: 'transport', name: 'Transport', icon: 'directions_car'),
  (id: 'insurance', name: 'Insurance', icon: 'shield'),
  (id: 'health', name: 'Health', icon: 'favorite'),
  (id: 'education', name: 'Education', icon: 'school'),
  (id: 'fitness', name: 'Fitness', icon: 'fitness_center'),
  (id: 'business', name: 'Business', icon: 'work'),
  (id: 'other', name: 'Other', icon: 'category'),
];
