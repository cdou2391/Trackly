import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/trackly_tokens.dart';
import '../../../../core/theme/trackly_type.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../application/insights_summary.dart';

/// Bars for each week of the month, each with its own amount: the lighter bar
/// is what the week costs, the solid one inside it what has been paid. A fully
/// paid week shows its amount in the accent colour; a part-paid one shows the
/// paid share inside the bar and the week's total above it (when the paid part
/// is too short to hold text, the paid share goes above, in the accent colour,
/// under the total).
class PaidWeeksChart extends StatelessWidget {
  const PaidWeeksChart({
    required this.weeks,
    required this.currency,
    required this.locale,
    super.key,
  });

  final List<WeekBucket> weeks;
  final String currency;
  final String locale;

  static const _plotHeight = 188.0;

  /// Room above the tallest bar for its amount.
  static const _labelRoom = 46.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;

    final max = weeks
        .map((w) => math.max(w.total, w.paid))
        .fold<double>(0, math.max);
    if (max <= 0) return const SizedBox.shrink();

    final semantics = [
      for (final w in weeks)
        l10n.insightsWeekSemantics(
          l10n.insightsWeekRange(w.startDay, w.endDay),
          formatMoney(w.paid, currency, locale: locale),
          formatMoney(w.total, currency, locale: locale),
        ),
    ].join('. ');

    final planned = tokens.accent.withValues(alpha: 0.24);

    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Which currency the amounts are in (the compact figures drop it).
          Text(
            currency,
            style: sans(
              13,
              weight: 600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TracklySpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: motionDuration(context, Motion.countUp),
            curve: Motion.curve,
            builder: (context, progress, _) => SizedBox(
              height: _plotHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final week in weeks)
                    Expanded(
                      child: _WeekBar(
                        week: week,
                        max: max,
                        progress: progress,
                        currency: currency,
                        locale: locale,
                        planned: planned,
                        paid: tokens.accent,
                        maxBarHeight: _plotHeight - _labelRoom,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: tokens.cardBorder),
          const SizedBox(height: TracklySpacing.xs),
          Row(
            children: [
              for (final w in weeks)
                Expanded(
                  // Shrinks instead of clipping at large text sizes, with a
                  // little air so neighbouring labels do not touch.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l10n.insightsWeekRange(w.startDay, w.endDay),
                        maxLines: 1,
                        style: sans(
                          13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TracklySpacing.sm),
          Row(
            children: [
              _LegendDot(color: planned, label: l10n.insightsChartPlanned),
              const SizedBox(width: TracklySpacing.base),
              _LegendDot(color: tokens.accent, label: l10n.insightsChartPaid),
            ],
          ),
        ],
      ),
    );
  }
}

/// One week: the amount, then the bar (planned behind, paid in front).
class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.week,
    required this.max,
    required this.progress,
    required this.currency,
    required this.locale,
    required this.planned,
    required this.paid,
    required this.maxBarHeight,
  });

  final WeekBucket week;
  final double max;

  /// 0 to 1: the bars grow from the baseline and the amounts fade in.
  final double progress;
  final String currency;
  final String locale;
  final Color planned;
  final Color paid;
  final double maxBarHeight;

  static const _maxBarWidth = 56.0;

  double _height(double amount) {
    if (amount <= 0) return 0;
    // A visible stub for anything above zero, so a small week is not lost.
    return math.max(amount / max * maxBarHeight * progress, 3 * progress);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalHeight = _height(math.max(week.total, week.paid));
    final paidHeight = _height(week.paid);

    final fullyPaid = week.paid > 0 && week.paid >= week.total;
    final partlyPaid = week.paid > 0 && week.paid < week.total;
    // Inside the bar only when it is tall enough to hold the figure.
    final showPaidInside = partlyPaid && paidHeight >= 22;

    final shown = math.max(week.total, week.paid);
    final label = shown > 0
        ? formatCompactMoney(shown, currency, locale: locale)
        : null;
    // A paid part too short for text: say it above the bar instead.
    final paidAbove = partlyPaid && !showPaidInside;
    final labelOpacity = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (label != null)
          Opacity(
            opacity: labelOpacity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      style: sans(
                        13,
                        weight: fullyPaid ? 700 : 600,
                        color: fullyPaid
                            ? paid
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (paidAbove)
                      Text(
                        formatCompactMoney(week.paid, currency, locale: locale),
                        maxLines: 1,
                        style: sans(13, weight: 700, color: paid),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (totalHeight > 0)
          SizedBox(
            width: _maxBarWidth,
            height: totalHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: planned,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                ),
                if (paidHeight > 0)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: paidHeight,
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: paid,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                        child: showPaidInside
                            ? Center(
                                child: Opacity(
                                  opacity: ((progress - 0.5) / 0.5).clamp(
                                    0.0,
                                    1.0,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Text(
                                        formatCompactMoney(
                                          week.paid,
                                          currency,
                                          locale: locale,
                                        ),
                                        maxLines: 1,
                                        style: sans(
                                          12.5,
                                          weight: 700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: sans(
            13.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
