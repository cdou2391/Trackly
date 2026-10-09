import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../payments/domain/payment.dart';
import '../../subscriptions/domain/recurring_item.dart';
import 'home_summary.dart';

/// Current time, overridable in tests.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final recurringItemsProvider = StreamProvider<List<RecurringItem>>((ref) {
  return ref.watch(appDatabaseProvider).recurringItemsDao.watchAll();
});

final recentPaymentsProvider = StreamProvider<List<Payment>>((ref) {
  return ref.watch(appDatabaseProvider).paymentsDao.watchRecentPaid();
});

final homeSummaryProvider = Provider<AsyncValue<HomeSummary>>((ref) {
  final items = ref.watch(recurringItemsProvider);
  final payments = ref.watch(recentPaymentsProvider);

  final error = items.error ?? payments.error;
  if (error != null) {
    return AsyncValue.error(
      error,
      items.stackTrace ?? payments.stackTrace ?? StackTrace.empty,
    );
  }
  if (!items.hasValue || !payments.hasValue) return const AsyncValue.loading();

  return AsyncValue.data(
    buildHomeSummary(
      items: items.requireValue,
      recentPaid: payments.requireValue,
      now: ref.watch(nowProvider)(),
    ),
  );
});
