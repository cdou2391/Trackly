import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../application/home_summary.dart';

class StatusSummary extends StatelessWidget {
  const StatusSummary({required this.summary, super.key});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TracklySpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _StatusCard(
              icon: Icons.check_circle_rounded,
              color: TracklyColors.success,
              count: summary.activeCount,
              label: l10n.statusActive,
            ),
          ),
          const SizedBox(width: TracklySpacing.sm),
          Expanded(
            child: _StatusCard(
              icon: Icons.hourglass_bottom_rounded,
              color: TracklyColors.warning,
              count: summary.trialCount,
              label: l10n.statusTrial,
            ),
          ),
          const SizedBox(width: TracklySpacing.sm),
          Expanded(
            child: _StatusCard(
              icon: Icons.cancel_rounded,
              color: TracklyColors.danger,
              count: summary.cancelledCount,
              label: l10n.statusCancelled,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // The chevron matches the design; filtered lists come with the full
    // subscription management screens.
    return Semantics(
      label: context.l10n.statusCount(label, count),
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(TracklySpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: TracklySpacing.sm),
              Text('$count', style: theme.textTheme.headlineMedium),
              Text(
                label,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
