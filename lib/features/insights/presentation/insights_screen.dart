import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_bottom_navigation.dart';
import '../../../core/database/tables/categories_table.dart';
import '../../../core/error/error_reporter.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/category_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/currency_amounts.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/service_icon.dart';
import '../../home/widgets/summary_card.dart';
import '../../settings/application/settings_providers.dart';
import '../../subscriptions/domain/recurring_enums.dart';
import '../application/insights_providers.dart';
import '../application/insights_summary.dart';
import 'spending_trend_card.dart';

/// Keeps content readable on tablets and large phones.
const _maxContentWidth = 520.0;

/// What the recurring items cost and where the money goes: monthly and yearly
/// totals, a few counts, and the monthly cost by category. Deliberately small;
/// Trackly is not a budgeting app.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(insightsSummaryProvider);

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: summary.when(
            data: (data) => _InsightsContent(summary: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) {
              ref
                  .read(errorReporterProvider)
                  .captureException(error, stackTrace);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _InsightsContent extends ConsumerWidget {
  const _InsightsContent({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return ListView(
      padding: EdgeInsets.only(bottom: 32 + navOverlayInset(context)),
      children: [
        ScreenHeader(title: l10n.insightsTitle, icon: Icons.insights_rounded),
        if (!summary.hasItems)
          const _EmptyState()
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TracklySpacing.base,
            ),
            child: _TotalsCard(summary: summary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TracklySpacing.base,
              TracklySpacing.md,
              TracklySpacing.base,
              0,
            ),
            child: _Counts(summary: summary),
          ),
          if (summary.monthProgress.isNotEmpty)
            _Section(child: _PaidThisMonth(summary: summary)),
          const _Section(child: SpendingTrendSection()),
          if (summary.categoryBreakdown.isNotEmpty)
            _Section(child: _CategoryBreakdown(summary: summary)),
          if (_hasBothTypes(summary))
            _Section(child: _TypeBreakdown(summary: summary)),
          if (summary.biggestCosts.isNotEmpty)
            _Section(child: _BiggestCosts(summary: summary)),
        ],
      ],
    );
  }
}

/// A block under the totals, with the screen's usual spacing.
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.base,
        TracklySpacing.xl,
        TracklySpacing.base,
        0,
      ),
      child: child,
    );
  }
}

/// Subscriptions and bills are only worth splitting when there are both.
bool _hasBothTypes(InsightsSummary summary) =>
    summary.typeBreakdown.values.any((types) => types.length > 1);

