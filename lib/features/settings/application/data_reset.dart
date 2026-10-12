import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/error/error_reporter.dart';
import '../../../core/notifications/notification_service.dart';
import 'settings_providers.dart';
import 'settings_store.dart';

/// The two ways to wipe what the user has entered. Both are permanent.
class DataReset {
  DataReset(this._ref);

  final Ref _ref;

  AppDatabase get _db => _ref.read(appDatabaseProvider);

  /// Removes every recorded payment and skip. Subscriptions, their next charge
  /// dates and their reminders are untouched.
  Future<void> clearHistory() =>
      _reported(() => _db.paymentsDao.clearHistory());

  /// Back to a fresh install: every subscription, bill and trial with its
  /// payment history, every scheduled reminder, and every setting.
  ///
  /// The data goes first, because it is what the user asked to remove. Not
  /// being able to cancel the reminders afterwards is reported but does not
  /// fail the reset: a reminder for an item that no longer exists opens the
  /// app normally, and the next launch reconciles them anyway.
  Future<void> deleteEverything() async {
    await _reported(() async {
      await _db.deleteAllUserData();
      await _ref.read(settingsStoreProvider).clear();
    });

    try {
      await _ref.read(notificationServiceProvider).cancelAll();
    } catch (error, stackTrace) {
      await _ref
          .read(errorReporterProvider)
          .captureException(error, stackTrace);
    }

    // Settings are read from the store again, now empty.
    _ref
      ..invalidate(defaultCurrencyProvider)
      ..invalidate(themeModeProvider)
      ..invalidate(defaultReminderProvider);
  }

  /// Reports a failure, then lets the caller show its own message.
  Future<void> _reported(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      await _ref
          .read(errorReporterProvider)
          .captureException(error, stackTrace);
      rethrow;
    }
  }
}

final dataResetProvider = Provider<DataReset>(DataReset.new);
