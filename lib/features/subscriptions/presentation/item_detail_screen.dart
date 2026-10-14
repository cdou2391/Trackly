import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/recurrence_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/snack.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/service_icon.dart';
import '../../home/application/home_providers.dart';
import '../../payments/presentation/widgets/payment_row.dart';
import '../application/add_panel_controller.dart';
import '../application/categories_provider.dart';
import '../application/item_providers.dart';
import '../application/subscription_actions.dart';
import '../domain/recurring_enums.dart';
import '../domain/recurring_item.dart';
import 'labels.dart';

/// Keeps content readable on tablets and large phones.
const _maxContentWidth = 520.0;

/// One subscription or bill: its status, amount and schedule, the actions
/// (mark paid, skip, pause, resume, edit, cancel, delete) and its payment
/// history.
class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(itemProvider(itemId));

    // The edit panel is shown by the app frame, above the navigation bar.
    return Scaffold(
      body: item.when(
        data: (value) =>
            value == null ? const _Gone() : _DetailContent(item: value),
        loading: () =>
            const SafeArea(child: Center(child: CircularProgressIndicator())),
        error: (error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

/// The item no longer exists (it was deleted): leave the screen.
class _Gone extends StatefulWidget {
  const _Gone();

  @override
  State<_Gone> createState() => _GoneState();
}

class _GoneState extends State<_Gone> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.canPop()) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.item});

  final RecurringItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final now = ref.watch(nowProvider)();
    final payments = ref.watch(itemPaymentsProvider(item.id)).value ?? const [];

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TracklySpacing.base,
              0,
              TracklySpacing.base,
              TracklySpacing.xxl,
            ),
            children: [
              _TopBar(item: item),
              _Title(item: item, now: now),
              const SizedBox(height: TracklySpacing.base),
              _AmountCard(item: item, now: now),
              const SizedBox(height: TracklySpacing.base),
              _Actions(item: item),
              const SizedBox(height: TracklySpacing.xl),
              SectionHeader(title: l10n.paymentHistory),
              const SizedBox(height: TracklySpacing.sm),
              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: TracklySpacing.base,
                  ),
                  child: Text(
                    l10n.noPaymentsYet,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (final payment in payments) ...[
                  PaymentRow(payment: payment),
                  const SizedBox(height: TracklySpacing.sm),
                ],
              if ((item.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: TracklySpacing.base),
                _NotesCard(notes: item.notes!),
              ],
              const SizedBox(height: TracklySpacing.base),
              _DangerZone(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.item});

  final RecurringItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Row(
      children: [
        IconButton(
          tooltip: l10n.back,
          icon: Icon(Icons.arrow_back_rounded, color: onSurface),
          onPressed: () => context.pop(),
        ),
        const Spacer(),
        IconButton(
          tooltip: l10n.editTooltip,
          icon: Icon(Icons.edit_outlined, color: onSurface),
          onPressed: () =>
              ref.read(addPanelProvider.notifier).openForEdit(item),
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.item, required this.now});

  final RecurringItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ServiceIcon(
          logoKey: item.logoKey,
          categoryId: item.categoryId,
          size: 56,
        ),
        const SizedBox(width: TracklySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(item.name, style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: itemChips(context, item, now),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends ConsumerWidget {
  const _AmountCard({required this.item, required this.now});

  final RecurringItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final categoryName = categories
        .where((c) => c.id == item.categoryId)
        .map((c) => c.name)
        .firstOrNull;
    final cancelled = item.status == ItemStatus.cancelled;
    final trialRunning =
        item.isTrial &&
        item.trialEndDate != null &&
        !dateOnly(now).isAfter(dateOnly(item.trialEndDate!));

    // Before the due date there are two reminders (the day itself is at 9:00),
    // each on its own row; "same day" and "off" are a single row.
    final early = item.reminderDaysBefore > 0;
    final reminders = <String>[
      if (!item.remindersEnabled)
        l10n.reminderOff
      else ...[
        l10n.reminderWhenAt(
          early
              ? l10n.reminderDaysBefore(item.reminderDaysBefore)
              : l10n.reminderSameDay,
          reminderTimeLabel(context, item.reminderMinuteOfDay),
        ),
        if (early)
          l10n.reminderWhenAt(
            l10n.reminderOnTheDay,
            reminderTimeLabel(context, defaultReminderMinuteOfDay),
          ),
      ],
    ];

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TracklyRadius.large),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TracklySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                text: formatMoney(
                  item.amount,
                  item.currencyCode,
                  locale: locale,
                ),
                style: sans(
                  36,
                  weight: 700,
                  color: theme.colorScheme.onSurface,
                  height: 1.1,
                ),
                children: [
                  TextSpan(
                    text: '  ${item.frequency.label(context)}',
                    style: sans(
                      16,
                      weight: 500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trialRunning) ...[
              const SizedBox(height: TracklySpacing.xs),
              Text(
                '${l10n.trialEndsOn(formatMediumDate(item.trialEndDate!, locale: locale))} · '
                '${l10n.afterTrial(formatMoney(item.amount, item.currencyCode, locale: locale), item.frequency.label(context).toLowerCase())}',
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: TracklySpacing.base),
            Divider(color: tokens.cardBorder, height: 1),
            if (!cancelled)
              _InfoRow(
                icon: Icons.event_rounded,
                label: l10n.nextChargeLabel,
                value: formatMediumDate(item.nextDueDate, locale: locale),
              ),
            for (final (index, reminder) in reminders.indexed)
              _InfoRow(
                icon: Icons.notifications_none_rounded,
                label: reminders.length == 1
                    ? l10n.reminderLabel
                    : l10n.reminderNumbered(index + 1),
                value: reminder,
              ),
            _InfoRow(
              icon: Icons.receipt_long_outlined,
              label: l10n.typeLabel,
              value: item.type == RecurringItemType.bill
                  ? l10n.addTypeBill
                  : l10n.addTypeSubscription,
            ),
            if (categoryName != null)
              _InfoRow(
                icon: Icons.category_outlined,
                label: l10n.categoryLabel,
                value: categoryName,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: TracklySpacing.md),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: TracklySpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
          const SizedBox(width: TracklySpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: sans(15, weight: 600, color: theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TracklyRadius.large),
        side: BorderSide(color: context.tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TracklySpacing.base),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.notesLabel, style: theme.textTheme.labelMedium),
              const SizedBox(height: TracklySpacing.xs),
              Text(notes, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- actions

/// Runs [action], showing a failure message instead of crashing.
Future<void> _run(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = context.l10n.actionFailed;
  try {
    await action();
  } catch (_) {
    // The actions layer already reported the error.
    messenger.showReplacing(SnackBar(content: Text(message)));
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({required this.item});

  final RecurringItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final actions = ref.read(subscriptionActionsProvider);
    final locale = Localizations.localeOf(context).toString();

    Future<void> record(
      Future<PaymentOutcome> Function() action,
      String Function(String date) message,
    ) async {
      final messenger = ScaffoldMessenger.of(context);
      final undo = l10n.undo;
      final failed = l10n.actionFailed;
      final next = nextDueAfterPayment(item);
      try {
        final outcome = await action();
        messenger.showReplacing(
          SnackBar(
            content: Text(message(formatShortDate(next, locale: locale))),
            action: SnackBarAction(
              label: undo,
              onPressed: () => actions.undo(outcome),
            ),
          ),
        );
      } catch (_) {
        messenger.showReplacing(SnackBar(content: Text(failed)));
      }
    }

    switch (item.status) {
      case ItemStatus.cancelled:
        return const SizedBox.shrink();

      case ItemStatus.paused:
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.resumeAction),
            onPressed: () => _resume(context, ref),
          ),
        );

      case ItemStatus.active:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                icon: const Icon(Icons.check_rounded),
                label: Text(l10n.markAsPaid),
                onPressed: () =>
                    record(() => actions.markPaid(item), l10n.snackMarkedPaid),
              ),
            ),
            const SizedBox(height: TracklySpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.skip_next_rounded),
                    label: Text(l10n.skipCharge, textAlign: TextAlign.center),
                    onPressed: () =>
                        record(() => actions.skip(item), l10n.snackSkipped),
                  ),
                ),
                const SizedBox(width: TracklySpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.pause_rounded),
                    label: Text(l10n.pauseAction),
                    onPressed: () => _run(context, () async {
                      await actions.pause(item);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showReplacing(
                          SnackBar(content: Text(l10n.snackPaused)),
                        );
                      }
                    }),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  /// Resuming asks for the next charge date (the old one may be long past).
  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final actions = ref.read(subscriptionActionsProvider);
    final messenger = ScaffoldMessenger.of(context);
    final today = dateOnly(ref.read(nowProvider)());

    final picked = await showDatePicker(
      context: context,
      initialDate: defaultResumeDate(item, today),
      firstDate: DateTime(today.year - 1),
      lastDate: DateTime(today.year + 5),
      helpText: l10n.resumePickerHelp,
    );
    if (picked == null) return;

    try {
      await actions.resume(item, picked);
      messenger.showReplacing(
        SnackBar(
          content: Text(
            l10n.snackResumed(formatShortDate(picked, locale: locale)),
          ),
        ),
      );
    } catch (_) {
      messenger.showReplacing(SnackBar(content: Text(l10n.actionFailed)));
    }
  }
}

