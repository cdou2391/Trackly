import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/sub_page_header.dart';
import '../../home/application/home_providers.dart';
import '../../home/widgets/subscription_row.dart';
import '../application/items_filter.dart';
import 'labels.dart';

/// Every subscription and bill, in tabs: All, Active, Trial and Cancelled.
///
/// Tapping a tab or swiping slides smoothly from one list to the next.
class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({this.initialFilter = ItemFilter.all, super.key});

  final ItemFilter initialFilter;

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(
    length: ItemFilter.values.length,
    initialIndex: ItemFilter.values.indexOf(widget.initialFilter),
    vsync: this,
    // A touch slower than the default, so the slide reads as smooth.
    animationDuration: const Duration(milliseconds: 320),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    // Four tabs share the width evenly; at large text they scroll instead of
    // squeezing their labels.
    final largeText = MediaQuery.textScalerOf(context).scale(14) / 14 > 1.15;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                SubPageHeader(title: l10n.allSubscriptionsTitle),
                TabBar(
                  controller: _controller,
                  isScrollable: largeText,
                  tabAlignment: largeText ? TabAlignment.start : null,
                  tabs: [
                    for (final filter in ItemFilter.values)
                      // 48 dp tall: the minimum touch target.
                      Tab(text: _label(filter), height: 48),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _controller,
                    children: [
                      for (final filter in ItemFilter.values)
                        _ItemsList(filter: filter),
                    ],
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

/// The list for one tab.
class _ItemsList extends ConsumerWidget {
  const _ItemsList({required this.filter});

  final ItemFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider)();
    final items = ref.watch(recurringItemsProvider).value ?? const [];
    final shown = filterItems(items, filter, now);

    if (shown.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noItemsInFilter,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return ListView.separated(
      // Each tab remembers its own scroll position while you switch.
      key: PageStorageKey<ItemFilter>(filter),
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.base,
        TracklySpacing.base,
        TracklySpacing.base,
        TracklySpacing.xxl,
      ),
      itemCount: shown.length,
      separatorBuilder: (_, _) => const SizedBox(height: TracklySpacing.sm),
      itemBuilder: (context, index) {
        final item = shown[index];
        return SubscriptionRow(
          item: item,
          chips: itemChips(context, item, now),
          onTap: () => context.push(AppRoutes.itemPath(item.id)),
        );
      },
    );
  }
}
