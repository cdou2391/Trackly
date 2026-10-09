/// Event names from the technical doc's analytics taxonomy.
///
/// Never attach subscription names, notes or other raw user text to events.
abstract final class AnalyticsEvents {
  static const appOpened = 'app_opened';

  static const subscriptionCreated = 'subscription_created';
  static const subscriptionUpdated = 'subscription_updated';
  static const subscriptionPaused = 'subscription_paused';
  static const subscriptionResumed = 'subscription_resumed';
  static const subscriptionCancelled = 'subscription_cancelled';
  static const subscriptionDeleted = 'subscription_deleted';

  static const billCreated = 'bill_created';

  static const trialCreated = 'trial_created';
  static const trialEnded = 'trial_ended';

  static const quickAddStarted = 'quick_add_started';
  static const quickAddCompleted = 'quick_add_completed';
  static const quickAddAbandoned = 'quick_add_abandoned';

  static const reminderEnabled = 'reminder_enabled';
  static const reminderDisabled = 'reminder_disabled';
  static const reminderScheduled = 'reminder_scheduled';
  static const reminderOpened = 'reminder_opened';

  static const paymentRecorded = 'payment_recorded';
  static const paymentSkipped = 'payment_skipped';

  static const homeOpened = 'home_opened';
  static const calendarOpened = 'calendar_opened';
  static const insightsOpened = 'insights_opened';
  static const historyOpened = 'history_opened';

  static const upcomingItemOpened = 'upcoming_item_opened';
  static const recentPaymentOpened = 'recent_payment_opened';

  static const notificationPermissionPrompted =
      'notification_permission_prompted';
  static const notificationPermissionGranted =
      'notification_permission_granted';
  static const notificationPermissionDenied = 'notification_permission_denied';

  static const currencyChanged = 'currency_changed';
  static const themeChanged = 'theme_changed';
}
