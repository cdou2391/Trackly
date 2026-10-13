import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/application/home_providers.dart';
import '../../features/settings/application/settings_store.dart';
import '../../features/subscriptions/application/item_analytics.dart';
import '../../features/subscriptions/domain/recurring_item.dart';
import '../error/error_reporter.dart';
import '../utils/recurrence_utils.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';

/// Counts each free trial once, the first time the app sees that its end date
/// has passed.
///
/// A trial ends while the app is closed, so there is no moment to hook an
/// event to. Instead each check (at launch, on return to the app and when
/// items change) compares the end dates with today and keeps the ids already
/// counted on the device. Only structured facts are sent, never the name.
class TrialEndReporter {
  TrialEndReporter(this._ref);

  final Ref _ref;

  /// Logs `trial_ended` for trials that ended since the last check.
  Future<void> check() async {
    try {
      final items = _ref.read(recurringItemsProvider).value;
      if (items == null) return;

      final today = dateOnly(_ref.read(nowProvider)());
      final store = _ref.read(settingsStoreProvider);
      final reported = store.reportedTrialEnds;
      final ended = [
        for (final item in items)
          if (_hasEnded(item, today)) item,
      ];

      final analytics = _ref.read(analyticsProvider);
      for (final item in ended) {
        if (reported.contains(item.id)) continue;
        unawaited(
          analytics.logEvent(
            AnalyticsEvents.trialEnded,
            parameters: itemAnalyticsParameters(item),
          ),
        );
      }

      // Forgets trials that were deleted or moved to a later end date, so a
      // trial that ends again later is counted again.
      final now = {for (final item in ended) item.id};
      if (now.length != reported.length || !now.containsAll(reported)) {
        await store.setReportedTrialEnds(now);
      }
    } catch (error, stackTrace) {
      await _ref
          .read(errorReporterProvider)
          .captureException(error, stackTrace);
    }
  }

  static bool _hasEnded(RecurringItem item, DateTime today) {
    final end = item.trialEndDate;
    return item.isTrial && end != null && dateOnly(end).isBefore(today);
  }
}

final trialEndReporterProvider = Provider<TrialEndReporter>((ref) {
  final reporter = TrialEndReporter(ref);

  ref.listen<AsyncValue<List<RecurringItem>>>(recurringItemsProvider, (
    previous,
    next,
  ) {
    if (next.hasValue) unawaited(reporter.check());
  }, fireImmediately: true);

  // Days pass while the app is in the background.
  final observer = _ResumeObserver(() => unawaited(reporter.check()));
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

  return reporter;
});

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this._onResume);

  final VoidCallback _onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }
}
