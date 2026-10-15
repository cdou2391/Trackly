import 'dart:math' as math;
import 'dart:ui';

import '../../../core/utils/cost_utils.dart';
import '../domain/recurring_item.dart';

/// The smallest and largest bubble radius, in dp. The smallest is still a
/// comfortable touch target (a 60 dp circle).
const bubbleMinRadius = 30.0;
const bubbleMaxRadius = 54.0;

/// How much of the field the bubbles may cover, so they have room to drift.
const bubbleDensity = 0.40;

/// The gap kept between two bubbles, in dp.
const bubbleGap = 4.0;

/// A radius for each of [items]: bigger for a costlier item, compared only
/// with items in the same currency (10,000 RWF and 10 USD say nothing about
/// each other). The area, not the width, grows with the cost, so a bubble twice
/// as costly looks about twice as big. Several items of the same cost, or a
/// currency with one item, get a middle size.
List<double> bubbleRadii(List<RecurringItem> items, {double scale = 1}) {
  final maxByCurrency = <String, double>{};
  final monthly = [for (final item in items) calculateMonthlyEquivalent(item)];
  for (var i = 0; i < items.length; i++) {
    final code = items[i].currencyCode;
    maxByCurrency[code] = math.max(maxByCurrency[code] ?? 0, monthly[i]);
  }

  const mid = (bubbleMinRadius + bubbleMaxRadius) / 2;
  return [
    for (var i = 0; i < items.length; i++)
      scale *
          switch (maxByCurrency[items[i].currencyCode]!) {
            final max when max <= 0 => mid,
            final max =>
              bubbleMinRadius +
                  (bubbleMaxRadius - bubbleMinRadius) *
                      math.sqrt((monthly[i] / max).clamp(0.0, 1.0)),
          },
  ];
}

/// The height a field [width] dp wide needs to hold bubbles of [radii] without
/// crowding, never less than [minHeight]. A screen with many items scrolls.
double bubbleFieldHeight(
  List<double> radii, {
  required double width,
  required double minHeight,
}) {
  var area = 0.0;
  for (final r in radii) {
    final d = r + bubbleGap;
    area += math.pi * d * d;
  }
  final needed = width <= 0 ? 0.0 : area / bubbleDensity / width;
  return math.max(minHeight, needed);
}

/// One circle: where it is, how fast it moves, how big it is.
class Bubble {
  Bubble({required this.radius});

  final double radius;
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;

  double get mass => radius * radius;
}

/// Circles drifting around a rectangle: they bounce off its edges and off each
/// other, and never stop. Pure maths with no widgets, so it is easy to test.
///
/// The same [seed] gives the same starting layout and directions, so the
/// screen opens the same way each time for the same items.
class BubblePhysics {
  BubblePhysics({required List<double> radii, int seed = 0})
    : bubbles = [for (final r in radii) Bubble(radius: r)],
      _random = math.Random(seed);

  final List<Bubble> bubbles;
  final math.Random _random;
  Size _size = Size.zero;

  /// Slowest and fastest a bubble moves, in dp per second. Slow enough to
  /// read and tap, fast enough to look alive.
  static const minSpeed = 9.0;
  static const maxSpeed = 24.0;

  Size get size => _size;

  /// Sets the rectangle. The first call places the bubbles without
  /// overlapping and gives each a direction; later calls keep them inside.
  void resize(Size size) {
    final first = _size == Size.zero;
    _size = size;
    if (first) {
      _place();
    } else {
      for (final b in bubbles) {
        _keepInside(b);
      }
    }
  }

  void _place() {
    final placed = <Bubble>[];
    // Biggest first: they are the hardest to fit.
    final order = [...bubbles]..sort((a, b) => b.radius.compareTo(a.radius));
    for (final b in order) {
      var bestX = b.radius;
      var bestY = b.radius;
      var bestOverlap = double.infinity;
      for (var attempt = 0; attempt < 240; attempt++) {
        final x = _between(b.radius, _size.width - b.radius);
        final y = _between(b.radius, _size.height - b.radius);
        final overlap = _overlapAt(placed, x, y, b.radius);
        if (overlap < bestOverlap) {
          bestOverlap = overlap;
          bestX = x;
          bestY = y;
          if (overlap == 0) break;
        }
      }
      b
        ..x = bestX
        ..y = bestY;
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = minSpeed + _random.nextDouble() * (maxSpeed - minSpeed) / 2;
      b
        ..vx = math.cos(angle) * speed
        ..vy = math.sin(angle) * speed;
      placed.add(b);
    }
    // A last pass for any bubble left touching another.
    for (var i = 0; i < 12; i++) {
      _collide(bounce: false);
    }
  }

