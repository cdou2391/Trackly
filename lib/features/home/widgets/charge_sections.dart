import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/cost_utils.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../subscriptions/application/add_panel_controller.dart';
import '../../subscriptions/domain/recurring_item.dart';
import '../../subscriptions/presentation/labels.dart';
import '../application/home_summary.dart';
import 'charge_row.dart';

class UpcomingSection extends StatelessWidget {
  const UpcomingSection({required this.summary, required this.now, super.key});

  final HomeSummary summary;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _Section(
      title: l10n.upcomingTitle,
      // The full upcoming list is not built yet.
      trailing: summary.upcoming.isEmpty
          ? null
          : TextButton(onPressed: () {}, child: Text(l10n.seeAll)),
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

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.item, required this.now});

  final RecurringItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final due = dueStatus(context, item.nextDueDate, now);
    return ChargeRow(
      item: item,
      pills: [
        StatusPill(label: due.label, tone: due.tone),
        if (isInActiveTrial(item, now))
          StatusPill(label: context.l10n.pillTrial, tone: PillTone.warning),
      ],
    );
  }
}

class RecentPaymentsSection extends StatelessWidget {
  const RecentPaymentsSection({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    if (summary.recentPayments.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    return _Section(
      title: l10n.recentPaymentsTitle,
      child: Column(
        children: [
          for (final recent in summary.recentPayments) ...[
            ChargeRow(
              item: recent.item,
              amount: recent.payment.amount,
              pills: [
                StatusPill(
                  label: l10n.paidOn(
                    formatShortDate(
                      recent.payment.paidDate ?? recent.payment.dueDate,
                      locale: locale,
                    ),
                  ),
                  tone: PillTone.success,
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
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.lg,
        TracklySpacing.xl,
        TracklySpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: TracklySpacing.md),
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
              color: theme.colorScheme.primary,
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
