import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/error/error_reporter.dart';
import '../../settings/application/settings_store.dart';

/// What the person has agreed to send. A choice is null until they are asked;
/// until then, and whenever it is false, nothing is sent.
class PrivacyChoices {
  const PrivacyChoices({this.usageStats, this.errorReports});

  final bool? usageStats;
  final bool? errorReports;

  /// Both questions answered, so the first-run screen is done with.
  bool get decided => usageStats != null && errorReports != null;

  bool get usageStatsOn => usageStats ?? false;
  bool get errorReportsOn => errorReports ?? false;

  PrivacyChoices copyWith({bool? usageStats, bool? errorReports}) =>
      PrivacyChoices(
        usageStats: usageStats ?? this.usageStats,
        errorReports: errorReports ?? this.errorReports,
      );
}

/// Holds the privacy choices and applies them: each change is remembered,
/// switches the matching service on or off at once, and never fails the
/// screen (a problem is reported instead).
class PrivacyController extends Notifier<PrivacyChoices> {
  @override
  PrivacyChoices build() {
    final store = ref.watch(settingsStoreProvider);
    return PrivacyChoices(
      usageStats: store.usageStatsEnabled,
      errorReports: store.errorReportsEnabled,
    );
  }

  /// The first-run answer: share both kinds of data, or neither.
  Future<void> chooseAll(bool allow) async {
    state = PrivacyChoices(usageStats: allow, errorReports: allow);
    await _apply(usageStats: allow, errorReports: allow);
  }

  Future<void> setUsageStats(bool allow) async {
    if (state.usageStats == allow) return;
    // A change here settles the other answer as "no" if it was never given,
    // so the first-run screen cannot reappear after a change in Settings.
    final settleOther = state.errorReports == null;
    state = state.copyWith(
      usageStats: allow,
      errorReports: state.errorReports ?? false,
    );
    await _apply(usageStats: allow, errorReports: settleOther ? false : null);
  }

  Future<void> setErrorReports(bool allow) async {
    if (state.errorReports == allow) return;
    final settleOther = state.usageStats == null;
    state = state.copyWith(
      errorReports: allow,
      usageStats: state.usageStats ?? false,
    );
    await _apply(errorReports: allow, usageStats: settleOther ? false : null);
  }

  Future<void> _apply({bool? usageStats, bool? errorReports}) async {
    final store = ref.read(settingsStoreProvider);
    final analytics = ref.read(analyticsProvider);
    final errors = ref.read(errorReporterProvider);

    // Each step is independent: one failing must not stop the others, least
    // of all switching something off.
    Future<void> step(Future<void> Function() action) async {
      try {
        await action();
      } catch (error, stackTrace) {
        await ref
            .read(errorReporterProvider)
            .captureException(error, stackTrace);
      }
    }

    if (usageStats != null) {
      await step(() => analytics.setCollectionEnabled(usageStats));
      await step(() => store.setUsageStatsEnabled(usageStats));
    }
    if (errorReports != null) {
      await step(() => errors.setEnabled(errorReports));
      await step(() => store.setErrorReportsEnabled(errorReports));
    }
  }
}

final privacyChoicesProvider =
    NotifierProvider<PrivacyController, PrivacyChoices>(PrivacyController.new);
