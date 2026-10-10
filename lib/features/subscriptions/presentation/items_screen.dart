import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/filter_pill.dart';
import '../../../shared/widgets/sub_page_header.dart';
import '../../home/application/home_providers.dart';
import '../../home/widgets/subscription_row.dart';
import '../application/items_filter.dart';
import 'labels.dart';

/// Every subscription and bill, with Active / Trial / Cancelled filters.
class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({this.initialFilter = ItemFilter.all, super.key});

  final ItemFilter initialFilter;

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  late ItemFilter _filter = widget.initialFilter;

  String _label(ItemFilter filter) {
    final l10n = context.l10n;
    return switch (filter) {
      ItemFilter.all => l10n.filterAll,
      ItemFilter.active => l10n.filterActive,
      ItemFilter.trial => l10n.filterTrial,
      ItemFilter.cancelled => l10n.filterCancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = ref.watch(nowProvider)();
    final items = ref.watch(recurringItemsProvider).value ?? const [];
    final shown = filterItems(items, _filter, now);

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                SubPageHeader(title: l10n.allSubscriptionsTitle),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TracklySpacing.base,
                  ),
                  child: Row(
                    children: [
                      for (final filter in ItemFilter.values) ...[
                        FilterPill(
                          label: _label(filter),
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                        const SizedBox(width: TracklySpacing.sm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: TracklySpacing.md),
                Expanded(
                  child: shown.isEmpty
                      ? Center(
                          child: Text(
                            l10n.noItemsInFilter,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            TracklySpacing.base,
                            0,
                            TracklySpacing.base,
                            TracklySpacing.xxl,
                          ),
                          itemCount: shown.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: TracklySpacing.sm),
                          itemBuilder: (context, index) {
                            final item = shown[index];
                            return SubscriptionRow(
                              item: item,
                              chips: itemChips(context, item, now),
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
