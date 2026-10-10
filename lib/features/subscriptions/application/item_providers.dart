import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../payments/domain/payment.dart';
import '../domain/recurring_item.dart';

/// One item, live. Emits null once it has been deleted.
final itemProvider = StreamProvider.family<RecurringItem?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).recurringItemsDao.watchById(id);
});

/// One item's payments and skips, newest first.
final itemPaymentsProvider = StreamProvider.family<List<Payment>, String>((
  ref,
  id,
) {
  return ref.watch(appDatabaseProvider).paymentsDao.watchForItem(id);
});

/// Every payment and skip across all items, newest first.
final allPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(appDatabaseProvider).paymentsDao.watchAll();
});
