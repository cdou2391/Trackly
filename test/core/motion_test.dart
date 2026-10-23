import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/motion/motion.dart';

import '../helpers/test_app.dart';

double _opacityOf(WidgetTester tester, Finder child) {
  final fade = tester.widget<FadeTransition>(
    find.ancestor(of: child, matching: find.byType(FadeTransition)).first,
  );
  return fade.opacity.value;
}

Widget _host({required Widget child, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );
}

void main() {
  group('Reveal', () {
    testWidgets('fades in after its turn', (tester) async {
      const text = Text('hello');
      await tester.pumpWidget(
        _host(child: const Reveal(index: 2, child: text)),
      );
      expect(_opacityOf(tester, find.text('hello')), 0);

      // Past the stagger delay and the animation.
      await tester.pump(Motion.stagger * 2 + const Duration(milliseconds: 20));
      await tester.pump(Motion.enter);
      expect(_opacityOf(tester, find.text('hello')), 1);
    });

    testWidgets('a later index waits longer', (tester) async {
      await tester.pumpWidget(
        _host(
          child: const Column(
            children: [
              Reveal(index: 0, child: Text('first')),
              Reveal(index: 5, child: Text('last')),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_opacityOf(tester, find.text('first')), greaterThan(0.3));
      expect(_opacityOf(tester, find.text('last')), 0);

      await tester.pump(Motion.stagger * 5);
      await tester.pump(Motion.enter);
      expect(_opacityOf(tester, find.text('last')), 1);
    });

    testWidgets('shows at once when the system reduces motion', (tester) async {
      await tester.pumpWidget(
        _host(
          reduceMotion: true,
          child: const Reveal(index: 3, child: Text('hello')),
        ),
      );
      expect(_opacityOf(tester, find.text('hello')), 1);
    });

    testWidgets('leaves no timers behind when removed early', (tester) async {
      await tester.pumpWidget(
        _host(child: const Reveal(index: 4, child: Text('x'))),
      );
      await tester.pumpWidget(_host(child: const SizedBox()));
      await tester.pump(Motion.stagger * 6);
      expect(tester.takeException(), isNull);
    });
  });

  group('screens', () {
    tracklyTest('opening an item animates in and then settles', (tester) async {
      await pumpTrackly(
        tester,
        size: const Size(390, 1800),
        items: [testItem('Netflix')],
      );
      await tester.tap(find.text('Netflix').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      // Mid-transition: the page is arriving, not yet fully opaque.
      expect(find.byType(FadeTransition), findsWidgets);

      await settle(tester);
      expect(find.text('Next charge'), findsOneWidget);
      expect(find.text('Mark as paid'), findsOneWidget);
    });
  });
}
