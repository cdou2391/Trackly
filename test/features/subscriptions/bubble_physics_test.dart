import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/features/subscriptions/application/bubble_physics.dart';
import 'package:trackly/features/subscriptions/domain/recurring_enums.dart';
import 'package:trackly/features/subscriptions/domain/recurring_item.dart';

final _now = DateTime(2026, 10, 9);

RecurringItem item(String id, double amount, {String currency = 'USD'}) {
  return RecurringItem(
    id: id,
    name: id,
    type: RecurringItemType.subscription,
    amount: amount,
    currencyCode: currency,
    frequency: BillingFrequency.monthly,
    startDate: DateTime(2026, 1, 20),
    nextDueDate: DateTime(2026, 10, 20),
    status: ItemStatus.active,
    createdAt: _now,
    updatedAt: _now,
  );
}

double _distance(Bubble a, Bubble b) =>
    math.sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));

void main() {
  group('bubbleRadii', () {
    test('a costlier item gets a bigger bubble, within the limits', () {
      final radii = bubbleRadii([item('a', 5), item('b', 20), item('c', 80)]);

      expect(radii[0], lessThan(radii[1]));
      expect(radii[1], lessThan(radii[2]));
      expect(radii[2], bubbleMaxRadius);
      expect(radii[0], greaterThanOrEqualTo(bubbleMinRadius));
    });

    test('currencies are compared only with themselves', () {
      final radii = bubbleRadii([
        item('usd', 10),
        item('rwf', 10000, currency: 'RWF'),
      ]);

      // Each is the costliest in its own currency, so each is the largest.
      expect(radii[0], bubbleMaxRadius);
      expect(radii[1], bubbleMaxRadius);
    });

    test('equal costs, or an item alone, get the same size', () {
      final radii = bubbleRadii([item('a', 10), item('b', 10)]);

      expect(radii[0], radii[1]);
      expect(radii[0], bubbleMaxRadius); // all are the costliest
    });

    test('text scaling makes every bubble bigger by the same factor', () {
      final plain = bubbleRadii([item('a', 5), item('b', 50)]);
      final scaled = bubbleRadii([item('a', 5), item('b', 50)], scale: 1.2);

      expect(scaled[0], closeTo(plain[0] * 1.2, 1e-9));
      expect(scaled[1], closeTo(plain[1] * 1.2, 1e-9));
    });

    test('a free item still gets a bubble', () {
      final radii = bubbleRadii([item('free', 0)]);

      expect(radii.single, greaterThan(0));
    });
  });

  group('bubbleFieldHeight', () {
    test('is never less than the screen', () {
      final height = bubbleFieldHeight([40, 40], width: 390, minHeight: 600);

      expect(height, 600);
    });

    test('grows when there are too many bubbles for the screen', () {
      final radii = List.filled(80, 40.0);
      final height = bubbleFieldHeight(radii, width: 390, minHeight: 600);

      expect(height, greaterThan(600));
      // Enough room that the bubbles cover no more than the set share.
      final area = 80 * math.pi * 44 * 44;
      expect(area / (390 * height), lessThanOrEqualTo(bubbleDensity + 1e-9));
    });
  });

  group('BubblePhysics', () {
    BubblePhysics make({int count = 12, int seed = 1}) {
      return BubblePhysics(
        radii: [for (var i = 0; i < count; i++) 30.0 + (i % 5) * 6],
        seed: seed,
      )..resize(const Size(390, 700));
    }

    test('places every bubble inside, without overlap', () {
      final physics = make();

      for (final b in physics.bubbles) {
        expect(b.x, greaterThanOrEqualTo(b.radius));
        expect(b.x, lessThanOrEqualTo(390 - b.radius));
        expect(b.y, greaterThanOrEqualTo(b.radius));
        expect(b.y, lessThanOrEqualTo(700 - b.radius));
      }
      for (var i = 0; i < physics.bubbles.length; i++) {
        for (var j = i + 1; j < physics.bubbles.length; j++) {
          final a = physics.bubbles[i];
          final b = physics.bubbles[j];
          expect(_distance(a, b), greaterThanOrEqualTo(a.radius + b.radius));
        }
      }
    });

    test('keeps them inside and moving for minutes of drifting', () {
      final physics = make();

      // Five minutes at 30 frames a second.
      for (var frame = 0; frame < 9000; frame++) {
        physics.step(1 / 30);
        if (frame % 500 != 0) continue;
        for (final b in physics.bubbles) {
          expect(b.x, inInclusiveRange(b.radius, 390 - b.radius));
          expect(b.y, inInclusiveRange(b.radius, 700 - b.radius));
          final speed = math.sqrt(b.vx * b.vx + b.vy * b.vy);
          expect(speed, greaterThanOrEqualTo(BubblePhysics.minSpeed - 1e-6));
          expect(speed, lessThanOrEqualTo(BubblePhysics.maxSpeed + 1e-6));
        }
      }
    });

    test('bubbles do not pass through each other', () {
      final physics = make(count: 14);

      var worst = 0.0;
      for (var frame = 0; frame < 3000; frame++) {
        physics.step(1 / 30);
        for (var i = 0; i < physics.bubbles.length; i++) {
          for (var j = i + 1; j < physics.bubbles.length; j++) {
            final a = physics.bubbles[i];
            final b = physics.bubbles[j];
            worst = math.max(worst, a.radius + b.radius - _distance(a, b));
          }
        }
      }

      // A pixel or two of give is fine; sinking into each other is not.
      expect(worst, lessThan(3));
    });

    test('two bubbles heading at each other bounce apart', () {
      final physics = BubblePhysics(radii: [30, 30])
        ..resize(const Size(600, 300));
      final a = physics.bubbles[0]
        ..x = 200
        ..y = 150
        ..vx = 20
        ..vy = 0;
      final b = physics.bubbles[1]
        ..x = 200 + 30 + 30 + bubbleGap + 1
        ..y = 150
        ..vx = -20
        ..vy = 0;

      physics.step(0.05);

      expect(a.vx, lessThan(0));
      expect(b.vx, greaterThan(0));
    });

    test('a heavy bubble hardly moves when a light one hits it', () {
      final physics = BubblePhysics(radii: [54, 30])
        ..resize(const Size(600, 300));
      final heavy = physics.bubbles[0]
        ..x = 200
        ..y = 150
        ..vx = 0
        ..vy = 0;
      final light = physics.bubbles[1]
        ..x = 200 + 54 + 30 + bubbleGap - 1
        ..y = 150
        ..vx = -20
        ..vy = 0;

      physics.step(0.05);

      expect(light.vx, greaterThan(0)); // bounced back
      expect(heavy.vx.abs(), lessThan(light.vx.abs()));
    });

    test('the same seed gives the same layout, another seed another', () {
      final a = make(seed: 7);
      final b = make(seed: 7);
      final c = make(seed: 8);

      expect(
        [for (final bubble in a.bubbles) bubble.x],
        [for (final bubble in b.bubbles) bubble.x],
      );
      expect([
        for (final bubble in a.bubbles) bubble.x,
      ], isNot([for (final bubble in c.bubbles) bubble.x]));
    });

    test('a long pause does not fling anything', () {
      final physics = make();
      final before = [for (final b in physics.bubbles) b.x];

      physics.step(60); // a minute with the app asleep

      for (var i = 0; i < before.length; i++) {
        final moved = (physics.bubbles[i].x - before[i]).abs();
        expect(moved, lessThan(BubblePhysics.maxSpeed * 0.05 + 10));
      }
    });

    test('shrinking the field keeps every bubble inside', () {
      final physics = make()..resize(const Size(300, 500));

      for (final b in physics.bubbles) {
        expect(b.x, inInclusiveRange(b.radius, 300 - b.radius));
        expect(b.y, inInclusiveRange(b.radius, 500 - b.radius));
      }
    });

    test('with nothing to move, stepping does nothing', () {
      final empty = BubblePhysics(radii: const [])
        ..resize(const Size(100, 100));
      expect(() => empty.step(0.03), returnsNormally);

      final unsized = BubblePhysics(radii: [30]);
      expect(() => unsized.step(0.03), returnsNormally);
    });
  });
}