/// A small grey currency label, shown only when there is more than one.
class _CurrencyLabel extends StatelessWidget {
  const _CurrencyLabel(this.currency);

  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TracklySpacing.sm),
      child: Text(
        currency,
        style: sans(
          13,
          weight: 600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(TracklySpacing.xl),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.insights_rounded,
              size: 48,
              color: context.tokens.accent,
            ),
          ),
          const SizedBox(height: TracklySpacing.md),
          Text(
            l10n.insightsEmptyTitle,
            textAlign: TextAlign.center,
            style: sans(17, weight: 600, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: TracklySpacing.xs),
          Text(
            l10n.insightsEmptyBody,
            textAlign: TextAlign.center,
            style: sans(14, color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Monthly and yearly cost side by side, one line per currency.
class _TotalsCard extends ConsumerWidget {
  const _TotalsCard({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = ref.watch(defaultCurrencyProvider);
    final amountStyle = sans(
      24,
      weight: 700,
      color: theme.colorScheme.onSurface,
      height: 1.15,
    );
    final labelStyle = sans(
      13,
      weight: 500,
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget column(String label, Map<String, double> totals) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: TracklySpacing.xs),
          CurrencyAmounts(
            totals: totals,
            emptyCurrency: currency,
            style: amountStyle,
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(TracklyRadius.medium),
        border: Border.all(color: context.tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TracklySpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            column(l10n.insightsPerMonth, summary.monthlyTotalsByCurrency),
            const SizedBox(width: TracklySpacing.base),
            column(l10n.insightsPerYear, summary.yearlyTotalsByCurrency),
          ],
        ),
      ),
    );
  }
}

/// Active, Trial and Upcoming, laid out like the cards on Home: the icon
/// beside the figure. They only inform, so there is no chevron.
class _Counts extends StatelessWidget {
  const _Counts({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            icon: Icons.check_circle_outline_rounded,
            tone: tokens.summaryActive,
            count: summary.activeCount,
            label: l10n.statusActive,
            showChevron: false,
          ),
        ),
        const SizedBox(width: TracklySpacing.sm),
        Expanded(
          child: SummaryCard(
            icon: Icons.hourglass_bottom_rounded,
            tone: tokens.summaryTrial,
            count: summary.trialCount,
            label: l10n.statusTrial,
            showChevron: false,
          ),
        ),
        const SizedBox(width: TracklySpacing.sm),
        Expanded(
          child: SummaryCard(
            icon: Icons.event_rounded,
            tone: tokens.neutral,
            count: summary.upcomingCount,
            label: l10n.insightsChargesAhead,
            showChevron: false,
            semanticsLabel: l10n.insightsChargesAheadSemantics(
              summary.upcomingCount,
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final currencies = summary.categoryBreakdown.keys.toList()..sort();
    final showCurrency = currencies.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.insightsByCategory),
        const SizedBox(height: TracklySpacing.sm),
        for (final currency in currencies) ...[
          if (showCurrency) _CurrencyLabel(currency),
          for (final category in summary.categoryBreakdown[currency]!)
            _ShareRow(
              icon: categoryIconData(category.categoryId),
              color: categoryColor(category.categoryId),
              name: _categoryName(category.categoryId),
              amount: formatMoney(
                category.monthlyAmount,
                currency,
                locale: locale,
              ),
              share: _share(
                category.monthlyAmount,
                summary.monthlyTotalsByCurrency[currency],
              ),
              detail: l10n.insightsTypeItems(category.count),
            ),
        ],
      ],
    );
  }
}

double _share(double amount, double? total) =>
    (total ?? 0) > 0 ? amount / total! : 0.0;

/// Monthly cost of subscriptions against bills.
class _TypeBreakdown extends StatelessWidget {
  const _TypeBreakdown({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final currencies = [
      for (final entry in summary.typeBreakdown.entries)
        if (entry.value.length > 1) entry.key,
    ]..sort();
    final showCurrency = currencies.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.insightsByType),
        const SizedBox(height: TracklySpacing.sm),
        for (final currency in currencies) ...[
          if (showCurrency) _CurrencyLabel(currency),
          for (final type in summary.typeBreakdown[currency]!)
            _ShareRow(
              icon: type.type == RecurringItemType.bill
                  ? Icons.receipt_long_rounded
                  : Icons.autorenew_rounded,
              color: type.type == RecurringItemType.bill
                  ? billTileColor
                  : subscriptionTileColor,
              name: type.type == RecurringItemType.bill
                  ? l10n.insightsTypeBills
                  : l10n.insightsTypeSubscriptions,
              amount: formatMoney(type.monthlyAmount, currency, locale: locale),
              share: _share(
                type.monthlyAmount,
                summary.monthlyTotalsByCurrency[currency],
              ),
              detail: l10n.insightsTypeItems(type.count),
            ),
        ],
      ],
    );
  }
}

/// One card in the style of the subscription lists: an icon, a name with a
/// caption, the amount, and a thin share bar underneath. Used for categories
/// and for subscriptions against bills.
class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.icon,
    required this.color,
    required this.name,
    required this.amount,
    required this.share,
    required this.detail,
  });

  final IconData icon;

  /// The tile color: the category's, or the type's.
  final Color color;
  final String name;
  final String amount;

  /// 0 to 1 of the monthly total.
  final double share;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;
    final percent = (share * 100).round();

    return _InsightCard(
      semanticsLabel:
          '$name, $amount ${l10n.heroMonthSuffix}, $detail, '
          '${l10n.insightsShare(percent)}',
      leading: GlyphTile(
        color: color,
        size: _insightIconSize,
        child: Icon(icon, size: 24, color: Colors.white),
      ),
      title: name,
      subtitle: '$detail · ${l10n.insightsShare(percent)}',
      amount: amount,
      footer: ClipRRect(
        borderRadius: BorderRadius.circular(TracklyRadius.pill),
        child: LinearProgressIndicator(
          value: share.clamp(0.0, 1.0),
          minHeight: 6,
          color: tokens.accent,
          backgroundColor: tokens.fieldFill,
        ),
      ),
    );
  }
}

