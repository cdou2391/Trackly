import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/trackly_tokens.dart';
import '../../../../core/theme/trackly_type.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../application/insights_summary.dart';

/// Bars for each week of the month: the lighter bar is what the week costs,
/// the solid one inside it is what has already been paid.
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

  static const _plotHeight = 112.0;

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

    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: motionDuration(context, Motion.countUp),
            curve: Motion.curve,
            builder: (context, progress, _) => SizedBox(
              height: _plotHeight,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarsPainter(
                  weeks: weeks,
                  max: max,
                  progress: progress,
                  planned: tokens.accent.withValues(alpha: 0.24),
                  paid: tokens.accent,
                  baseline: tokens.cardBorder,
                ),
              ),
            ),
          ),
          const SizedBox(height: TracklySpacing.xs),
          Row(
            children: [
              for (final w in weeks)
                Expanded(
                  child: Text(
                    l10n.insightsWeekRange(w.startDay, w.endDay),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: sans(
                      11.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TracklySpacing.sm),
          Row(
            children: [
              _LegendDot(
                color: tokens.accent.withValues(alpha: 0.24),
                label: l10n.insightsChartPlanned,
              ),
              const SizedBox(width: TracklySpacing.base),
              _LegendDot(color: tokens.accent, label: l10n.insightsChartPaid),
            ],
          ),
        ],
      ),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: sans(
            12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.weeks,
    required this.max,
    required this.progress,
    required this.planned,
    required this.paid,
    required this.baseline,
  });

  final List<WeekBucket> weeks;
  final double max;

  /// 0 to 1: the bars grow from the baseline.
  final double progress;
  final Color planned;
  final Color paid;
  final Color baseline;

  @override
  void paint(Canvas canvas, Size size) {
    if (weeks.isEmpty) return;
    final floor = size.height - 1;
    final top = 6.0;
    final plot = floor - top;
    final cell = size.width / weeks.length;
    final barWidth = math.min(cell * 0.56, 44.0);
    const radius = Radius.circular(8);

    canvas.drawLine(
      Offset(0, floor),
      Offset(size.width, floor),
      Paint()
        ..color = baseline
        ..strokeWidth = 1,
    );

    for (var i = 0; i < weeks.length; i++) {
      final week = weeks[i];
      final left = cell * i + (cell - barWidth) / 2;

      RRect bar(double amount) {
        final height = (amount / max) * plot * progress;
        // A visible stub for anything above zero, so a small week is not lost.
        final h = amount > 0 ? math.max(height, 3.0 * progress) : 0.0;
        return RRect.fromRectAndCorners(
          Rect.fromLTWH(left, floor - h, barWidth, h),
          topLeft: radius,
          topRight: radius,
        );
      }

      if (week.total > 0) {
        canvas.drawRRect(bar(week.total), Paint()..color = planned);
      }
      if (week.paid > 0) {
        canvas.drawRRect(bar(week.paid), Paint()..color = paid);
      }
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress ||
      old.weeks != weeks ||
      old.max != max ||
      old.planned != planned ||
      old.paid != paid;
}
