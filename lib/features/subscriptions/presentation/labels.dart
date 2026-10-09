import 'package:flutter/material.dart';

import '../../../core/utils/format_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/status_pill.dart';
import '../domain/recurring_enums.dart';

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

typedef DueStatus = ({String label, PillTone tone});

/// Relative due label with a tone: red when due today or overdue, amber when
/// due within a week, neutral (a plain date) beyond that.
DueStatus dueStatus(BuildContext context, DateTime due, DateTime now) {
  final l10n = context.l10n;
  final days = daysBetween(now, due);
  if (days < 0) return (label: l10n.overdue, tone: PillTone.danger);
  if (days == 0) return (label: l10n.dueToday, tone: PillTone.danger);
  if (days == 1) return (label: l10n.dueTomorrow, tone: PillTone.warning);
  if (days <= 7) {
    return (label: l10n.dueInDays(days), tone: PillTone.warning);
  }
  final locale = Localizations.localeOf(context).toString();
  return (label: formatShortDate(due, locale: locale), tone: PillTone.neutral);
}
