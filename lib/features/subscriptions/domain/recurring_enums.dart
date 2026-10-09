enum RecurringItemType { subscription, bill }

/// Trial is not a status: a trial is an active item with `isTrial` set.
enum ItemStatus { active, paused, cancelled }

/// `custom` means "every `interval` days" in v1.
enum BillingFrequency { weekly, monthly, quarterly, semiAnnual, yearly, custom }
