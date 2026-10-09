// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Trackly';

  @override
  String get homeSubtitle => 'Subscriptions & Bills';

  @override
  String get navHome => 'Home';

  @override
  String get navInsights => 'Insights';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navMore => 'More';

  @override
  String get navAdd => 'Add subscription';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get moreTitle => 'More';

  @override
  String get addSubscriptionTitle => 'Add subscription';

  @override
  String get searchTooltip => 'Search';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get heroLabel => 'YOUR RECURRING COST';

  @override
  String heroPerMonth(String amount) {
    return '$amount / month';
  }

  @override
  String heroPerYear(String amount) {
    return '$amount per year';
  }

  @override
  String heroOtherCurrencies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+ $count other currencies',
      one: '+ 1 other currency',
    );
    return '$_temp0';
  }

  @override
  String get statusActive => 'Active';

  @override
  String get statusTrial => 'Trial';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String statusCount(String label, int count) {
    return '$label: $count';
  }

  @override
  String get upcomingTitle => 'Upcoming charges';

  @override
  String get recentPaymentsTitle => 'Recent payments';

  @override
  String get seeAll => 'See all';

  @override
  String get emptyUpcomingTitle => 'No upcoming charges';

  @override
  String get emptyUpcomingBody =>
      'Add your first subscription to start tracking renewals.';

  @override
  String get quickAddTitle => 'Add a new subscription';

  @override
  String get quickAddHelper => 'Quick add — you can edit details later';

  @override
  String get quickAddServiceHint => 'Search a service';

  @override
  String get quickAddAmount => 'Amount';

  @override
  String get quickAddFrequency => 'Frequency';

  @override
  String get quickAddStartDate => 'Start date';

  @override
  String get quickAddSave => 'Save';

  @override
  String quickAddSaved(String date) {
    return 'Saved — next charge $date';
  }

  @override
  String get quickAddSaveError => 'Couldn\'t save subscription. Try again.';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get frequencyMonthly => 'Monthly';

  @override
  String get frequencyQuarterly => 'Quarterly';

  @override
  String get frequencySemiAnnual => 'Every 6 months';

  @override
  String get frequencyYearly => 'Yearly';

  @override
  String get frequencyCustom => 'Custom';

  @override
  String frequencyAndCurrency(String frequency, String currency) {
    return '$frequency • $currency';
  }

  @override
  String get dueToday => 'Due today';

  @override
  String get dueTomorrow => 'Due tomorrow';

  @override
  String dueInDays(int count) {
    return 'In $count days';
  }

  @override
  String get overdue => 'Overdue';

  @override
  String paidOn(String date) {
    return 'Paid $date';
  }

  @override
  String get pillPaused => 'Paused';

  @override
  String get pillTrial => 'Trial';

  @override
  String get addPanelClose => 'Close';

  @override
  String get addNameHint => 'Search a service or type a name';

  @override
  String get addTypeSubscription => 'Subscription';

  @override
  String get addTypeBill => 'Bill';

  @override
  String get addCurrency => 'Currency';

  @override
  String get addSectionBilling => 'Billing';

  @override
  String get addSectionReminder => 'Reminder';

  @override
  String get addRemindMe => 'Remind me';

  @override
  String get reminderSameDay => 'Same day';

  @override
  String reminderDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get addMoreDetails => 'More details';

  @override
  String get addCategory => 'Category';

  @override
  String get addCategoryNone => 'None';

  @override
  String get addTrialSwitch => 'This is a free trial';

  @override
  String get addTrialEnds => 'Trial ends';

  @override
  String get addNotes => 'Notes';
}