  double _between(double low, double high) =>
      high <= low ? low : low + _random.nextDouble() * (high - low);

  double _overlapAt(List<Bubble> others, double x, double y, double r) {
    var total = 0.0;
    for (final o in others) {
      final gap = math.sqrt((o.x - x) * (o.x - x) + (o.y - y) * (o.y - y));
      final over = o.radius + r + bubbleGap - gap;
      if (over > 0) total += over;
    }
    return total;
  }

  void _keepInside(Bubble b) {
    b
      ..x = b.x.clamp(b.radius, math.max(b.radius, _size.width - b.radius))
      ..y = b.y.clamp(b.radius, math.max(b.radius, _size.height - b.radius));
  }

  /// Moves every bubble on by [dt] seconds.
  void step(double dt) {
    if (_size == Size.zero || bubbles.isEmpty) return;
    // A long pause (a slow frame, a resumed app) must not fling bubbles.
    final t = dt.clamp(0.0, 0.05);

    for (final b in bubbles) {
      b
        ..x += b.vx * t
        ..y += b.vy * t;
      if (b.x < b.radius) {
        b
          ..x = b.radius
          ..vx = b.vx.abs();
      } else if (b.x > _size.width - b.radius) {
        b
          ..x = math.max(b.radius, _size.width - b.radius)
          ..vx = -b.vx.abs();
      }
      if (b.y < b.radius) {
        b
          ..y = b.radius
          ..vy = b.vy.abs();
      } else if (b.y > _size.height - b.radius) {
        b
          ..y = math.max(b.radius, _size.height - b.radius)
          ..vy = -b.vy.abs();
      }
    }

    _collide(bounce: true);

    for (final b in bubbles) {
      _regulateSpeed(b);
    }
  }

  /// Pushes overlapping bubbles apart. With [bounce] they also trade momentum
  /// like billiard balls (heavier ones move less).
  void _collide({required bool bounce}) {
    for (var i = 0; i < bubbles.length; i++) {
      for (var j = i + 1; j < bubbles.length; j++) {
        final a = bubbles[i];
        final c = bubbles[j];
        var dx = c.x - a.x;
        var dy = c.y - a.y;
        var dist = math.sqrt(dx * dx + dy * dy);
        final minDist = a.radius + c.radius + bubbleGap;
        if (dist >= minDist) continue;

        if (dist < 1e-6) {
          // Exactly on top of each other: pick any direction to separate.
          dx = 1;
          dy = 0;
          dist = 1;
        }
        final nx = dx / dist;
        final ny = dy / dist;
        final overlap = minDist - dist;

        final total = a.mass + c.mass;
        final aShare = c.mass / total;
        final cShare = a.mass / total;
        a
          ..x -= nx * overlap * aShare
          ..y -= ny * overlap * aShare;
        c
          ..x += nx * overlap * cShare
          ..y += ny * overlap * cShare;
        _keepInside(a);
        _keepInside(c);

        if (!bounce) continue;
        final approach = (a.vx - c.vx) * nx + (a.vy - c.vy) * ny;
        if (approach <= 0) continue; // already moving apart
        final impulse = 2 * approach / (1 / a.mass + 1 / c.mass);
        a
          ..vx -= impulse / a.mass * nx
          ..vy -= impulse / a.mass * ny;
        c
          ..vx += impulse / c.mass * nx
          ..vy += impulse / c.mass * ny;
      }
    }
  }

  void _regulateSpeed(Bubble b) {
    final speed = math.sqrt(b.vx * b.vx + b.vy * b.vy);
    if (speed < 1e-6) {
      final angle = _random.nextDouble() * 2 * math.pi;
      b
        ..vx = math.cos(angle) * minSpeed
        ..vy = math.sin(angle) * minSpeed;
    } else if (speed < minSpeed) {
      final k = minSpeed / speed;
      b
        ..vx *= k
        ..vy *= k;
    } else if (speed > maxSpeed) {
      final k = maxSpeed / speed;
      b
        ..vx *= k
        ..vy *= k;
    }
  }
}
