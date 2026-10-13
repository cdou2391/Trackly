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
  String get appTagline => 'Know what’s charging next.';

  @override
  String get splashLoading => 'Loading Trackly';

  @override
  String get splashErrorTitle => 'Couldn’t start Trackly';

  @override
  String get splashErrorBody =>
      'Something went wrong while opening the app. Please try again.';

  @override
  String get splashRetry => 'Try again';

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
  String get heroLabel => 'Your recurring cost';

  @override
  String get heroMonthSuffix => '/month';

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
  String get quickAddServiceHint =>
      'Search a service (e.g. Netflix, Spotify, Adobe)';

  @override
  String get quickAddAmountHint => '0.00';

  @override
  String get quickAddServiceLabel => 'Service name';

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
  String get addRemindAt => 'Remind me at';

  @override
  String reminderWhenAt(String when, String time) {
    return '$when at $time';
  }

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

  @override
  String get editSubscriptionTitle => 'Edit subscription';

  @override
  String get editNextCharge => 'Next charge';

  @override
  String get editSaveChanges => 'Save changes';

  @override
  String get editSaved => 'Changes saved';

  @override
  String get back => 'Back';

  @override
  String get editTooltip => 'Edit';

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String get skipCharge => 'Skip this charge';

  @override
  String get pauseAction => 'Pause';

  @override
  String get resumeAction => 'Resume';

  @override
  String get cancelSubscription => 'Cancel subscription';

  @override
  String get deleteItem => 'Delete';

  @override
  String get paymentHistory => 'Payment history';

  @override
  String get noPaymentsYet => 'No payments recorded yet.';

  @override
  String get nextChargeLabel => 'Next charge';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get reminderOff => 'Off';

  @override
  String get categoryLabel => 'Category';

  @override
  String get typeLabel => 'Type';

  @override
  String get notesLabel => 'Notes';

  @override
  String trialEndsOn(String date) {
    return 'Trial ends $date';
  }

  @override
  String afterTrial(String amount, String frequency) {
    return '$amount $frequency after the trial';
  }

  @override
  String dueOn(String date) {
    return 'Due $date';
  }

  @override
  String get skippedChip => 'Skipped';

  @override
  String get undo => 'Undo';

  @override
  String snackMarkedPaid(String date) {
    return 'Marked as paid — next charge $date';
  }

  @override
  String snackSkipped(String date) {
    return 'Skipped — next charge $date';
  }

  @override
  String get snackPaused => 'Paused';

  @override
  String snackResumed(String date) {
    return 'Resumed — next charge $date';
  }

  @override
  String get snackCancelled => 'Cancelled';

  @override
  String get snackDeleted => 'Deleted';

  @override
  String get actionFailed => 'Couldn\'t save that change. Try again.';

  @override
  String get resumePickerHelp => 'Next charge date';

  @override
  String cancelDialogTitle(String name) {
    return 'Cancel $name?';
  }

  @override
  String get cancelDialogBody =>
      'Reminders and due dates stop. Your payment history is kept.';

  @override
  String get cancelDialogConfirm => 'Cancel subscription';

  @override
  String deleteDialogTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteDialogBody =>
      'This removes it and its payment history. This can\'t be undone.';

  @override
  String get deleteDialogConfirm => 'Delete';

  @override
  String get dialogKeep => 'Keep it';

  @override
  String get dialogNotNow => 'Not now';

  @override
  String get allSubscriptionsTitle => 'All subscriptions';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterTrial => 'Trial';

  @override
  String get filterPaused => 'Paused';

  @override
  String get filterCancelled => 'Cancelled';

  @override
  String get noItemsInFilter => 'Nothing here yet.';

  @override
  String get historyTitle => 'Payment history';

  @override
  String get historyEmpty => 'Payments you mark as paid will show up here.';

  @override
  String get moreSectionTracking => 'Tracking';

  @override
  String get notifChannelName => 'Renewal reminders';

  @override
  String get notifChannelDescription =>
      'Reminders before a subscription or bill is due';

  @override
  String notifDueSoon(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Due in $count days',
      one: 'Due tomorrow',
    );
    return '$_temp0 · $amount';
  }

  @override
  String notifDueToday(String amount) {
    return 'Due today · $amount';
  }

  @override
  String notifTrialEnding(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trial ends in $count days',
      one: 'Trial ends tomorrow',
    );
    return '$_temp0. You\'ll be charged $amount after.';
  }

  @override
  String notifTrialEndsToday(String amount) {
    return 'Trial ends today. You\'ll be charged $amount.';
  }

  @override
  String get remindersPromptTitle => 'Get reminded before it renews?';

  @override
  String get remindersPromptBody =>
      'Trackly can send a notification before a charge. Reminders are scheduled on your device and never leave it.';

  @override
  String get remindersPromptConfirm => 'Turn on reminders';

  @override
  String get remindersPromptLater => 'Not now';

  @override
  String get chipPaid => 'Paid';

  @override
  String get calendarMonthTotal => 'Total this month';

  @override
  String calendarLeftFrom(String date) {
    return 'Left from $date';
  }

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarNoCharges => 'No charges on this day.';

  @override
  String calendarDayLabel(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges',
      one: '1 charge',
      zero: 'no charges',
    );
    return '$date: $_temp0';
  }

  @override
  String get insightsPerMonth => 'Per month';

  @override
  String get insightsPerYear => 'Per year';

  @override
  String get insightsChargesAhead => 'Charges ahead';

  @override
  String insightsChargesAheadSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges',
      one: '1 charge',
    );
    return '$_temp0 in the next month';
  }

  @override
  String get insightsByCategory => 'By category';

  @override
  String insightsCategorySubs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subscriptions',
      one: '1 subscription',
    );
    return '$_temp0';
  }

  @override
  String insightsShare(int percent) {
    return '$percent%';
  }

  @override
  String get insightsEmptyTitle => 'No spending to show yet';

  @override
  String get insightsEmptyBody =>
      'Add a subscription to see your monthly cost and where it goes.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionDefaults => 'For new subscriptions';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsReminders => 'Remind me';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsSectionNotifications => 'Notifications';

  @override
  String get settingsNotificationsOn => 'Reminders are on';

  @override
  String get settingsNotificationsOff =>
      'Notifications are off, so you won’t get reminders.';

  @override
  String get settingsTurnOn => 'Turn on';

  @override
  String get settingsAllowInPhone =>
      'Allow notifications for Trackly in your phone’s settings to get reminders.';

  @override
  String get settingsReminderDelay =>
      'A reminder can arrive a few minutes after its time: Android delays reminders to save battery.';

  @override
  String get settingsSectionData => 'Your data';

  @override
  String get settingsClearHistory => 'Clear payment history';

  @override
  String get settingsClearHistoryHint => 'Keeps your subscriptions and bills';

  @override
  String get settingsDeleteAll => 'Delete all data';

  @override
  String get settingsDeleteAllHint => 'Subscriptions, history and settings';

  @override
  String get clearHistoryDialogTitle => 'Clear payment history?';

  @override
  String get clearHistoryDialogBody =>
      'This removes every recorded payment and skip. Your subscriptions and their next charge dates stay as they are. This can’t be undone.';

  @override
  String get clearHistoryConfirm => 'Clear history';

  @override
  String get deleteAllDialogTitle => 'Delete all data?';

  @override
  String get deleteAllDialogBody =>
      'This removes every subscription, bill and trial, their payment history and your settings, and cancels all reminders. This can’t be undone.';

  @override
  String get deleteAllConfirm => 'Delete everything';

  @override
  String get snackHistoryCleared => 'Payment history cleared';

  @override
  String get snackAllDeleted => 'All data deleted';

  @override
  String get searchHint => 'Search your subscriptions';

  @override
  String get searchClear => 'Clear search';

  @override
  String get searchPrompt => 'Search by name, category or note.';

  @override
  String get searchNoItems =>
      'Nothing to search yet. Add a subscription first.';

  @override
  String searchNoMatches(String query) {
    return 'No matches for “$query”';
  }

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get aboutMadeBy => 'Made by CoreCrest';

  @override
  String get aboutContact => 'Contact support';

  @override
  String get aboutLicenses => 'Open source licenses';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String linkOpenFailed(String address) {
    return 'Couldn’t open $address. Try again.';
  }

  @override
  String get privacyChoiceTitle => 'Help improve Trackly';

  @override
  String get privacyChoiceIntro =>
      'Your subscriptions, payments and notes stay on your phone. Trackly never receives them.';

  @override
  String get privacyChoiceAsk => 'If you allow it, Trackly also sends:';

  @override
  String get privacyChoiceUsageTitle => 'Usage statistics';

  @override
  String get privacyChoiceUsageBody =>
      'Which features are used, such as adding a subscription. Never names, amounts or notes.';

  @override
  String get privacyChoiceErrorsTitle => 'Error reports';

  @override
  String get privacyChoiceErrorsBody =>
      'Technical details when something goes wrong, so it can be fixed. Never your subscriptions.';

  @override
  String get privacyChoiceNothing =>
      'Nothing is sent unless you allow it. You can change this at any time in Settings.';

  @override
  String get privacyChoiceRead => 'Read the privacy policy';

  @override
  String get privacyChoiceAllow => 'Share anonymous data';

  @override
  String get privacyChoiceDecline => 'Don’t share';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsUsageStats => 'Usage statistics';

  @override
  String get settingsUsageStatsHint =>
      'Which features are used. Never names, amounts or notes.';

  @override
  String get settingsErrorReports => 'Error reports';

  @override
  String get settingsErrorReportsHint =>
      'Technical details when something breaks.';

  @override
  String get settingsPrivacyNote => 'Nothing is sent while these are off.';
}
