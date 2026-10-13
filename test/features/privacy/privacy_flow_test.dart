import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/config/app_links.dart';
import 'package:trackly/features/settings/application/settings_store.dart';

import '../../helpers/privacy_fakes.dart';
import '../../helpers/test_app.dart';

const _tall = Size(390, 1400);

Finder get _allow => find.byKey(const Key('privacy-allow'));
Finder get _decline => find.byKey(const Key('privacy-decline'));
Finder get _homeContent => find.byKey(const Key('quick-add-name'));

Future<void> _openSettings(WidgetTester tester) async {
  await tester.tap(find.text('More').last);
  await settle(tester);
  await tester.tap(find.text('Settings'));
  await settle(tester);
}

Switch _switch(WidgetTester tester, String key) => tester.widget<Switch>(
  find.descendant(of: find.byKey(Key(key)), matching: find.byType(Switch)),
);

void main() {
  group('first launch', () {
    tracklyTest('asks before showing the app, and says what is sent', (
      tester,
    ) async {
      await pumpTrackly(tester, size: _tall, showPrivacyChoice: true);

      expect(find.text('Help improve Trackly'), findsOneWidget);
      expect(find.text('Usage statistics'), findsOneWidget);
      expect(find.text('Error reports'), findsOneWidget);
      expect(
        find.textContaining('Nothing is sent unless you allow it'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Never names, amounts or notes'),
        findsOneWidget,
      );
      expect(
        _homeContent,
        findsNothing,
        reason: 'the app waits for the choice',
      );
    });

    tracklyTest('nothing is switched on while the question is open', (
      tester,
    ) async {
      final analytics = FakeAnalytics();
      final errors = FakeErrorReporter();
      final store = InMemorySettingsStore();
      await pumpTrackly(
        tester,
        size: _tall,
        showPrivacyChoice: true,
        settings: store,
        analytics: analytics,
        errorReporter: errors,
      );

      expect(analytics.switches, isEmpty);
      expect(errors.switches, isEmpty);
      expect(store.usageStatsEnabled, isNull);
      expect(store.errorReportsEnabled, isNull);
    });

    tracklyTest('Share anonymous data turns both on and opens the app', (
      tester,
    ) async {
      final analytics = FakeAnalytics();
      final errors = FakeErrorReporter();
      final store = InMemorySettingsStore();
      await pumpTrackly(
        tester,
        size: _tall,
        showPrivacyChoice: true,
        settings: store,
        analytics: analytics,
        errorReporter: errors,
      );

      await tester.tap(_allow);
      await settle(tester);

      expect(find.text('Help improve Trackly'), findsNothing);
      expect(_homeContent, findsOneWidget);
      expect(store.usageStatsEnabled, isTrue);
      expect(store.errorReportsEnabled, isTrue);
      expect(analytics.switches, [true]);
      expect(errors.switches, [true]);
    });

    tracklyTest('Don\'t share keeps everything off and opens the app', (
      tester,
    ) async {
      final analytics = FakeAnalytics();
      final errors = FakeErrorReporter();
      final store = InMemorySettingsStore();
      await pumpTrackly(
        tester,
        size: _tall,
        showPrivacyChoice: true,
        settings: store,
        analytics: analytics,
        errorReporter: errors,
      );

      await tester.tap(_decline);
      await settle(tester);

      expect(find.text('Help improve Trackly'), findsNothing);
      expect(_homeContent, findsOneWidget);
      expect(store.usageStatsEnabled, isFalse);
      expect(store.errorReportsEnabled, isFalse);
      expect(analytics.switches, [false]);
      expect(errors.switches, [false]);
    });

    tracklyTest('yes and no are the same size and style', (tester) async {
      await pumpTrackly(tester, size: _tall, showPrivacyChoice: true);

      expect(tester.getSize(_allow), tester.getSize(_decline));
      expect(
        tester.widget(_allow).runtimeType,
        tester.widget(_decline).runtimeType,
      );
    });

    tracklyTest('the privacy policy can be read from the question', (
      tester,
    ) async {
      final opener = FakeLinkOpener();
      await pumpTrackly(
        tester,
        size: _tall,
        showPrivacyChoice: true,
        linkOpener: opener,
      );

      await tester.tap(find.text('Read the privacy policy'));
      await settle(tester);

      expect(opener.opened, [AppLinks.privacyPolicyUri]);
      expect(find.text('Help improve Trackly'), findsOneWidget);
    });

    tracklyTest('is not asked again once answered', (tester) async {
      final store = InMemorySettingsStore();
      await store.setUsageStatsEnabled(true);
      await store.setErrorReportsEnabled(false);
      await pumpTrackly(
        tester,
        size: _tall,
        showPrivacyChoice: true,
        settings: store,
      );

      expect(find.text('Help improve Trackly'), findsNothing);
      expect(_homeContent, findsOneWidget);
    });
  });

  group('Settings', () {
    tracklyTest('shows the choices as switches', (tester) async {
      final store = InMemorySettingsStore();
      await store.setUsageStatsEnabled(true);
      await store.setErrorReportsEnabled(false);
      await pumpTrackly(tester, size: _tall, settings: store);
      await _openSettings(tester);

      expect(find.text('Privacy'), findsOneWidget);
      expect(_switch(tester, 'settings-usage-stats').value, isTrue);
      expect(_switch(tester, 'settings-error-reports').value, isFalse);
      expect(find.text('Nothing is sent while these are off.'), findsOneWidget);
    });

    tracklyTest('turning usage statistics off stops them at once', (
      tester,
    ) async {
      final analytics = FakeAnalytics();
      final store = InMemorySettingsStore();
      await store.setUsageStatsEnabled(true);
      await store.setErrorReportsEnabled(true);
      await pumpTrackly(
        tester,
        size: _tall,
        settings: store,
        analytics: analytics,
      );
      await _openSettings(tester);

      await tester.tap(find.byKey(const Key('settings-usage-stats')));
      await settle(tester);

      expect(_switch(tester, 'settings-usage-stats').value, isFalse);
      expect(_switch(tester, 'settings-error-reports').value, isTrue);
      expect(store.usageStatsEnabled, isFalse);
      expect(analytics.switches, [false]);
    });

    tracklyTest('error reports can be switched off and back on', (
      tester,
    ) async {
      final errors = FakeErrorReporter();
      final store = InMemorySettingsStore();
      await store.setUsageStatsEnabled(false);
      await store.setErrorReportsEnabled(true);
      await pumpTrackly(
        tester,
        size: _tall,
        settings: store,
        errorReporter: errors,
      );
      await _openSettings(tester);

      await tester.tap(find.byKey(const Key('settings-error-reports')));
      await settle(tester);
      expect(store.errorReportsEnabled, isFalse);

      await tester.tap(find.byKey(const Key('settings-error-reports')));
      await settle(tester);
      expect(store.errorReportsEnabled, isTrue);
      expect(errors.switches, [false, true]);
    });

    tracklyTest('Delete all data keeps the privacy choices', (tester) async {
      final store = InMemorySettingsStore();
      await store.setUsageStatsEnabled(false);
      await store.setErrorReportsEnabled(true);
      await pumpTrackly(
        tester,
        size: _tall,
        settings: store,
        items: [testItem('Netflix')],
      );
      await _openSettings(tester);

      await tester.tap(find.text('Delete all data'));
      await settle(tester);
      await tester.tap(find.text('Delete everything'));
      await settle(tester);

      expect(find.text('Help improve Trackly'), findsNothing);
      expect(store.usageStatsEnabled, isFalse);
      expect(store.errorReportsEnabled, isTrue);
      expect(_switch(tester, 'settings-usage-stats').value, isFalse);
      expect(_switch(tester, 'settings-error-reports').value, isTrue);
    });
  });

  group('layout', () {
    for (final (size, scale) in [
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 1.6),
      (const Size(390, 844), 2.0),
    ]) {
      tracklyTest('first-run screen fits at ${size.width}dp, ${scale}x text', (
        tester,
      ) async {
        await pumpTrackly(
          tester,
          size: size,
          textScale: scale,
          showPrivacyChoice: true,
        );

        expect(tester.takeException(), isNull);
        // Both answers stay on screen whatever the text size.
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(
          tester.getBottomLeft(_decline).dy,
          lessThanOrEqualTo(screen.height),
        );
        expect(tester.getTopLeft(_allow).dy, greaterThanOrEqualTo(0));
      });
    }

    tracklyTest('Settings privacy section fits at 320dp, 1.6x text', (
      tester,
    ) async {
      await pumpTrackly(tester, size: const Size(320, 640), textScale: 1.6);
      await _openSettings(tester);
      await tester.scrollUntilVisible(
        find.text('Usage statistics'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Usage statistics'), findsOneWidget);
      expect(find.text('Error reports'), findsOneWidget);
    });
  });
}
