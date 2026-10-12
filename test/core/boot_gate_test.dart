import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/startup/boot_gate.dart';
import 'package:trackly/core/startup/splash_screen.dart';

import '../helpers/test_app.dart';

const _minimum = Duration(milliseconds: 1000);
const _tagline = 'Know what’s charging next.';

/// The app the gate hands over to.
Widget _readyApp() => const MaterialApp(home: Text('READY'));

/// Lets the logo asset load (real time), then advances the test clock.
Future<void> _pump(WidgetTester tester, Duration time) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pump(time);
}

/// Stops the animations and timers so the test can end.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 2));
}

Widget _gate(
  Future<Widget> Function() bootstrap, {
  void Function(Object, StackTrace)? onError,
}) =>
    BootGate(bootstrap: bootstrap, minimumDisplay: _minimum, onError: onError);

void main() {
  testWidgets('the logo file is a real SVG', (tester) async {
    final svg = await rootBundle.loadString(SplashScreen.logoAsset);
    expect(svg, contains('<svg'));
    expect(svg, contains('viewBox'));
  });

  group('while starting', () {
    testWidgets('shows the logo, the name and the tagline', (tester) async {
      await loadTracklyFonts(tester);
      final started = Completer<Widget>();
      await tester.pumpWidget(_gate(() => started.future));
      await _pump(tester, const Duration(milliseconds: 900));

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('Trackly'), findsOneWidget);
      expect(find.text(_tagline), findsOneWidget);
      expect(find.text('READY'), findsNothing);

      started.complete(_readyApp());
      await _pump(tester, _minimum + const Duration(seconds: 1));
      await _finish(tester);
    });

    testWidgets('the logo is big', (tester) async {
      await loadTracklyFonts(tester);
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final started = Completer<Widget>();
      await tester.pumpWidget(_gate(() => started.future));
      await _pump(tester, const Duration(milliseconds: 900));

      // About half the screen width on a phone.
      final logo = tester.getSize(find.byType(SvgPicture));
      expect(logo.width, greaterThan(180));
      expect(logo.width, lessThanOrEqualTo(260));

      started.complete(_readyApp());
      await _pump(tester, _minimum + const Duration(seconds: 1));
      await _finish(tester);
    });

    testWidgets('announces that it is loading', (tester) async {
      await loadTracklyFonts(tester);
      final semantics = tester.ensureSemantics();
      final started = Completer<Widget>();
      await tester.pumpWidget(_gate(() => started.future));
      await _pump(tester, const Duration(milliseconds: 900));

      expect(find.bySemanticsLabel('Loading Trackly'), findsOneWidget);

      started.complete(_readyApp());
      await _pump(tester, _minimum + const Duration(seconds: 1));
      await _finish(tester);
      semantics.dispose();
    });
  });

  group('handing over to the app', () {
    testWidgets('a fast start still shows the splash for the minimum time', (
      tester,
    ) async {
      await loadTracklyFonts(tester);
      await tester.pumpWidget(_gate(() async => _readyApp()));
      await _pump(tester, const Duration(milliseconds: 500));

      expect(find.text(_tagline), findsOneWidget);
      expect(find.text('READY'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600)); // past the minimum
      await tester.pump(const Duration(milliseconds: 400)); // cross-fade
      expect(find.text('READY'), findsOneWidget);
      expect(find.text(_tagline), findsNothing);
      await _finish(tester);
    });

    testWidgets('a slow start keeps the splash until it finishes', (
      tester,
    ) async {
      await loadTracklyFonts(tester);
      final started = Completer<Widget>();
      await tester.pumpWidget(_gate(() => started.future));
      await _pump(tester, const Duration(seconds: 5));

      expect(find.text(_tagline), findsOneWidget);
      expect(find.text('READY'), findsNothing);

      started.complete(_readyApp());
      await tester.pump(); // let the future complete
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('READY'), findsOneWidget);
      await _finish(tester);
    });
  });

  group('when starting fails', () {
    testWidgets('says so, reports it, and Try again recovers', (tester) async {
      await loadTracklyFonts(tester);
      var attempts = 0;
      final errors = <Object>[];
      await tester.pumpWidget(
        _gate(() async {
          attempts++;
          if (attempts == 1) throw StateError('database would not open');
          return _readyApp();
        }, onError: (error, _) => errors.add(error)),
      );
      await _pump(tester, const Duration(milliseconds: 1200));

      expect(find.text('Couldn’t start Trackly'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text(_tagline), findsOneWidget); // still branded
      expect(errors.single, isA<StateError>());
      expect(find.text('READY'), findsNothing);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await _pump(tester, _minimum + const Duration(milliseconds: 500));

      expect(attempts, 2);
      expect(find.text('READY'), findsOneWidget);
      await _finish(tester);
    });
  });

  group('layout and motion', () {
    testWidgets('with animations off it is drawn at once and still', (
      tester,
    ) async {
      await loadTracklyFonts(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      final started = Completer<Widget>();
      await tester.pumpWidget(_gate(() => started.future));
      await _pump(tester, const Duration(milliseconds: 16));

      // The logo and the words are fully visible at once (the loader dots are
      // drawn still and slightly dim), and nothing keeps animating.
      double opacityOf(Finder inside) => tester
          .widget<Opacity>(
            find.ancestor(of: inside, matching: find.byType(Opacity)).first,
          )
          .opacity;
      expect(opacityOf(find.byType(SvgPicture)), 1.0);
      expect(opacityOf(find.text(_tagline)), 1.0);
      expect(tester.hasRunningAnimations, isFalse);

      started.complete(_readyApp());
      await _pump(tester, _minimum + const Duration(seconds: 1));
      await _finish(tester);
    });

    for (final failing in [false, true]) {
      testWidgets(
        'fits a small screen with large text${failing ? ' (error state)' : ''}',
        (tester) async {
          await loadTracklyFonts(tester);
          tester.view.physicalSize = const Size(320, 568) * 2;
          tester.view.devicePixelRatio = 2;
          tester.platformDispatcher.textScaleFactorTestValue = 1.6;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          final started = Completer<Widget>();
          await tester.pumpWidget(
            _gate(() => failing ? throw StateError('x') : started.future),
          );
          await _pump(tester, const Duration(milliseconds: 1200));

          expect(tester.takeException(), isNull);
          expect(find.text('Trackly'), findsOneWidget);
          if (!started.isCompleted) started.complete(_readyApp());
          await _pump(tester, _minimum + const Duration(seconds: 1));
          await _finish(tester);
        },
      );
    }
  });
}