class _DangerZone extends ConsumerWidget {
  const _DangerZone({required this.item});

  final RecurringItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final danger = context.tokens.danger.fg;
    final actions = ref.read(subscriptionActionsProvider);

    TextStyle? style() => sans(15, weight: 600, color: danger);

    return Column(
      children: [
        if (item.status != ItemStatus.cancelled)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: danger),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirmed = await confirmDialog(
                context,
                title: l10n.cancelDialogTitle(item.name),
                body: l10n.cancelDialogBody,
                confirm: l10n.cancelDialogConfirm,
                cancel: l10n.dialogKeep,
              );
              if (confirmed != true) return;
              try {
                await actions.cancel(item);
                messenger.showReplacing(
                  SnackBar(content: Text(l10n.snackCancelled)),
                );
              } catch (_) {
                messenger.showReplacing(
                  SnackBar(content: Text(l10n.actionFailed)),
                );
              }
            },
            child: Text(l10n.cancelSubscription, style: style()),
          ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: danger),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final router = GoRouter.of(context);
            final confirmed = await confirmDialog(
              context,
              title: l10n.deleteDialogTitle(item.name),
              body: l10n.deleteDialogBody,
              confirm: l10n.deleteDialogConfirm,
              cancel: l10n.dialogNotNow,
            );
            if (confirmed != true) return;
            try {
              await actions.delete(item);
              if (router.canPop()) router.pop();
              messenger.showReplacing(
                SnackBar(content: Text(l10n.snackDeleted)),
              );
            } catch (_) {
              messenger.showReplacing(
                SnackBar(content: Text(l10n.actionFailed)),
              );
            }
          },
          child: Text(l10n.deleteItem, style: style()),
        ),
      ],
    );
  }
}

/// A confirmation dialog whose confirm button is styled as destructive.
