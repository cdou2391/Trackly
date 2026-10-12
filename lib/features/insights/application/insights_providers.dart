import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/home_providers.dart';
import 'insights_summary.dart';

final insightsSummaryProvider = Provider<AsyncValue<InsightsSummary>>((ref) {
  final items = ref.watch(recurringItemsProvider);

  if (items.hasError && !items.hasValue) {
    return AsyncValue.error(items.error!, items.stackTrace ?? StackTrace.empty);
  }
  if (!items.hasValue) return const AsyncValue.loading();

  return AsyncValue.data(
    buildInsightsSummary(
      items: items.requireValue,
      now: ref.watch(nowProvider)(),
    ),
  );
});
