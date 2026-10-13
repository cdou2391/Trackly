import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../subscriptions/application/add_panel_controller.dart';
import '../../subscriptions/application/item_analytics.dart';
import '../../subscriptions/domain/recurring_item.dart';
import '../../subscriptions/presentation/labels.dart';
import '../application/home_summary.dart';
import 'subscription_row.dart';

class UpcomingSection extends StatelessWidget {
  const UpcomingSection({required this.summary, required this.now, super.key});

  final HomeSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _Section(
      title: l10n.upcomingTitle,
      actionLabel: summary.upcoming.isEmpty ? null : l10n.seeAll,
      onAction: () => context.push(AppRoutes.subscriptionsPath()),
      child: summary.upcoming.isEmpty
          ? const _EmptyUpcoming()
          : Column(
              children: [
                for (final item in summary.upcoming) ...[
                  _UpcomingRow(item: item, now: now),
                  const SizedBox(height: TracklySpacing.sm),
                ],
              ],
            ),
    );
  }
}

/// Logs that a row on Home was opened, then opens the item.
void _openItem(
  BuildContext context,
  WidgetRef ref,
  RecurringItem item,
  String event,
) {
  ref
      .read(analyticsProvider)
      .logEvent(event, parameters: itemAnalyticsParameters(item));
  context.push(AppRoutes.itemPath(item.id));
}

class _UpcomingRow extends ConsumerWidget {
  const _UpcomingRow({required this.item, required this.now});

  final RecurringItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SubscriptionRow(
      item: item,
      chips: itemChips(context, item, now),
      onTap: () =>
          _openItem(context, ref, item, AnalyticsEvents.upcomingItemOpened),
    );
  }
}

class RecentPaymentsSection extends ConsumerWidget {
  const RecentPaymentsSection({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (summary.recentPayments.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return _Section(
      title: l10n.recentPaymentsTitle,
      actionLabel: l10n.seeAll,
      onAction: () => context.push(AppRoutes.history),
      child: Column(
        children: [
          for (final recent in summary.recentPayments) ...[
            SubscriptionRow(
              item: recent.item,
              amount: recent.payment.amount,
              onTap: () => _openItem(
                context,
                ref,
                recent.item,
                AnalyticsEvents.recentPaymentOpened,
              ),
              chips: [
                StatusChip(
                  label: l10n.paidOn(
                    formatShortDate(
                      recent.payment.paidDate ?? recent.payment.dueDate,
                      locale: locale,
                    ),
                  ),
                  tone: ChipTone.success,
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: TracklySpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.base,
        TracklySpacing.xl,
        TracklySpacing.base,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
          const SizedBox(height: TracklySpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _EmptyUpcoming extends ConsumerWidget {
  const _EmptyUpcoming();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Full width so the content centers on screen, not on its widest child.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TracklySpacing.base),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: context.tokens.accent,
            ),
            const SizedBox(height: TracklySpacing.md),
            Text(l10n.emptyUpcomingTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: TracklySpacing.xs),
            Text(
              l10n.emptyUpcomingBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: TracklySpacing.base),
            OutlinedButton(
              onPressed: ref.read(addPanelProvider.notifier).open,
              child: Text(l10n.navAdd),
            ),
          ],
        ),
      ),
    );
  }
}
