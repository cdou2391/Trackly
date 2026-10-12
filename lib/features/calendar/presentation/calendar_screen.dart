import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/error_reporter.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/currency_amounts.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../home/application/home_providers.dart';
import '../../home/widgets/subscription_row.dart';
import '../../settings/application/settings_providers.dart';
import '../../subscriptions/presentation/labels.dart';
import '../application/calendar_month.dart';
import '../application/calendar_providers.dart';
import 'widgets/calendar_grid.dart';

/// Keeps content readable on tablets and large phones.
const _maxContentWidth = 520.0;

/// Charges laid out on a month grid, with the month's total, what is left of
/// it from the chosen day, and the chosen day's charges listed underneath.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final today = dateOnly(ref.read(nowProvider)());
    _month = DateTime(today.year, today.month);
    _selected = today;
  }

  /// Opening the current month selects today; any other month selects its
  /// first day, so "left" then covers the whole month.
  void _showMonth(DateTime month) {
    final today = dateOnly(ref.read(nowProvider)());
    setState(() {
      _month = DateTime(month.year, month.month);
      _selected = (_month.year == today.year && _month.month == today.month)
          ? today
          : _month;
    });
  }

  void _step(int months) =>
      _showMonth(DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(ref.watch(nowProvider)());
    final calendar = ref.watch(calendarMonthProvider(_month));

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: calendar.when(
            data: (data) => _content(context, data, today),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) {
              ref
                  .read(errorReporterProvider)
                  .captureException(error, stackTrace);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, CalendarMonth data, DateTime today) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final onCurrentMonth =
        _month.year == today.year && _month.month == today.month;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() < 300) return;
        // Dragging left goes forward, as in a paper calendar (mirrored in RTL).
        final rtl = Directionality.of(context) == ui.TextDirection.rtl;
        _step((velocity < 0) != rtl ? 1 : -1);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          ScreenHeader(
            title: l10n.calendarTitle,
            icon: Icons.calendar_month_rounded,
          ),
          _MonthBar(
            month: _month,
            locale: locale,
            showToday: !onCurrentMonth,
            onPrevious: () => _step(-1),
            onNext: () => _step(1),
            onToday: () => _showMonth(today),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TracklySpacing.base,
              TracklySpacing.sm,
              TracklySpacing.base,
              0,
            ),
            child: _TotalsCard(data: data, selected: _selected, locale: locale),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TracklySpacing.md,
              TracklySpacing.base,
              TracklySpacing.md,
              0,
            ),
            child: CalendarGrid(
              data: data,
              selected: _selected,
              today: today,
              onSelect: (date) => setState(() => _selected = date),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TracklySpacing.base,
              TracklySpacing.xl,
              TracklySpacing.base,
              0,
            ),
            child: _DayCharges(
              entries: data.entriesOn(_selected),
              date: _selected,
              today: today,
              locale: locale,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.locale,
    required this.showToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final String locale;
  final bool showToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TracklySpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.calendarPrevMonth,
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                DateFormat.yMMMM(locale).format(month),
                textAlign: TextAlign.center,
                style: sans(
                  18,
                  weight: 600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (showToday)
            TextButton(
              onPressed: onToday,
              style: TextButton.styleFrom(foregroundColor: tokens.accentText),
              child: Text(l10n.calendarToday),
            ),
          IconButton(
            tooltip: l10n.calendarNextMonth,
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// The month's total and what is left from the chosen day, per currency.
class _TotalsCard extends ConsumerWidget {
  const _TotalsCard({
    required this.data,
    required this.selected,
    required this.locale,
  });

  final CalendarMonth data;
  final DateTime selected;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = ref.watch(defaultCurrencyProvider);
    final amountStyle = sans(
      22,
      weight: 700,
      color: theme.colorScheme.onSurface,
      height: 1.15,
    );
    final labelStyle = sans(
      13,
      weight: 500,
      color: theme.colorScheme.onSurfaceVariant,
    );

    Widget column(String label, Map<String, double> totals) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: TracklySpacing.xs),
          CurrencyAmounts(
            totals: totals,
            emptyCurrency: currency,
            style: amountStyle,
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(TracklyRadius.medium),
        border: Border.all(color: context.tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TracklySpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            column(l10n.calendarMonthTotal, data.totalByCurrency),
            const SizedBox(width: TracklySpacing.base),
            column(
              l10n.calendarLeftFrom(formatShortDate(selected, locale: locale)),
              data.leftFrom(selected),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCharges extends ConsumerWidget {
  const _DayCharges({
    required this.entries,
    required this.date,
    required this.today,
    required this.locale,
  });

  final List<CalendarEntry> entries;
  final DateTime date;
  final DateTime today;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: DateFormat.MMMEd(locale).format(date)),
        const SizedBox(height: TracklySpacing.sm),
        if (entries.isEmpty)
          Text(
            l10n.calendarNoCharges,
            style: sans(
              14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final entry in entries) ...[
            SubscriptionRow(
              item: entry.item,
              amount: entry.amount,
              chips: _chips(context, entry),
              onTap: () => context.push(AppRoutes.itemPath(entry.item.id)),
            ),
            const SizedBox(height: TracklySpacing.sm),
          ],
      ],
    );
  }

  List<StatusChip> _chips(BuildContext context, CalendarEntry entry) {
    final l10n = context.l10n;
    switch (entry.status) {
      case CalendarEntryStatus.paid:
        return [
          StatusChip(
            label: l10n.chipPaid,
            tone: ChipTone.success,
            icon: Icons.check_circle_rounded,
          ),
        ];
      case CalendarEntryStatus.skipped:
        return [
          StatusChip(
            label: l10n.skippedChip,
            tone: ChipTone.neutral,
            icon: Icons.skip_next_rounded,
          ),
        ];
      case CalendarEntryStatus.due:
      case CalendarEntryStatus.overdue:
        final due = dueStatus(context, entry.date, today);
        return [
          StatusChip(label: due.label, tone: due.tone, icon: due.icon),
          if (!entry.countsInTotal)
            StatusChip(
              label: l10n.pillTrial,
              tone: ChipTone.warning,
              icon: Icons.hourglass_bottom_rounded,
            ),
        ];
    }
  }
}
