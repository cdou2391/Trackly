import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/trackly_type.dart';
import '../../../../l10n/l10n.dart';

/// One slice of the donut.
class DonutSlice {
  const DonutSlice({required this.color, required this.value});

  final Color color;
  final double value;
}

/// A pie with a hole: each slice is one category's share of the monthly cost,
/// with the total in the middle. It sweeps open when it first appears.
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    required this.slices,
    required this.total,
    required this.semanticsLabel,
    super.key,
  });

  final List<DonutSlice> slices;

  /// The formatted total, shown in the centre.
  final String total;
  final String semanticsLabel;

  static const _size = 184.0;
  static const _thickness = 26.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final sum = slices.fold<double>(0, (a, s) => a + s.value);
    if (sum <= 0) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Center(
        child: SizedBox(
          width: _size,
          height: _size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: motionDuration(context, Motion.countUp),
                curve: Motion.curve,
                builder: (context, progress, _) => CustomPaint(
                  size: const Size(_size, _size),
                  painter: _DonutPainter(
                    slices: slices,
                    sum: sum,
                    progress: progress,
                    thickness: _thickness,
                    track: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_thickness + 10),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        total,
                        style: sans(
                          20,
                          weight: 700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.insightsPerMonth,
                        style: sans(
                          12,
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
  });

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
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.sum != sum ||
      old.slices != slices ||
      old.track != track;
}
