import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/tables/categories_table.dart';
import '../../../core/error/error_reporter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/currency_amounts.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/service_icon.dart';
import '../../settings/application/settings_providers.dart';
import '../application/insights_providers.dart';
import '../application/insights_summary.dart';

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
      padding: const EdgeInsets.only(bottom: 120),
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
          if (summary.categoryBreakdown.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TracklySpacing.base,
                TracklySpacing.xl,
                TracklySpacing.base,
                0,
              ),
              child: _CategoryBreakdown(summary: summary),
            ),
        ],
      ],
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

class _Counts extends StatelessWidget {
  const _Counts({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CountCard(
            icon: Icons.check_circle_outline_rounded,
            tone: tokens.summaryActive,
            count: summary.activeCount,
            label: l10n.statusActive,
          ),
          const SizedBox(width: TracklySpacing.sm),
          _CountCard(
            icon: Icons.hourglass_bottom_rounded,
            tone: tokens.summaryTrial,
            count: summary.trialCount,
            label: l10n.statusTrial,
          ),
          const SizedBox(width: TracklySpacing.sm),
          _CountCard(
            icon: Icons.event_rounded,
            tone: tokens.neutral,
            count: summary.upcomingCount,
            label: l10n.insightsChargesAhead,
            semanticsLabel: l10n.insightsChargesAheadSemantics(
              summary.upcomingCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.icon,
    required this.tone,
    required this.count,
    required this.label,
    this.semanticsLabel,
  });

  final IconData icon;
  final ToneColors tone;
  final int count;
  final String label;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Semantics(
        container: true,
        label: semanticsLabel ?? context.l10n.statusCount(label, count),
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.tokens.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tone.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: tone.fg),
                ),
                const SizedBox(height: TracklySpacing.sm),
                Text(
                  '$count',
                  style: sans(
                    24,
                    weight: 700,
                    color: theme.colorScheme.onSurface,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: sans(12.5, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final currencies = summary.categoryBreakdown.keys.toList()..sort();
    final showCurrency = currencies.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: context.l10n.insightsByCategory),
        const SizedBox(height: TracklySpacing.sm),
        for (final currency in currencies) ...[
          if (showCurrency)
            Padding(
              padding: const EdgeInsets.only(bottom: TracklySpacing.sm),
              child: Text(
                currency,
                style: sans(
                  13,
                  weight: 600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final category in summary.categoryBreakdown[currency]!)
            _CategoryRow(
              category: category,
              currency: currency,
              total: summary.monthlyTotalsByCurrency[currency] ?? 0,
            ),
        ],
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.currency,
    required this.total,
  });

  final CategoryTotal category;
  final String currency;
  final double total;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toString();

    final share = total > 0 ? category.monthlyAmount / total : 0.0;
    final percent = (share * 100).round();
    final name = _categoryName(category.categoryId);
    final amount = formatMoney(
      category.monthlyAmount,
      currency,
      locale: locale,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: TracklySpacing.md),
      child: Semantics(
        container: true,
        label:
            '$name, $amount ${l10n.heroMonthSuffix}, '
            '${l10n.insightsCategorySubs(category.count)}, '
            '${l10n.insightsShare(percent)}',
        excludeSemantics: true,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tokens.tileFill,
                borderRadius: BorderRadius.circular(TracklyRadius.small),
              ),
              child: Icon(
                categoryIconData(category.categoryId),
                size: 22,
                color: tokens.tileInk,
              ),
            ),
            const SizedBox(width: TracklySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: sans(
                            16,
                            weight: 600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: TracklySpacing.sm),
                      Text(
                        amount,
                        style: sans(
                          16,
                          weight: 600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(TracklyRadius.pill),
                    child: LinearProgressIndicator(
                      value: share.clamp(0.0, 1.0),
                      minHeight: 6,
                      color: tokens.accent,
                      backgroundColor: tokens.fieldFill,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.insightsCategorySubs(category.count)} · '
                    '${l10n.insightsShare(percent)}',
                    style: sans(
                      12.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _categoryName(String id) {
  for (final category in systemCategories) {
    if (category.id == id) return category.name;
  }
  return systemCategories.last.name;
}
