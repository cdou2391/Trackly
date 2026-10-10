import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/error_reporter.dart';
import '../domain/service_catalog.dart';

/// Gives every item that has no logo the key of the catalog service whose name
/// it matches exactly (ignoring case), and its category when it has none.
///
/// Items already carrying a logo key are never touched, so a user's choice is
/// kept. Safe to run on every launch: it only looks at items without a logo.
/// Returns how many items were updated.
Future<int> backfillCatalogLogos(AppDatabase db) async {
  var updated = 0;
  for (final item in await db.recurringItemsDao.getWithoutLogo()) {
    final service = findServiceByName(item.name);
    if (service == null) continue;
    await db.recurringItemsDao.setCatalogService(
      item.id,
      logoKey: service.key,
      categoryId: service.categoryId,
    );
    updated++;
  }
  return updated;
}

/// Runs the backfill once when the app starts. A failure is reported, never
/// shown: logos are cosmetic.
final catalogBackfillProvider = FutureProvider<void>((ref) async {
  try {
    await backfillCatalogLogos(ref.read(appDatabaseProvider));
  } catch (error, stackTrace) {
    await ref.read(errorReporterProvider).captureException(error, stackTrace);
  }
});