const _insightIconSize = 44.0;

/// The card every Insights list uses, matching the rows of the subscription
/// lists on Home: a bordered, rounded surface with the icon on the left, the
/// name and a caption beside it, and the amount on the right. A [onTap] adds
/// the chevron; a [footer] sits under the row.
class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.semanticsLabel,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.footer,
    this.onTap,
  });

  final String semanticsLabel;
  final Widget leading;
  final String title;
  final String subtitle;
  final String amount;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: TracklySpacing.sm),
      child: Semantics(
        container: true,
        button: onTap != null,
        label: semanticsLabel,
        excludeSemantics: true,
        child: Material(
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: tokens.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      leading,
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amount,
                        style: sans(
                          17,
                          weight: 600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (onTap != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  if (footer != null) ...[const SizedBox(height: 10), footer!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What has been paid this month against what the month costs.
class _PaidThisMonth extends StatelessWidget {
  const _PaidThisMonth({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toString();
    final currencies = summary.monthProgress.keys.toList()..sort();
    final showCurrency = currencies.length > 1;
    final nothingPaid = summary.monthProgress.values.every((p) => p.paid <= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.insightsPaidThisMonth),
        const SizedBox(height: TracklySpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(TracklyRadius.medium),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TracklySpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (index, currency) in currencies.indexed) ...[
                  if (index > 0) const SizedBox(height: TracklySpacing.base),
                  if (showCurrency) _CurrencyLabel(currency),
                  _ProgressLine(
                    text: l10n.insightsPaidOf(
                      formatMoney(
                        summary.monthProgress[currency]!.paid,
                        currency,
                        locale: locale,
                      ),
                      formatMoney(
                        summary.monthProgress[currency]!.total,
                        currency,
                        locale: locale,
                      ),
                    ),
                    value:
                        summary.monthProgress[currency]!.paid /
                        summary.monthProgress[currency]!.total,
                  ),
                ],
                if (nothingPaid) ...[
                  const SizedBox(height: TracklySpacing.sm),
                  Text(
                    l10n.insightsPaidHint,
                    style: sans(
                      12.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.text, required this.value});

  final String text;

  /// 0 to 1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: sans(20, weight: 700, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: TracklySpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(TracklyRadius.pill),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 8,
              color: tokens.accent,
              backgroundColor: tokens.fieldFill,
            ),
          ),
        ],
      ),
    );
  }
}

/// The costliest items per month, largest first. Tapping one opens it.
class _BiggestCosts extends StatelessWidget {
  const _BiggestCosts({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final currencies = summary.biggestCosts.keys.toList()..sort();
    final showCurrency = currencies.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.insightsBiggest),
        const SizedBox(height: TracklySpacing.sm),
        for (final currency in currencies) ...[
          if (showCurrency) _CurrencyLabel(currency),
          for (final costly in summary.biggestCosts[currency]!)
            _CostlyRow(
              costly: costly,
              amount: formatMoney(
                costly.monthlyAmount,
                currency,
                locale: locale,
              ),
              percent:
                  (_share(
                            costly.monthlyAmount,
                            summary.monthlyTotalsByCurrency[currency],
                          ) *
                          100)
                      .round(),
            ),
        ],
      ],
    );
  }
}

class _CostlyRow extends StatelessWidget {
  const _CostlyRow({
    required this.costly,
    required this.amount,
    required this.percent,
  });

  final CostlyItem costly;
  final String amount;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = costly.item;

    return _InsightCard(
      semanticsLabel:
          '${item.name}, $amount ${l10n.heroMonthSuffix}, '
          '${l10n.insightsBiggestShare(percent)}',
      leading: ServiceIcon(
        logoKey: item.logoKey,
        categoryId: item.categoryId,
        size: _insightIconSize,
      ),
      title: item.name,
      subtitle: l10n.insightsBiggestShare(percent),
      amount: amount,
      onTap: () => context.push(AppRoutes.itemPath(item.id)),
    );
  }
}

String _categoryName(String id) {
  for (final category in systemCategories) {
    if (category.id == id) return category.name;
  }
  return systemCategories.last.name;
}
