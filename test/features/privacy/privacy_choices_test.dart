import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/analytics/analytics_service.dart';
import 'package:trackly/core/error/error_reporter.dart';
import 'package:trackly/features/privacy/application/privacy_choices.dart';
import 'package:trackly/features/settings/application/settings_store.dart';

import '../../helpers/privacy_fakes.dart';

void main() {
  late InMemorySettingsStore store;
  late FakeAnalytics analytics;
  late FakeErrorReporter errors;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        analyticsProvider.overrideWithValue(analytics),
        errorReporterProvider.overrideWithValue(errors),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    store = InMemorySettingsStore();
    analytics = FakeAnalytics();
    errors = FakeErrorReporter();
  });

  test('before anyone is asked, nothing is allowed and nothing is applied', () {
    final c = container();
    final choices = c.read(privacyChoicesProvider);

    expect(choices.decided, isFalse);
    expect(choices.usageStatsOn, isFalse);
    expect(choices.errorReportsOn, isFalse);
    expect(analytics.switches, isEmpty);
    expect(errors.switches, isEmpty);
  });

  test('earlier choices are read back at start', () async {
    await store.setUsageStatsEnabled(true);
    await store.setErrorReportsEnabled(false);
    final choices = container().read(privacyChoicesProvider);

    expect(choices.decided, isTrue);
    expect(choices.usageStatsOn, isTrue);
    expect(choices.errorReportsOn, isFalse);
  });

  test('Share anonymous data turns both on and remembers it', () async {
    final c = container();
    await c.read(privacyChoicesProvider.notifier).chooseAll(true);

    expect(c.read(privacyChoicesProvider).decided, isTrue);
    expect(store.usageStatsEnabled, isTrue);
    expect(store.errorReportsEnabled, isTrue);
    expect(analytics.switches, [true]);
    expect(errors.switches, [true]);
  });

  test('Don\'t share turns both off and remembers it', () async {
    final c = container();
    await c.read(privacyChoicesProvider.notifier).chooseAll(false);

    final choices = c.read(privacyChoicesProvider);
    expect(choices.decided, isTrue);
    expect(choices.usageStatsOn, isFalse);
    expect(choices.errorReportsOn, isFalse);
    expect(store.usageStatsEnabled, isFalse);
    expect(store.errorReportsEnabled, isFalse);
    expect(analytics.switches, [false]);
    expect(errors.switches, [false]);
  });

  test('each switch changes only its own service', () async {
    final c = container();
    final controller = c.read(privacyChoicesProvider.notifier);
    await controller.chooseAll(true);
    analytics.switches.clear();
    errors.switches.clear();

    await controller.setUsageStats(false);
    expect(analytics.switches, [false]);
    expect(errors.switches, isEmpty);
    expect(store.usageStatsEnabled, isFalse);
    expect(store.errorReportsEnabled, isTrue);

    await controller.setErrorReports(false);
    expect(errors.switches, [false]);
    expect(store.errorReportsEnabled, isFalse);

    await controller.setErrorReports(true);
    expect(errors.switches, [false, true]);
    expect(c.read(privacyChoicesProvider).errorReportsOn, isTrue);
    expect(c.read(privacyChoicesProvider).usageStatsOn, isFalse);
  });

  test('setting the same value again does nothing', () async {
    final c = container();
    final controller = c.read(privacyChoicesProvider.notifier);
    await controller.chooseAll(true);
    analytics.switches.clear();

    await controller.setUsageStats(true);
    expect(analytics.switches, isEmpty);
  });

  test('a first change in Settings settles the other answer as no', () async {
    // So the first-run screen can never come back after this.
    final c = container();
    await c.read(privacyChoicesProvider.notifier).setUsageStats(true);

    final choices = c.read(privacyChoicesProvider);
    expect(choices.decided, isTrue);
    expect(choices.usageStatsOn, isTrue);
    expect(choices.errorReportsOn, isFalse);
    expect(store.errorReportsEnabled, isFalse);
  });

  test('a service that fails does not lose the choice or throw', () async {
    analytics.failSwitchWith = StateError('platform call failed');
    final c = container();

    await c.read(privacyChoicesProvider.notifier).chooseAll(true);

    expect(store.usageStatsEnabled, isTrue, reason: 'still remembered');
    expect(store.errorReportsEnabled, isTrue);
    expect(errors.switches, [true], reason: 'the other service still switched');
    expect(errors.captured.single, isA<StateError>(), reason: 'reported');
  });
}
