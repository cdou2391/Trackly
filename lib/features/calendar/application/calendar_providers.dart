import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/home_providers.dart';
import '../../subscriptions/application/item_providers.dart';
import 'calendar_month.dart';

/// The Calendar for one month, keyed by the first day of that month. Updates
/// live as items and payments change.
final calendarMonthProvider =
    Provider.family<AsyncValue<CalendarMonth>, DateTime>((ref, month) {
      final items = ref.watch(recurringItemsProvider);
      final payments = ref.watch(allPaymentsProvider);

      final error = items.error ?? payments.error;
      if (error != null) {
        return AsyncValue.error(
          error,
          items.stackTrace ?? payments.stackTrace ?? StackTrace.empty,
        );
      }
      if (!items.hasValue || !payments.hasValue) {
        return const AsyncValue.loading();
      }

      return AsyncValue.data(
        buildCalendarMonth(
          items: items.requireValue,
          payments: payments.requireValue,
          month: month,
          today: ref.watch(nowProvider)(),
        ),
      );
    });
