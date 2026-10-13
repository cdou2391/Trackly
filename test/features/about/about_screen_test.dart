import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/config/app_links.dart';

import '../../helpers/test_app.dart';

const _tall = Size(390, 1400);

Future<void> _openMore(WidgetTester tester) async {
  await tester.tap(find.text('More').last);
  await settle(tester);
}

Future<void> _openAbout(WidgetTester tester) async {
  await _openMore(tester);
  await tester.tap(find.text('About'));
  await settle(tester);
}

void main() {
  group('More', () {
    tracklyTest('lists About and the Privacy policy', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await _openMore(tester);

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
    });

    tracklyTest('Privacy policy opens Trackly\'s page in the browser', (
      tester,
    ) async {
      final opener = FakeLinkOpener();
      await pumpTrackly(tester, size: _tall, linkOpener: opener);
      await _openMore(tester);

      await tester.tap(find.text('Privacy policy'));
      await settle(tester);

      expect(opener.opened, [AppLinks.privacyPolicyUri]);
      // It stays on More: the page opens outside the app.
      expect(find.text('About'), findsOneWidget);
    });

    tracklyTest('says so, with the address, when nothing can open it', (
      tester,
    ) async {
      final opener = FakeLinkOpener()..canOpen = false;
      await pumpTrackly(tester, size: _tall, linkOpener: opener);
      await _openMore(tester);

      await tester.tap(find.text('Privacy policy'));
      await settle(tester);

      expect(
        find.text(
          'Couldn’t open https://corecrest.tech/trackly/privacy-policy. '
          'Try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('About', () {
    tracklyTest('shows the name, tagline, version and maker', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await _openAbout(tester);

      expect(find.text('Trackly'), findsWidgets);
      expect(find.text('Know what’s charging next.'), findsOneWidget);
      expect(find.text('Version 1.0.0 (8)'), findsOneWidget);
      expect(find.text('Made by CoreCrest'), findsOneWidget);
    });

    tracklyTest('Back returns to More', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await _openAbout(tester);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);

      expect(find.text('Made by CoreCrest'), findsNothing);
      expect(find.text('Privacy policy'), findsOneWidget);
    });

    tracklyTest('Privacy policy opens the page', (tester) async {
      final opener = FakeLinkOpener();
      await pumpTrackly(tester, size: _tall, linkOpener: opener);
      await _openAbout(tester);

      await tester.tap(find.text('Privacy policy'));
      await settle(tester);

      expect(opener.opened, [AppLinks.privacyPolicyUri]);
    });

    tracklyTest('Contact support opens a mail draft', (tester) async {
      final opener = FakeLinkOpener();
      await pumpTrackly(tester, size: _tall, linkOpener: opener);
      await _openAbout(tester);

      expect(find.text('info@corecrest.tech'), findsOneWidget);
      await tester.tap(find.text('Contact support'));
      await settle(tester);

      expect(opener.opened, [AppLinks.supportUri]);
    });

    tracklyTest('with no mail app it shows the address to write to', (
      tester,
    ) async {
      final opener = FakeLinkOpener()..canOpen = false;
      await pumpTrackly(tester, size: _tall, linkOpener: opener);
      await _openAbout(tester);

      await tester.tap(find.text('Contact support'));
      await settle(tester);

      expect(
        find.text('Couldn’t open info@corecrest.tech. Try again.'),
        findsOneWidget,
      );
    });

    tracklyTest('Open source licenses opens the licenses page', (tester) async {
      await pumpTrackly(tester, size: _tall);
      await _openAbout(tester);

      await tester.tap(find.text('Open source licenses'));
      await settle(tester);

      expect(find.byType(LicensePage), findsOneWidget);
    });
  });

  group('layout', () {
    for (final (size, scale) in [
      (const Size(320, 640), 1.0),
      (const Size(320, 640), 1.6),
      (const Size(390, 844), 1.6),
    ]) {
      tracklyTest('About has no overflow at ${size.width}dp, ${scale}x text', (
        tester,
      ) async {
        await pumpTrackly(tester, size: size, textScale: scale);
        await _openAbout(tester);

        expect(tester.takeException(), isNull);
        expect(find.text('Contact support'), findsOneWidget);
      });
    }
  });
}
