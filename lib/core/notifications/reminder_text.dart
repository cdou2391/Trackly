import 'dart:ui';

import '../../features/subscriptions/domain/recurring_item.dart';
import '../../l10n/app_localizations.dart';
import '../utils/format_utils.dart';
import 'reminder_plan.dart';

/// The localized notification for [reminder]: the item's name as the title and
/// when and how much as the body.
({String title, String body}) reminderText(
  AppLocalizations l10n,
  RecurringItem item,
  PlannedReminder reminder, {
  required String locale,
}) {
  final amount = formatMoney(item.amount, item.currencyCode, locale: locale);

  final body = switch (reminder.type) {
    ReminderType.dueSoon => l10n.notifDueSoon(reminder.daysAhead, amount),
    ReminderType.trialEnding => l10n.notifTrialEnding(
      reminder.daysAhead,
      amount,
    ),
    // On the day itself a trial's message is about the trial ending.
    ReminderType.dueToday =>
      item.isTrial
          ? l10n.notifTrialEndsToday(amount)
          : l10n.notifDueToday(amount),
  };

  return (title: item.name, body: body);
}

/// Localizations for [locale], falling back to English for a language the app
/// does not have yet (notifications are built outside any widget).
AppLocalizations notificationLocalizations(Locale locale) {
  if (AppLocalizations.delegate.isSupported(locale)) {
    return lookupAppLocalizations(locale);
  }
  return lookupAppLocalizations(const Locale('en'));
}
