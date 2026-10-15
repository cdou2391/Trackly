import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Trackly'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Know what’s charging next.'**
  String get appTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading Trackly'**
  String get splashLoading;

  /// No description provided for @splashErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t start Trackly'**
  String get splashErrorTitle;

  /// No description provided for @splashErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while opening the app. Please try again.'**
  String get splashErrorBody;

  /// No description provided for @splashRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get splashRetry;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions & Bills'**
  String get homeSubtitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navAdd.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get navAdd;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @addSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscriptionTitle;

  /// No description provided for @searchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @heroLabel.
  ///
  /// In en, this message translates to:
  /// **'Your recurring cost'**
  String get heroLabel;

  /// No description provided for @heroMonthSuffix.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get heroMonthSuffix;

  /// No description provided for @heroPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount} / month'**
  String heroPerMonth(String amount);

  /// No description provided for @heroPerYear.
  ///
  /// In en, this message translates to:
  /// **'{amount} per year'**
  String heroPerYear(String amount);

  /// No description provided for @heroOtherCurrencies.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{+ 1 other currency} other{+ {count} other currencies}}'**
  String heroOtherCurrencies(int count);

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get statusTrial;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusCount.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count}'**
  String statusCount(String label, int count);

  /// No description provided for @upcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming charges'**
  String get upcomingTitle;

  /// No description provided for @recentPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent payments'**
  String get recentPaymentsTitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @emptyUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming charges'**
  String get emptyUpcomingTitle;

  /// No description provided for @emptyUpcomingBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first subscription to start tracking renewals.'**
  String get emptyUpcomingBody;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new subscription'**
  String get quickAddTitle;

  /// No description provided for @quickAddHelper.
  ///
  /// In en, this message translates to:
  /// **'Quick add — you can edit details later'**
  String get quickAddHelper;

  /// No description provided for @quickAddServiceHint.
  ///
  /// In en, this message translates to:
  /// **'Search a service (e.g. Netflix, Spotify, Adobe)'**
  String get quickAddServiceHint;

  /// No description provided for @quickAddAmountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get quickAddAmountHint;

  /// No description provided for @quickAddServiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Service name'**
  String get quickAddServiceLabel;

  /// No description provided for @quickAddAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get quickAddAmount;

  /// No description provided for @quickAddFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get quickAddFrequency;

  /// No description provided for @quickAddStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get quickAddStartDate;

  /// No description provided for @quickAddSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get quickAddSave;

  /// No description provided for @quickAddSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved — next charge {date}'**
  String quickAddSaved(String date);

  /// No description provided for @quickAddSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save subscription. Try again.'**
  String get quickAddSaveError;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get frequencyWeekly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get frequencyMonthly;

  /// No description provided for @frequencyQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get frequencyQuarterly;

  /// No description provided for @frequencySemiAnnual.
  ///
  /// In en, this message translates to:
  /// **'Every 6 months'**
  String get frequencySemiAnnual;

  /// No description provided for @frequencyYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get frequencyYearly;

  /// No description provided for @frequencyCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get frequencyCustom;

  /// No description provided for @frequencyAndCurrency.
  ///
  /// In en, this message translates to:
  /// **'{frequency} • {currency}'**
  String frequencyAndCurrency(String frequency, String currency);

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Due tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String dueInDays(int count);

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @paidOn.
  ///
  /// In en, this message translates to:
  /// **'Paid {date}'**
  String paidOn(String date);

  /// No description provided for @pillPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pillPaused;

  /// No description provided for @pillTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get pillTrial;

  /// No description provided for @addPanelClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get addPanelClose;

  /// No description provided for @addNameHint.
  ///
  /// In en, this message translates to:
  /// **'Search a service or type a name'**
  String get addNameHint;

  /// No description provided for @addTypeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get addTypeSubscription;

  /// No description provided for @addTypeBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get addTypeBill;

  /// No description provided for @addCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get addCurrency;

  /// No description provided for @addSectionBilling.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get addSectionBilling;

  /// No description provided for @addSectionReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get addSectionReminder;

  /// No description provided for @addRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get addRemindMe;

  /// No description provided for @reminderSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same day'**
  String get reminderSameDay;

  /// No description provided for @addRemindAt.
  ///
  /// In en, this message translates to:
  /// **'Remind me at'**
  String get addRemindAt;

  /// No description provided for @suggestionBillTag.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get suggestionBillTag;

  /// No description provided for @reminderOnTheDay.
  ///
  /// In en, this message translates to:
  /// **'On the day'**
  String get reminderOnTheDay;

  /// No description provided for @reminderNumbered.
  ///
  /// In en, this message translates to:
  /// **'Reminder {number}'**
  String reminderNumbered(int number);

  /// No description provided for @reminderWhenAt.
  ///
  /// In en, this message translates to:
  /// **'{when} at {time}'**
  String reminderWhenAt(String when, String time);

  /// No description provided for @reminderDaysBefore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day before} other{{count} days before}}'**
  String reminderDaysBefore(int count);

  /// No description provided for @addMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'More details'**
  String get addMoreDetails;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get addCategory;

  /// No description provided for @addCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get addCategoryNone;

  /// No description provided for @addTrialSwitch.
  ///
  /// In en, this message translates to:
  /// **'This is a free trial'**
  String get addTrialSwitch;

  /// No description provided for @addTrialEnds.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get addTrialEnds;

  /// No description provided for @addNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get addNotes;

  /// No description provided for @editSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get editSubscriptionTitle;

  /// No description provided for @editNextCharge.
  ///
  /// In en, this message translates to:
  /// **'Next charge'**
  String get editNextCharge;

  /// No description provided for @editSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get editSaveChanges;

  /// No description provided for @editSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get editSaved;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// No description provided for @skipCharge.
  ///
  /// In en, this message translates to:
  /// **'Skip this charge'**
  String get skipCharge;

  /// No description provided for @pauseAction.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseAction;

  /// No description provided for @resumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resumeAction;

  /// No description provided for @cancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelSubscription;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItem;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistory;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments recorded yet.'**
  String get noPaymentsYet;

  /// No description provided for @nextChargeLabel.
  ///
  /// In en, this message translates to:
  /// **'Next charge'**
  String get nextChargeLabel;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderOff;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @trialEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Trial ends {date}'**
  String trialEndsOn(String date);

  /// No description provided for @afterTrial.
  ///
  /// In en, this message translates to:
  /// **'{amount} {frequency} after the trial'**
  String afterTrial(String amount, String frequency);

  /// No description provided for @dueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueOn(String date);

  /// No description provided for @skippedChip.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skippedChip;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @snackMarkedPaid.
  ///
  /// In en, this message translates to:
  /// **'Marked as paid — next charge {date}'**
  String snackMarkedPaid(String date);

  /// No description provided for @snackSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped — next charge {date}'**
  String snackSkipped(String date);

  /// No description provided for @snackPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get snackPaused;

  /// No description provided for @snackResumed.
  ///
  /// In en, this message translates to:
  /// **'Resumed — next charge {date}'**
  String snackResumed(String date);

  /// No description provided for @snackCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get snackCancelled;

  /// No description provided for @snackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get snackDeleted;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that change. Try again.'**
  String get actionFailed;

  /// No description provided for @resumePickerHelp.
  ///
  /// In en, this message translates to:
  /// **'Next charge date'**
  String get resumePickerHelp;

  /// No description provided for @cancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel {name}?'**
  String cancelDialogTitle(String name);

  /// No description provided for @cancelDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders and due dates stop. Your payment history is kept.'**
  String get cancelDialogBody;

  /// No description provided for @cancelDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get cancelDialogConfirm;

  /// No description provided for @deleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteDialogTitle(String name);

  /// No description provided for @deleteDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This removes it and its payment history. This can\'t be undone.'**
  String get deleteDialogBody;

  /// No description provided for @deleteDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDialogConfirm;

  /// No description provided for @dialogKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get dialogKeep;

  /// No description provided for @dialogNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get dialogNotNow;

  /// No description provided for @allSubscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'All subscriptions'**
  String get allSubscriptionsTitle;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterTrial.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get filterTrial;

  /// No description provided for @filterPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get filterPaused;

  /// No description provided for @filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterCancelled;

  /// No description provided for @noItemsInFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get noItemsInFilter;

  /// No description provided for @itemsViewShowList.
  ///
  /// In en, this message translates to:
  /// **'Show as list'**
  String get itemsViewShowList;

  /// No description provided for @itemsViewShowBubbles.
  ///
  /// In en, this message translates to:
  /// **'Show as bubbles'**
  String get itemsViewShowBubbles;

  /// No description provided for @bubbleSemantics.
  ///
  /// In en, this message translates to:
  /// **'{name}, {amount}, {status}'**
  String bubbleSemantics(String name, String amount, String status);

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Payments you mark as paid will show up here.'**
  String get historyEmpty;

  /// No description provided for @moreSectionTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get moreSectionTracking;

  /// No description provided for @notifChannelName.
  ///
  /// In en, this message translates to:
  /// **'Renewal reminders'**
  String get notifChannelName;

  /// No description provided for @notifChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Reminders before a subscription or bill is due'**
  String get notifChannelDescription;

  /// No description provided for @notifDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Due tomorrow} other{Due in {count} days}} · {amount}'**
  String notifDueSoon(int count, String amount);

  /// No description provided for @notifDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today · {amount}'**
  String notifDueToday(String amount);

  /// No description provided for @notifTrialEnding.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Trial ends tomorrow} other{Trial ends in {count} days}}. You\'ll be charged {amount} after.'**
  String notifTrialEnding(int count, String amount);

  /// No description provided for @notifTrialEndsToday.
  ///
  /// In en, this message translates to:
  /// **'Trial ends today. You\'ll be charged {amount}.'**
  String notifTrialEndsToday(String amount);

  /// No description provided for @remindersPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded before it renews?'**
  String get remindersPromptTitle;

  /// No description provided for @remindersPromptBody.
  ///
  /// In en, this message translates to:
  /// **'Trackly can send a notification before a charge. Reminders are scheduled on your device and never leave it.'**
  String get remindersPromptBody;

  /// No description provided for @remindersPromptConfirm.
  ///
  /// In en, this message translates to:
  /// **'Turn on reminders'**
  String get remindersPromptConfirm;

  /// No description provided for @remindersPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get remindersPromptLater;

  /// No description provided for @chipPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get chipPaid;

  /// No description provided for @calendarMonthTotal.
  ///
  /// In en, this message translates to:
  /// **'Total this month'**
  String get calendarMonthTotal;

  /// No description provided for @calendarLeftFrom.
  ///
  /// In en, this message translates to:
  /// **'Left from {date}'**
  String calendarLeftFrom(String date);

  /// No description provided for @calendarPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPrevMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get calendarToday;

  /// No description provided for @calendarNoCharges.
  ///
  /// In en, this message translates to:
  /// **'No charges on this day.'**
  String get calendarNoCharges;

  /// No description provided for @calendarDayLabel.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count, plural, =0{no charges} =1{1 charge} other{{count} charges}}'**
  String calendarDayLabel(String date, int count);

  /// No description provided for @insightsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get insightsPerMonth;

  /// No description provided for @insightsPerYear.
  ///
  /// In en, this message translates to:
  /// **'Per year'**
  String get insightsPerYear;

  /// No description provided for @insightsChargesAhead.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get insightsChargesAhead;

  /// No description provided for @insightsChargesAheadSemantics.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 charge} other{{count} charges}} in the next month'**
  String insightsChargesAheadSemantics(int count);

  /// No description provided for @insightsByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get insightsByCategory;

  /// No description provided for @insightsShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String insightsShare(int percent);

  /// No description provided for @insightsTrend.
  ///
  /// In en, this message translates to:
  /// **'Spending trend'**
  String get insightsTrend;

  /// No description provided for @insightsTrendRange3.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get insightsTrendRange3;

  /// No description provided for @insightsTrendRange6.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get insightsTrendRange6;

  /// No description provided for @insightsTrendRange12.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get insightsTrendRange12;

  /// No description provided for @insightsTrendLast.
  ///
  /// In en, this message translates to:
  /// **'Last {count} months'**
  String insightsTrendLast(int count);

  /// No description provided for @insightsTrendNote.
  ///
  /// In en, this message translates to:
  /// **'Past months show what you paid. This month also includes charges still to pay.'**
  String get insightsTrendNote;

  /// No description provided for @insightsTrendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your trend appears once two months have payments or charges.'**
  String get insightsTrendEmpty;

  /// No description provided for @insightsTrendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Spending trend, last {count} months: {points}'**
  String insightsTrendSemantics(int count, String points);

  /// No description provided for @insightsPaidThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Paid this month'**
  String get insightsPaidThisMonth;

  /// No description provided for @insightsPaidOf.
  ///
  /// In en, this message translates to:
  /// **'{paid} of {total}'**
  String insightsPaidOf(String paid, String total);

  /// No description provided for @insightsPaidHint.
  ///
  /// In en, this message translates to:
  /// **'Charges you mark as paid count here.'**
  String get insightsPaidHint;

  /// No description provided for @insightsByType.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions and bills'**
  String get insightsByType;

  /// No description provided for @insightsTypeSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get insightsTypeSubscriptions;

  /// No description provided for @insightsTypeBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get insightsTypeBills;

  /// No description provided for @insightsTypeItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String insightsTypeItems(int count);

  /// No description provided for @insightsBiggest.
  ///
  /// In en, this message translates to:
  /// **'Biggest costs'**
  String get insightsBiggest;

  /// No description provided for @insightsBiggestShare.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your monthly cost'**
  String insightsBiggestShare(int percent);

  /// No description provided for @insightsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No spending to show yet'**
  String get insightsEmptyTitle;

  /// No description provided for @insightsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a subscription to see your monthly cost and where it goes.'**
  String get insightsEmptyBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionDefaults.
  ///
  /// In en, this message translates to:
  /// **'For new subscriptions'**
  String get settingsSectionDefaults;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsReminders.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get settingsReminders;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsSectionNotifications;

  /// No description provided for @settingsNotificationsOn.
  ///
  /// In en, this message translates to:
  /// **'Reminders are on'**
  String get settingsNotificationsOn;

  /// No description provided for @settingsNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off, so you won’t get reminders.'**
  String get settingsNotificationsOff;

  /// No description provided for @settingsTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get settingsTurnOn;

  /// No description provided for @settingsAllowInPhone.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for Trackly in your phone’s settings to get reminders.'**
  String get settingsAllowInPhone;

  /// No description provided for @settingsReminderDelay.
  ///
  /// In en, this message translates to:
  /// **'A reminder can arrive a few minutes after its time: Android delays reminders to save battery.'**
  String get settingsReminderDelay;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsSectionData;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear payment history'**
  String get settingsClearHistory;

  /// No description provided for @settingsClearHistoryHint.
  ///
  /// In en, this message translates to:
  /// **'Keeps your subscriptions and bills'**
  String get settingsClearHistoryHint;

  /// No description provided for @settingsDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get settingsDeleteAll;

  /// No description provided for @settingsDeleteAllHint.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions, history and settings'**
  String get settingsDeleteAllHint;

  /// No description provided for @clearHistoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear payment history?'**
  String get clearHistoryDialogTitle;

  /// No description provided for @clearHistoryDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every recorded payment and skip. Your subscriptions and their next charge dates stay as they are. This can’t be undone.'**
  String get clearHistoryDialogBody;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistoryConfirm;

  /// No description provided for @deleteAllDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteAllDialogTitle;

  /// No description provided for @deleteAllDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every subscription, bill and trial, their payment history and your settings, and cancels all reminders. This can’t be undone.'**
  String get deleteAllDialogBody;

  /// No description provided for @deleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get deleteAllConfirm;

  /// No description provided for @snackHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Payment history cleared'**
  String get snackHistoryCleared;

  /// No description provided for @snackAllDeleted.
  ///
  /// In en, this message translates to:
  /// **'All data deleted'**
  String get snackAllDeleted;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search your subscriptions'**
  String get searchHint;

  /// No description provided for @searchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClear;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search by name, category or note.'**
  String get searchPrompt;

  /// No description provided for @searchNoItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing to search yet. Add a subscription first.'**
  String get searchNoItems;

  /// No description provided for @searchNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches for “{query}”'**
  String searchNoMatches(String query);

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 result} other{{count} results}}'**
  String searchResultCount(int count);

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutMadeBy.
  ///
  /// In en, this message translates to:
  /// **'Made by CoreCrest'**
  String get aboutMadeBy;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get aboutContact;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get aboutLicenses;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @linkOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t open {address}. Try again.'**
  String linkOpenFailed(String address);

  /// No description provided for @privacyChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Help improve Trackly'**
  String get privacyChoiceTitle;

  /// No description provided for @privacyChoiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Your subscriptions, payments and notes stay on your phone. Trackly never receives them.'**
  String get privacyChoiceIntro;

  /// No description provided for @privacyChoiceAsk.
  ///
  /// In en, this message translates to:
  /// **'If you allow it, Trackly also sends:'**
  String get privacyChoiceAsk;

  /// No description provided for @privacyChoiceUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics'**
  String get privacyChoiceUsageTitle;

  /// No description provided for @privacyChoiceUsageBody.
  ///
  /// In en, this message translates to:
  /// **'Which features are used, such as adding a subscription. Never names, amounts or notes.'**
  String get privacyChoiceUsageBody;

  /// No description provided for @privacyChoiceErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Error reports'**
  String get privacyChoiceErrorsTitle;

  /// No description provided for @privacyChoiceErrorsBody.
  ///
  /// In en, this message translates to:
  /// **'Technical details when something goes wrong, so it can be fixed. Never your subscriptions.'**
  String get privacyChoiceErrorsBody;

  /// No description provided for @privacyChoiceNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent unless you allow it. You can change this at any time in Settings.'**
  String get privacyChoiceNothing;

  /// No description provided for @privacyChoiceRead.
  ///
  /// In en, this message translates to:
  /// **'Read the privacy policy'**
  String get privacyChoiceRead;

  /// No description provided for @privacyChoiceAllow.
  ///
  /// In en, this message translates to:
  /// **'Share anonymous data'**
  String get privacyChoiceAllow;

  /// No description provided for @privacyChoiceDecline.
  ///
  /// In en, this message translates to:
  /// **'Don’t share'**
  String get privacyChoiceDecline;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsUsageStats.
  ///
  /// In en, this message translates to:
  /// **'Usage statistics'**
  String get settingsUsageStats;

  /// No description provided for @settingsUsageStatsHint.
  ///
  /// In en, this message translates to:
  /// **'Which features are used. Never names, amounts or notes.'**
  String get settingsUsageStatsHint;

  /// No description provided for @settingsErrorReports.
  ///
  /// In en, this message translates to:
  /// **'Error reports'**
  String get settingsErrorReports;

  /// No description provided for @settingsErrorReportsHint.
  ///
  /// In en, this message translates to:
  /// **'Technical details when something breaks.'**
  String get settingsErrorReportsHint;

  /// No description provided for @settingsPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Nothing is sent while these are off.'**
  String get settingsPrivacyNote;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export data (CSV)'**
  String get settingsExport;

  /// No description provided for @settingsExportHint.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions and payment history, for Excel or Sheets'**
  String get settingsExportHint;

  /// No description provided for @exportShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Trackly export'**
  String get exportShareTitle;

  /// No description provided for @exportNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet. Add a subscription first.'**
  String get exportNothing;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t export your data. Try again.'**
  String get exportFailed;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import data (CSV)'**
  String get settingsImport;

  /// No description provided for @settingsImportHint.
  ///
  /// In en, this message translates to:
  /// **'Restore a Trackly export, or add subscriptions from a spreadsheet'**
  String get settingsImportHint;

  /// No description provided for @importReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review before importing'**
  String get importReviewTitle;

  /// No description provided for @importNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to import.'**
  String get importNothing;

  /// No description provided for @importNewSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new subscription or bill} other{{count} new subscriptions and bills}}'**
  String importNewSubscriptions(int count);

  /// No description provided for @importNewPayments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new payment} other{{count} new payments}}'**
  String importNewPayments(int count);

  /// No description provided for @importDuplicates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row is already in Trackly and is left out} other{{count} rows are already in Trackly and are left out}}'**
  String importDuplicates(int count);

  /// No description provided for @importProblemRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row has a problem and will be skipped} other{{count} rows have problems and will be skipped}}'**
  String importProblemRows(int count);

  /// No description provided for @importFilesHeader.
  ///
  /// In en, this message translates to:
  /// **'Files that can’t be read'**
  String get importFilesHeader;

  /// No description provided for @importProblemsHeader.
  ///
  /// In en, this message translates to:
  /// **'Problems'**
  String get importProblemsHeader;

  /// No description provided for @importNotesHeader.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get importNotesHeader;

  /// No description provided for @importMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{…and 1 more} other{…and {count} more}}'**
  String importMore(int count);

  /// No description provided for @importConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importConfirm;

  /// No description provided for @importConfirmSkipping.
  ///
  /// In en, this message translates to:
  /// **'Import, skipping the problem rows'**
  String get importConfirmSkipping;

  /// No description provided for @importCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get importCancel;

  /// No description provided for @importClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get importClose;

  /// No description provided for @importLocation.
  ///
  /// In en, this message translates to:
  /// **'{file}, line {line}'**
  String importLocation(String file, int line);

  /// No description provided for @snackImported.
  ///
  /// In en, this message translates to:
  /// **'Imported {items, plural, =1{1 subscription} other{{items} subscriptions}} and {payments, plural, =1{1 payment} other{{payments} payments}}'**
  String snackImported(int items, int payments);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t import. Nothing was changed.'**
  String get importFailed;

  /// No description provided for @importIssueNotUtf8.
  ///
  /// In en, this message translates to:
  /// **'This file isn’t UTF-8 text. In your spreadsheet, save it as “CSV UTF-8”.'**
  String get importIssueNotUtf8;

  /// No description provided for @importIssueUnclosedQuote.
  ///
  /// In en, this message translates to:
  /// **'A quote that opens on line {line} never closes.'**
  String importIssueUnclosedQuote(int line);

  /// No description provided for @importIssueStrayQuote.
  ///
  /// In en, this message translates to:
  /// **'There is a stray quote on line {line}.'**
  String importIssueStrayQuote(int line);

  /// No description provided for @importIssueTooManyRows.
  ///
  /// In en, this message translates to:
  /// **'The file has too many rows.'**
  String get importIssueTooManyRows;

  /// No description provided for @importIssueFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large to import.'**
  String get importIssueFileTooLarge;

  /// No description provided for @importIssueNotTrackly.
  ///
  /// In en, this message translates to:
  /// **'This doesn’t look like a Trackly file. It needs a first row naming the columns, such as name, amount, currency, frequency and next_due_date.'**
  String get importIssueNotTrackly;

  /// No description provided for @importIssueMissingColumn.
  ///
  /// In en, this message translates to:
  /// **'The column “{column}” is missing.'**
  String importIssueMissingColumn(String column);

  /// No description provided for @importIssueRequired.
  ///
  /// In en, this message translates to:
  /// **'“{column}” is empty.'**
  String importIssueRequired(String column);

  /// No description provided for @importIssueBadAmount.
  ///
  /// In en, this message translates to:
  /// **'“{value}” isn’t a valid amount in “{column}”. Use digits and a decimal point, like 15.49.'**
  String importIssueBadAmount(String value, String column);

  /// No description provided for @importIssueBadDate.
  ///
  /// In en, this message translates to:
  /// **'“{value}” isn’t a valid date in “{column}”. Use year-month-day, like 2026-10-31.'**
  String importIssueBadDate(String value, String column);

  /// No description provided for @importIssueBadChoice.
  ///
  /// In en, this message translates to:
  /// **'“{value}” isn’t allowed in “{column}”.'**
  String importIssueBadChoice(String value, String column);

  /// No description provided for @importIssueBadNumber.
  ///
  /// In en, this message translates to:
  /// **'“{value}” isn’t a valid number in “{column}”.'**
  String importIssueBadNumber(String value, String column);

  /// No description provided for @importIssueBadTime.
  ///
  /// In en, this message translates to:
  /// **'“{value}” isn’t a valid time. Use hours and minutes, like 09:00.'**
  String importIssueBadTime(String value);

  /// No description provided for @importIssueBadId.
  ///
  /// In en, this message translates to:
  /// **'“{value}” can’t be used as an id. Use letters, digits, - and _, up to 64 characters.'**
  String importIssueBadId(String value);

  /// No description provided for @importIssueTooLong.
  ///
  /// In en, this message translates to:
  /// **'“{column}” is too long.'**
  String importIssueTooLong(String column);

  /// No description provided for @importIssueTooManyFields.
  ///
  /// In en, this message translates to:
  /// **'This row has more values than there are columns. A name that contains a comma needs quotes around it.'**
  String get importIssueTooManyFields;

  /// No description provided for @importIssueDuplicateId.
  ///
  /// In en, this message translates to:
  /// **'The same id is used on line {otherLine}.'**
  String importIssueDuplicateId(int otherLine);

  /// No description provided for @importIssueTrialNeedsEnd.
  ///
  /// In en, this message translates to:
  /// **'A free trial needs a trial_end_date.'**
  String get importIssueTrialNeedsEnd;

  /// No description provided for @importIssueUnknownSubscription.
  ///
  /// In en, this message translates to:
  /// **'No subscription matches “{value}”. Import the subscriptions file too.'**
  String importIssueUnknownSubscription(String value);

  /// No description provided for @importIssueAmbiguousSubscription.
  ///
  /// In en, this message translates to:
  /// **'More than one subscription is named “{value}”. Add the subscription_id column.'**
  String importIssueAmbiguousSubscription(String value);

  /// No description provided for @importIssueUnknownCategory.
  ///
  /// In en, this message translates to:
  /// **'The category “{value}” doesn’t exist, so it was left empty.'**
  String importIssueUnknownCategory(String value);

  /// No description provided for @importIssueNoPaidDate.
  ///
  /// In en, this message translates to:
  /// **'No paid date, so the due date was used.'**
  String get importIssueNoPaidDate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
