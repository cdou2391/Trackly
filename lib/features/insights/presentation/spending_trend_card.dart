import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/error/error_reporter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/spending_trend.dart';

/// What each of the last 3, 6 or 12 months cost: a smooth line per currency,
/// with the peak and the current month labelled. Tap or drag along the line to
/// read any month.
class SpendingTrendSection extends ConsumerWidget {
  const SpendingTrendSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final trend = ref.watch(spendingTrendProvider);
    final months = ref.watch(trendRangeProvider);

    return trend.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) {
        ref.read(errorReporterProvider).captureException(error, stackTrace);
        return const SizedBox.shrink();
      },
      data: (data) {
        final currencies = data.chartableCurrencies;
        final theme = Theme.of(context);
        final tokens = context.tokens;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: TracklySpacing.sm,
              children: [
                SectionHeader(title: l10n.insightsTrend),
                if (currencies.isNotEmpty)
                  SegmentedButton<int>(
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    segments: [
                      for (final range in trendRanges)
                        ButtonSegment(
                          value: range,
                          label: Text(_rangeLabel(l10n, range)),
                          tooltip: l10n.insightsTrendLast(range),
                        ),
                    ],
                    selected: {months},
                    onSelectionChanged: (value) =>
                        ref.read(trendRangeProvider.notifier).set(value.single),
                  ),
              ],
            ),
            const SizedBox(height: TracklySpacing.sm),
            if (currencies.isEmpty)
              Text(
                l10n.insightsTrendEmpty,
                style: sans(14, color: theme.colorScheme.onSurfaceVariant),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(TracklyRadius.medium),
                  border: Border.all(color: tokens.cardBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TracklySpacing.sm,
                    TracklySpacing.base,
                    TracklySpacing.sm,
                    TracklySpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (index, currency) in currencies.indexed) ...[
                        if (index > 0)
                          const SizedBox(height: TracklySpacing.base),
                        if (currencies.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: TracklySpacing.sm,
                              bottom: TracklySpacing.xs,
                            ),
                            child: Text(
                              currency,
                              style: sans(
                                13,
                                weight: 600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        TrendChart(
                          key: ValueKey('trend-$currency-$months'),
                          points: data.byCurrency[currency]!,
                          currency: currency,
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TracklySpacing.sm,
                          TracklySpacing.sm,
                          TracklySpacing.sm,
                          0,
                        ),
                        child: Text(
                          l10n.insightsTrendNote,
                          style: sans(
                            12.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

String _rangeLabel(AppLocalizations l10n, int months) => switch (months) {
  3 => l10n.insightsTrendRange3,
  6 => l10n.insightsTrendRange6,
  _ => l10n.insightsTrendRange12,
};

/// One line chart. Stateful only for the month the person has tapped.
class TrendChart extends StatefulWidget {
  const TrendChart({required this.points, required this.currency, super.key});

  final List<TrendPoint> points;
  final String currency;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  static const _height = 176.0;

  int? _selected;

  void _select(Offset local, double width) {
    final count = widget.points.length;
    if (count == 0) return;
    final layout = _TrendLayout(Size(width, _height), count);
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < count; i++) {
      final distance = (layout.x(i) - local.dx).abs();
      if (distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    if (best != _selected) setState(() => _selected = best);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toString();
    final monthFormat = DateFormat.MMM(locale);

    final summary = l10n.insightsTrendSemantics(
      widget.points.length,
      [
        for (final p in widget.points)
          '${monthFormat.format(p.month)} '
              '${formatMoney(p.amount, widget.currency, locale: locale)}',
      ].join(', '),
    );

    return Semantics(
      container: true,
      label: summary,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition, width),
            onHorizontalDragStart: (d) => _select(d.localPosition, width),
            onHorizontalDragUpdate: (d) => _select(d.localPosition, width),
            child: SizedBox(
              height: _height,
              width: width,
              child: CustomPaint(
                painter: _TrendPainter(
                  points: widget.points,
                  currency: widget.currency,
                  selected: _selected,
                  locale: locale,
                  line: tokens.accent,
                  surface: theme.colorScheme.surface,
                  ink: theme.colorScheme.onSurface,
                  mutedInk: theme.colorScheme.onSurfaceVariant,
                  baseline: tokens.cardBorder,
                  textScaler: MediaQuery.textScalerOf(context)
                      .clamp(maxScaleFactor: 1.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Where the chart's parts sit inside its box.
class _TrendLayout {
  _TrendLayout(this.size, this.count);

  final Size size;
  final int count;

  static const left = 18.0;
  static const right = 18.0;
  static const top = 30.0;
  static const bottom = 26.0;

  double get plotWidth => math.max(1, size.width - left - right);
  double get plotHeight => math.max(1, size.height - top - bottom);
  double get floor => size.height - bottom;

  double x(int i) =>
      count == 1 ? size.width / 2 : left + plotWidth * i / (count - 1);

  double y(double amount, double max) =>
      floor - (max <= 0 ? 0 : amount / max) * plotHeight;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.currency,
    required this.selected,
    required this.locale,
    required this.line,
    required this.surface,
    required this.ink,
    required this.mutedInk,
    required this.baseline,
    required this.textScaler,
  });

  final List<TrendPoint> points;
  final String currency;
  final int? selected;
  final String locale;
  final Color line;
  final Color surface;
  final Color ink;
  final Color mutedInk;
  final Color baseline;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    final count = points.length;
    if (count == 0) return;

    final layout = _TrendLayout(size, count);
    final max = points.map((p) => p.amount).fold<double>(0, math.max);
    final offsets = [
      for (var i = 0; i < count; i++)
        Offset(layout.x(i), layout.y(points[i].amount, max)),
    ];

    // The only grid line: the floor the line rests on.
    canvas.drawLine(
      Offset(_TrendLayout.left / 2, layout.floor),
      Offset(size.width - _TrendLayout.right / 2, layout.floor),
      Paint()
        ..color = baseline
        ..strokeWidth = 1,
    );

    if (count > 1) {
      final curve = _smoothPath(offsets);

      final area = Path.from(curve)
        ..lineTo(offsets.last.dx, layout.floor)
        ..lineTo(offsets.first.dx, layout.floor)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.22), line.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, layout.floor)),
      );

      canvas.drawPath(
        curve,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Markers: 8 dp across, 10 for the current month and 12 for the chosen
    // one, each with a surface ring so it stands off the line.
    for (var i = 0; i < count; i++) {
      final isLast = i == count - 1;
      final radius = i == selected ? 6.0 : (isLast ? 5.0 : 4.0);
      canvas.drawCircle(offsets[i], radius + 2, Paint()..color = surface);
      canvas.drawCircle(offsets[i], radius, Paint()..color = line);
    }

    _paintValueLabels(canvas, size, layout, offsets);
    _paintMonthLabels(canvas, size, layout);
  }

  /// Which points carry their amount: the chosen month alone, otherwise the
  /// peak and the current month (every point when there are three or fewer).
  List<int> _labelled() {
    if (selected != null) return [selected!];
    final count = points.length;
    if (count <= 3) return [for (var i = 0; i < count; i++) i];
    var peak = 0;
    for (var i = 1; i < count; i++) {
      if (points[i].amount > points[peak].amount) peak = i;
    }
    return {peak, count - 1}.toList()..sort();
  }

  void _paintValueLabels(
    Canvas canvas,
    Size size,
    _TrendLayout layout,
    List<Offset> offsets,
  ) {
    final taken = <Rect>[];
    for (final i in _labelled()) {
      final painter = _text(
        formatMoney(points[i].amount, currency, locale: locale),
        12.5,
        weight: FontWeight.w700,
        color: ink,
      );
      var dx = offsets[i].dx - painter.width / 2;
      dx = dx.clamp(2.0, math.max(2.0, size.width - painter.width - 2));
      final dy = offsets[i].dy - 16 - painter.height;
      final rect = Rect.fromLTWH(dx, dy, painter.width, painter.height);
      if (i != selected && taken.any((r) => r.inflate(4).overlaps(rect))) {
        continue;
      }
      taken.add(rect);
      painter.paint(canvas, rect.topLeft);
    }
  }

  void _paintMonthLabels(Canvas canvas, Size size, _TrendLayout layout) {
    final format = DateFormat.MMM(locale);
    final count = points.length;
    final painters = [
      for (var i = 0; i < count; i++)
        _text(
          format.format(points[i].month),
          12,
          color: i == count - 1 || i == selected ? ink : mutedInk,
          weight: i == count - 1 || i == selected
              ? FontWeight.w600
              : FontWeight.w400,
        ),
    ];

    // Drop alternate months when they would touch (a year of months at a
    // large text size), always keeping the current one.
    final widest = painters.map((p) => p.width).fold<double>(0, math.max);
    final spacing = count > 1 ? layout.plotWidth / (count - 1) : size.width;
    final step = math.max(1, ((widest + 8) / spacing).ceil());

    for (var i = 0; i < count; i++) {
      final fromEnd = count - 1 - i;
      if (fromEnd % step != 0 && i != selected) continue;
      final painter = painters[i];
      var dx = layout.x(i) - painter.width / 2;
      dx = dx.clamp(0.0, math.max(0.0, size.width - painter.width));
      painter.paint(canvas, Offset(dx, layout.floor + 8));
    }
  }

  TextPainter _text(
    String text,
    double fontSize, {
    required Color color,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: sans(fontSize, weight: weight.value, color: color),
      ),
      textDirection: ui.TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
  }

  /// A smooth curve through [p] that never overshoots a point: the line does
  /// not dip below the floor between two small months or rise above a peak.
  Path _smoothPath(List<Offset> p) {
    final n = p.length;
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    if (n == 2) return path..lineTo(p[1].dx, p[1].dy);

    final dx = [for (var i = 0; i < n - 1; i++) p[i + 1].dx - p[i].dx];
    final slope = [
      for (var i = 0; i < n - 1; i++) (p[i + 1].dy - p[i].dy) / dx[i],
    ];

    // Tangent at each point: the mean of the neighbouring slopes, zero at a
    // turning point, then limited so no segment overshoots (Fritsch-Carlson).
    final m = List<double>.filled(n, 0);
    m[0] = slope[0];
    m[n - 1] = slope[n - 2];
    for (var i = 1; i < n - 1; i++) {
      m[i] = slope[i - 1] * slope[i] <= 0 ? 0 : (slope[i - 1] + slope[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (slope[i] == 0) {
        m[i] = 0;
        m[i + 1] = 0;
        continue;
      }
      final a = m[i] / slope[i];
      final b = m[i + 1] / slope[i];
      final sum = a * a + b * b;
      if (sum > 9) {
        final tau = 3 / math.sqrt(sum);
        m[i] = tau * a * slope[i];
        m[i + 1] = tau * b * slope[i];
      }
    }

    for (var i = 0; i < n - 1; i++) {
      final third = dx[i] / 3;
      path.cubicTo(
        p[i].dx + third,
        p[i].dy + m[i] * third,
        p[i + 1].dx - third,
        p[i + 1].dy - m[i + 1] * third,
        p[i + 1].dx,
        p[i + 1].dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.points != points ||
      old.selected != selected ||
      old.line != line ||
      old.surface != surface ||
      old.ink != ink ||
      old.mutedInk != mutedInk ||
      old.textScaler != textScaler ||
      old.locale != locale ||
      old.currency != currency;
}
