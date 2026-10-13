import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trackly/core/analytics/firebase_analytics_service.dart';
import 'package:trackly/core/error/error_reporter.dart';

class _MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  group('FirebaseAnalyticsService', () {
    late _MockFirebaseAnalytics firebase;

    setUp(() {
      firebase = _MockFirebaseAnalytics();
      when(
        () => firebase.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      when(() => firebase.setAnalyticsCollectionEnabled(any()))
          .thenAnswer((_) async {});
      when(() => firebase.resetAnalyticsData()).thenAnswer((_) async {});
    });

    test('hands nothing to Firebase until it is switched on', () async {
      final service = FirebaseAnalyticsService(firebase);
      await service.logEvent('app_opened');

      verifyNever(
        () => firebase.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    });

    test(
      'passes events on once it is on, and stops when switched off',
      () async {
        final service = FirebaseAnalyticsService(firebase);
        await service.setCollectionEnabled(true);
        await service.logEvent('app_opened', parameters: {'a': 1});
        verify(
          () => firebase.logEvent(name: 'app_opened', parameters: {'a': 1}),
        ).called(1);

        await service.setCollectionEnabled(false);
        await service.logEvent('later');
        verifyNever(
          () => firebase.logEvent(
            name: 'later',
            parameters: any(named: 'parameters'),
          ),
        );
      },
    );

    test('tells Firebase to start and stop collecting', () async {
      final service = FirebaseAnalyticsService(firebase);
      await service.setCollectionEnabled(true);
      await service.setCollectionEnabled(false);

      verifyInOrder([
        () => firebase.setAnalyticsCollectionEnabled(true),
        () => firebase.setAnalyticsCollectionEnabled(false),
      ]);
    });

    test(
      'forgets the installation identifier when going from on to off',
      () async {
        final service = FirebaseAnalyticsService(firebase, enabled: true);
        await service.setCollectionEnabled(false);

        verify(() => firebase.resetAnalyticsData()).called(1);
      },
    );

    test('does not reset anything when it was never on', () async {
      final service = FirebaseAnalyticsService(firebase);
      await service.setCollectionEnabled(false);

      verifyNever(() => firebase.resetAnalyticsData());
    });
  });

  group('SentryErrorReporter', () {
    late int starts;
    late int stops;

    SentryErrorReporter reporter({bool running = false}) => SentryErrorReporter(
      start: () async => starts++,
      stop: () async => stops++,
      running: running,
    );

    setUp(() {
      starts = 0;
      stops = 0;
    });

    test('is not running until it is switched on', () {
      expect(reporter().isRunning, isFalse);
      expect(starts, 0);
    });

    test('starts Sentry once when switched on', () async {
      final r = reporter();
      await r.setEnabled(true);
      await r.setEnabled(true);

      expect(r.isRunning, isTrue);
      expect(starts, 1);
      expect(stops, 0);
    });

    test(
      'stops Sentry when switched off, and only if it was running',
      () async {
        final r = reporter(running: true);
        await r.setEnabled(false);
        await r.setEnabled(false);

        expect(r.isRunning, isFalse);
        expect(stops, 1);
        expect(starts, 0);
      },
    );

    test('can be switched on again after being off', () async {
      final r = reporter(running: true);
      await r.setEnabled(false);
      await r.setEnabled(true);

      expect((starts, stops), (1, 1));
      expect(r.isRunning, isTrue);
    });

    test('while off it captures nothing and does not touch the SDK', () async {
      final r = reporter();
      // Sentry was never started in this test; capturing must be a no-op
      // that does not throw.
      await r.captureException(StateError('x'), StackTrace.current);
      r.addBreadcrumb('step');
    });

    test('a failed start leaves it off and rethrows', () async {
      final r = SentryErrorReporter(
        start: () async => throw StateError('no start'),
        stop: () async {},
      );

      await expectLater(r.setEnabled(true), throwsStateError);
      expect(r.isRunning, isFalse);
    });
  });
}
