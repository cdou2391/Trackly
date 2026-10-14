import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/home_providers.dart';
import '../../subscriptions/application/item_providers.dart';
import 'insights_summary.dart';

final insightsSummaryProvider = Provider<AsyncValue<InsightsSummary>>((ref) {
  final items = ref.watch(recurringItemsProvider);
  final payments = ref.watch(allPaymentsProvider);

  final error = items.error ?? payments.error;
  if (error != null && !(items.hasValue && payments.hasValue)) {
    return AsyncValue.error(
      error,
      items.stackTrace ?? payments.stackTrace ?? StackTrace.empty,
    );
  }
  if (!items.hasValue || !payments.hasValue) return const AsyncValue.loading();

  return AsyncValue.data(
    buildInsightsSummary(
      items: items.requireValue,
      payments: payments.requireValue,
      now: ref.watch(nowProvider)(),
    ),
  );
});
