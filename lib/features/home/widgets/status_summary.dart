import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../l10n/l10n.dart';
import '../application/home_summary.dart';
import 'summary_card.dart';

class StatusSummary extends StatelessWidget {
  const StatusSummary({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Padding(
      // Top gap separates the cards from the hero above.
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.base,
        TracklySpacing.base,
        TracklySpacing.base,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: SummaryCard(
              icon: Icons.credit_card_rounded,
              tone: tokens.summaryActive,
              count: summary.activeCount,
              label: l10n.statusActive,
              onTap: () => context.push(AppRoutes.subscriptionsPath('active')),
            ),
          ),
          const SizedBox(width: TracklySpacing.sm),
          Expanded(
            child: SummaryCard(
              icon: Icons.hourglass_bottom_rounded,
              tone: tokens.summaryTrial,
              count: summary.trialCount,
              label: l10n.statusTrial,
              onTap: () => context.push(AppRoutes.subscriptionsPath('trial')),
            ),
          ),
          const SizedBox(width: TracklySpacing.sm),
          Expanded(
            child: SummaryCard(
              icon: Icons.block_rounded,
              tone: tokens.summaryCancelled,
              count: summary.cancelledCount,
              label: l10n.statusCancelled,
              onTap: () =>
                  context.push(AppRoutes.subscriptionsPath('cancelled')),
            ),
          ),
        ],
      ),
    );
  }
}
