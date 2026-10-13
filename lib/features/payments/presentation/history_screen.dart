import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/sub_page_header.dart';
import '../../home/application/home_providers.dart';
import '../../subscriptions/application/item_providers.dart';
import 'widgets/payment_row.dart';

/// Every payment and skipped charge across all items, newest first.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(analyticsProvider).logEvent(AnalyticsEvents.historyOpened),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final payments = ref.watch(allPaymentsProvider).value ?? const [];
    final items = {
      for (final item in ref.watch(recurringItemsProvider).value ?? const [])
        item.id: item,
    };
    // Payments of an item that no longer exists are removed with it.
    final rows = [
      for (final payment in payments)
        if (items[payment.recurringItemId] != null) payment,
    ];

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                SubPageHeader(title: l10n.historyTitle),
                Expanded(
                  child: rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(TracklySpacing.xl),
                          child: Center(
                            child: Text(
                              l10n.historyEmpty,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            TracklySpacing.base,
                            TracklySpacing.sm,
                            TracklySpacing.base,
                            TracklySpacing.xxl,
                          ),
                          itemCount: rows.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: TracklySpacing.sm),
                          itemBuilder: (context, index) {
                            final payment = rows[index];
                            final item = items[payment.recurringItemId]!;
                            return PaymentRow(
                              payment: payment,
                              title: item.name,
                              onTap: () =>
                                  context.push(AppRoutes.itemPath(item.id)),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
