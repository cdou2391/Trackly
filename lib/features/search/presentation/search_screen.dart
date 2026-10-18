import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_bottom_navigation.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../home/application/home_providers.dart';
import '../../home/widgets/subscription_row.dart';
import '../../subscriptions/application/categories_provider.dart';
import '../../subscriptions/domain/recurring_item.dart';
import '../../subscriptions/presentation/labels.dart';
import '../application/item_search.dart';

/// Finds a subscription, bill or trial by name, category or note. Reached from
/// the search icon on Home; works across every status, including paused and
/// cancelled items.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  var _query = '';

  @override
  void initState() {
    super.initState();
    unawaited(
      ref.read(analyticsProvider).logEvent(AnalyticsEvents.searchOpened),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final now = ref.watch(nowProvider)();
    final items = ref.watch(recurringItemsProvider).value ?? const [];
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final names = {for (final c in categories) c.id: c.name};
    final results = searchItems(
      items,
      _query,
      categoryNameOf: (id) => id == null ? null : names[id],
    );
    final searching = searchTerms(_query).isNotEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TracklySpacing.xs,
                    TracklySpacing.xs,
                    TracklySpacing.base,
                    TracklySpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.back,
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: TextField(
                          key: const Key('search-field'),
                          controller: _controller,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => setState(() => _query = value),
                          decoration: InputDecoration(
                            hintText: l10n.searchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.searchClear,
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: _clear,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _body(
                    context,
                    searching: searching,
                    hasItems: items.isNotEmpty,
                    results: results,
                    now: now,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context, {
    required bool searching,
    required bool hasItems,
    required List<RecurringItem> results,
    required DateTime now,
  }) {
    final l10n = context.l10n;

    Widget message(String text) => Padding(
      padding: const EdgeInsets.all(TracklySpacing.xl),
      child: Align(
        alignment: Alignment.topCenter,
        child: Semantics(
          liveRegion: true,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );

    if (!hasItems) return message(l10n.searchNoItems);
    if (!searching) return message(l10n.searchPrompt);
    if (results.isEmpty) return message(l10n.searchNoMatches(_query.trim()));

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        TracklySpacing.base,
        TracklySpacing.sm,
        TracklySpacing.base,
        TracklySpacing.xxl + navOverlayInset(context),
      ),
      itemCount: results.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: TracklySpacing.sm),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Semantics(
            liveRegion: true,
            child: Text(
              l10n.searchResultCount(results.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final item = results[index - 1];
        return SubscriptionRow(
          item: item,
          chips: itemChips(context, item, now),
          onTap: () {
            unawaited(
              ref
                  .read(analyticsProvider)
                  .logEvent(AnalyticsEvents.searchResultOpened),
            );
            context.push(AppRoutes.itemPath(item.id));
          },
        );
      },
    );
  }
}
