import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/trackly_type.dart';
import '../../../../l10n/l10n.dart';

/// One slice of the donut.
class DonutSlice {
  const DonutSlice({required this.color, required this.value, this.name = ''});

  final Color color;
  final double value;

  /// The category's name, shown in the legend.
  final String name;
}

/// The legend: a coloured dot and the category name, one per slice.
class DonutLegend extends StatelessWidget {
  const DonutLegend({required this.slices, super.key});

  final List<DonutSlice> slices;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    slice.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: sans(15.5, color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A pie with a hole: each slice is one category's share of the monthly cost,
/// with the total in the middle. It sweeps open when it first appears.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    required this.slices,
    required this.total,
    required this.semanticsLabel,
    this.size = defaultSize,
    super.key,
  });

  /// The donut is a square of this side.
  final double size;

  final List<DonutSlice> slices;

  /// The formatted total, shown in the centre.
  final String total;
  final String semanticsLabel;

  static const defaultSize = 210.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sum = slices.fold<double>(0, (a, s) => a + s.value);
    // The ring's width follows the donut's size.
    final thickness = size * 0.19;
    if (sum <= 0) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: motionDuration(context, Motion.countUp),
                curve: Motion.curve,
                builder: (context, progress, _) => CustomPaint(
                  size: Size(size, size),
                  painter: _DonutPainter(
                    slices: slices,
                    sum: sum,
                    progress: progress,
                    thickness: thickness,
                    track: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    textScaler: MediaQuery.textScalerOf(context)
                        .clamp(maxScaleFactor: 1.2),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(thickness + 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total,
                        style: sans(
                          22,
                          weight: 700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.insightsPerMonth,
                        style: sans(
                          13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.sum,
    required this.progress,
    required this.thickness,
    required this.track,
    required this.textScaler,
  });

  final TextScaler textScaler;
  final List<DonutSlice> slices;
  final double sum;

  /// 0 to 1: how much of the ring has been drawn.
  final double progress;
  final double thickness;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    canvas.drawArc(rect, 0, math.pi * 2, false, ring..color = track);

    // A small gap between slices (none when there is only one).
    final gap = slices.length > 1 ? 0.035 : 0.0;
    final drawn = math.pi * 2 * progress;
    var start = -math.pi / 2;

    for (final slice in slices) {
      final sweep = slice.value / sum * math.pi * 2;
      final from = start;
      start += sweep;

      // Only what the sweep has reached so far.
      final reached = drawn - (from + math.pi / 2);
      if (reached <= 0) continue;
      final visible = math.min(sweep - gap, reached);
      if (visible <= 0) continue;

      canvas.drawArc(
        rect,
        from + gap / 2,
        visible,
        false,
        ring..color = slice.color,
      );

      _percent(canvas, rect, slice, from, sweep);
    }
  }

  /// The slice's share, written on the ring once the slice is big enough.
  void _percent(
    Canvas canvas,
    Rect rect,
    DonutSlice slice,
    double from,
    double sweep,
  ) {
    final share = slice.value / sum;
    if (share < 0.06) return;
    // Appears as the sweep finishes, so it does not flicker while drawing.
    final fade = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    if (fade <= 0) return;

    final painter = TextPainter(
      text: TextSpan(
        text: '${(share * 100).round()}%',
        style: sans(
          13.5,
          weight: 700,
          color: Colors.white.withValues(alpha: fade),
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();

    final mid = from + sweep / 2;
    final radius = rect.width / 2;
    final center = rect.center + Offset(math.cos(mid), math.sin(mid)) * radius;
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.sum != sum ||
      old.slices != slices ||
      old.textScaler != textScaler ||
      old.track != track;
}
