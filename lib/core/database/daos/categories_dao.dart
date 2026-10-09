import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Stream<List<Category>> watchAll() {
    return (select(
      categories,
    )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();
  }

  Future<Category?> getById(String id) {
    return (select(
      categories,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
