import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/trackly_tokens.dart';
import '../../../../core/theme/trackly_type.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/recurrence_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../application/calendar_month.dart';

/// A month as a grid of days. Each day shows one small dot per kind of charge
/// on it (paid, due soon, overdue, skipped); the full detail, in words, is in
/// the list under the grid and in each day's screen-reader label.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    required this.data,
    required this.selected,
    required this.today,
    required this.onSelect,
    super.key,
  });

  final CalendarMonth data;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final first = data.month;
    final days = data.lastDay.day;

    // Weekday columns start on the locale's first day of the week.
    final firstDay = material.firstDayOfWeekIndex;
    final leading = ((first.weekday % 7) - firstDay + 7) % 7;
    final weeks = ((leading + days) / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: ExcludeSemantics(
                  child: Center(
                    child: Text(
                      material.narrowWeekdays[(firstDay + i) % 7],
                      style: sans(
                        12,
                        weight: 600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: TracklySpacing.xs),
        for (var week = 0; week < weeks; week++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _cell(context, week * 7 + column - leading + 1),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, int day) {
    if (day < 1 || day > data.lastDay.day) return const SizedBox(height: 52);

    final date = DateTime(data.month.year, data.month.month, day);
    return _DayCell(
      date: date,
      entries: data.entriesOn(date),
      isSelected: date == dateOnly(selected),
      isToday: date == dateOnly(today),
      onTap: () => onSelect(date),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.entries,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final List<CalendarEntry> entries;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  static const _circle = 34.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toString();

    // One dot per kind of charge, most urgent first.
    final kinds = <CalendarEntryStatus>[
      for (final status in const [
        CalendarEntryStatus.overdue,
        CalendarEntryStatus.due,
        CalendarEntryStatus.paid,
        CalendarEntryStatus.skipped,
      ])
        if (entries.any((e) => e.status == status)) status,
    ];

    final textColor = isSelected
        ? tokens.onPrimaryAction
        : theme.colorScheme.onSurface;

    return Semantics(
      label: context.l10n.calendarDayLabel(
        formatMediumDate(date, locale: locale),
        entries.length,
      ),
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TracklyRadius.small),
        child: SizedBox(
          height: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: _circle,
                height: _circle,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? tokens.primaryAction : null,
                  border: isToday && !isSelected
                      ? Border.all(color: tokens.accent, width: 1.5)
                      : null,
                ),
                child: Text(
                  '${date.day}',
                  style: sans(
                    14,
                    weight: isToday || isSelected ? 700 : 500,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final kind in kinds)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _dotColor(tokens, kind),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _dotColor(TracklyTokens tokens, CalendarEntryStatus status) {
    return switch (status) {
      CalendarEntryStatus.overdue => tokens.danger.fg,
      CalendarEntryStatus.due => tokens.warning.fg,
      CalendarEntryStatus.paid => tokens.success.fg,
      CalendarEntryStatus.skipped => tokens.neutral.fg,
    };
  }
}
