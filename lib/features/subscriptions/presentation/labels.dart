import 'package:flutter/material.dart';

import '../../../core/utils/format_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../core/utils/cost_utils.dart';
import '../domain/recurring_enums.dart';
import '../domain/recurring_item.dart';

extension BillingFrequencyLabel on BillingFrequency {
  String label(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      BillingFrequency.weekly => l10n.frequencyWeekly,
      BillingFrequency.monthly => l10n.frequencyMonthly,
      BillingFrequency.quarterly => l10n.frequencyQuarterly,
      BillingFrequency.semiAnnual => l10n.frequencySemiAnnual,
      BillingFrequency.yearly => l10n.frequencyYearly,
      BillingFrequency.custom => l10n.frequencyCustom,
    };
  }
}

/// A reminder time such as "9:00 AM" or "18:30", in the phone's 12/24-hour
/// style.
String reminderTimeLabel(BuildContext context, int minuteOfDay) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

typedef DueStatus = ({String label, ChipTone tone, IconData icon});

/// Relative due label with a tone and icon: red with a bell when due today or
/// overdue, amber with a clock within a week, and a plain date (with the year)
/// on a neutral chip beyond that.
DueStatus dueStatus(BuildContext context, DateTime due, DateTime now) {
  final l10n = context.l10n;
  final days = daysBetween(now, due);
  if (days < 0) {
    return (
      label: l10n.overdue,
      tone: ChipTone.danger,
      icon: Icons.notifications_active_rounded,
    );
  }
  if (days == 0) {
    return (
      label: l10n.dueToday,
      tone: ChipTone.danger,
      icon: Icons.notifications_active_rounded,
    );
  }
  if (days == 1) {
    return (
      label: l10n.dueTomorrow,
      tone: ChipTone.danger,
      icon: Icons.notifications_active_rounded,
    );
  }
  if (days <= 7) {
    return (
      label: l10n.dueInDays(days),
      tone: ChipTone.warning,
      icon: Icons.schedule_rounded,
    );
  }
  final locale = Localizations.localeOf(context).toString();
  return (
    label: formatMediumDate(due, locale: locale),
    tone: ChipTone.neutral,
    icon: Icons.calendar_today_rounded,
  );
}

/// The status chips for an item: its due date (and Trial) while active, or
/// Paused / Cancelled otherwise.
List<StatusChip> itemChips(
  BuildContext context,
  RecurringItem item,
  DateTime now,
) {
  final l10n = context.l10n;
  switch (item.status) {
    case ItemStatus.cancelled:
      return [
        StatusChip(
          label: l10n.statusCancelled,
          tone: ChipTone.danger,
          icon: Icons.block_rounded,
        ),
      ];
    case ItemStatus.paused:
      return [
        StatusChip(
          label: l10n.pillPaused,
          tone: ChipTone.neutral,
          icon: Icons.pause_circle_outline_rounded,
        ),
      ];
    case ItemStatus.active:
      final due = dueStatus(context, item.nextDueDate, now);
      return [
        StatusChip(label: due.label, tone: due.tone, icon: due.icon),
        if (isInActiveTrial(item, now))
          StatusChip(
            label: l10n.pillTrial,
            tone: ChipTone.warning,
            icon: Icons.hourglass_bottom_rounded,
          ),
      ];
  }
}
