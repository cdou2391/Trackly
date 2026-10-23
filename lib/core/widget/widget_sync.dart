import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/home/application/home_providers.dart';
import '../database/app_database.dart';
import '../error/error_reporter.dart';
import '../utils/format_utils.dart';
import 'home_widget_gateway.dart';
import 'next_payment.dart';

/// Keeps the home-screen widget showing the next upcoming payment.
///
/// Only the item's name, amount and due date are written (the widget works out
/// "in 3 days" itself, so it stays right after midnight without the app
/// running). Everything stays on the device.
class WidgetSync {
  WidgetSync(this._ref, {Locale Function()? locale})
    : _locale = locale ?? (() => PlatformDispatcher.instance.locale);

  final Ref _ref;
  final Locale Function() _locale;

  Future<void>? _running;
  bool _again = false;

  /// Rewrites the widget data and redraws. A request during a run triggers one
  /// more run afterwards, so the latest data wins.
  Future<void> update() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      try {
        await _run();
      } catch (error, stackTrace) {
        await _ref
            .read(errorReporterProvider)
            .captureException(error, stackTrace);
      }
    } while (_again);
  }

  Future<void> _run() async {
    final gateway = _ref.read(homeWidgetGatewayProvider);
    final items = await _ref
        .read(appDatabaseProvider)
        .recurringItemsDao
        .getActive();
    final next = nextPayment(items);
    final locale = _locale().toLanguageTag();

    await gateway.save({
      'widget_name': next?.name,
      'widget_amount': next == null
          ? null
          : formatMoney(next.amount, next.currencyCode, locale: locale),
      // ISO date: the widget counts the days itself.
      'widget_due': next == null
          ? null
          : DateFormat('yyyy-MM-dd').format(next.nextDueDate),
      'widget_due_label': next == null
          ? null
          : formatMediumDate(next.nextDueDate, locale: locale),
    });
    await gateway.refresh();
  }
}

final widgetSyncProvider = Provider<WidgetSync>((ref) {
  final sync = WidgetSync(ref);

  ref.listen(recurringItemsProvider, (previous, next) {
    if (next.hasValue) unawaited(sync.update());
  }, fireImmediately: true);

  // A day passing changes nothing stored, but catch up on return anyway.
  final observer = _ResumeObserver(() => unawaited(sync.update()));
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));

  return sync;
});

class _ResumeObserver with WidgetsBindingObserver {
  _ResumeObserver(this._onResume);

  final VoidCallback _onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }
}
