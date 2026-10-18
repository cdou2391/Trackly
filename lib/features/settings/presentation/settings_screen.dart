import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/app_bottom_navigation.dart';
import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/reminder_sync.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/picker_field.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/snack.dart';
import '../../../shared/widgets/sub_page_header.dart';
import '../../export/application/data_export.dart';
import '../../home/application/home_providers.dart';
import '../../import/application/data_import.dart';
import '../../import/presentation/import_preview_sheet.dart';
import '../../subscriptions/presentation/labels.dart';
import '../../privacy/application/privacy_choices.dart';
import '../application/data_reset.dart';
import '../application/settings_providers.dart';
import '../application/settings_store.dart';

/// Whether the phone currently lets Trackly show notifications.
final notificationsAllowedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(notificationServiceProvider).notificationsAllowed(),
);

/// Defaults for new subscriptions, appearance, notifications and data.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The user may have changed the permission in the phone's settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsAllowedProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                SubPageHeader(title: l10n.settingsTitle),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      TracklySpacing.base,
                      TracklySpacing.sm,
                      TracklySpacing.base,
                      TracklySpacing.xxl + navOverlayInset(context),
                    ),
                    children: [
                      SectionHeader(title: l10n.settingsSectionDefaults),
                      const SizedBox(height: TracklySpacing.sm),
                      const _Card(child: _DefaultsSection()),
                      const SizedBox(height: TracklySpacing.lg),
                      SectionHeader(title: l10n.settingsSectionAppearance),
                      const SizedBox(height: TracklySpacing.sm),
                      const _Card(child: _AppearanceSection()),
                      const SizedBox(height: TracklySpacing.lg),
                      SectionHeader(title: l10n.settingsSectionNotifications),
                      const SizedBox(height: TracklySpacing.sm),
                      const _Card(child: _NotificationsSection()),
                      const SizedBox(height: TracklySpacing.lg),
                      SectionHeader(title: l10n.settingsSectionPrivacy),
                      const SizedBox(height: TracklySpacing.sm),
                      const _Card(child: _PrivacySection()),
                      const SizedBox(height: TracklySpacing.lg),
                      SectionHeader(title: l10n.settingsSectionData),
                      const SizedBox(height: TracklySpacing.sm),
                      const _Card(child: _DataSection()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TracklySpacing.base),
        child: child,
      ),
    );
  }
}

class _DefaultsSection extends ConsumerWidget {
  const _DefaultsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currency = ref.watch(defaultCurrencyProvider);
    final reminder = ref.watch(defaultReminderProvider);
    final currencies = {...commonCurrencyCodes, currency}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('currency-$currency'),
          initialValue: currency,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.settingsCurrency),
          items: [
            for (final code in currencies)
              DropdownMenuItem(value: code, child: Text(code)),
          ],
          onChanged: (code) {
            if (code != null) {
              ref.read(defaultCurrencyProvider.notifier).set(code);
            }
          },
        ),
        const SizedBox(height: TracklySpacing.base),
        Text(
          l10n.settingsReminders,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: TracklySpacing.sm),
        Wrap(
          spacing: TracklySpacing.sm,
          children: [
            for (final days in reminderDayOptions)
              ChoiceChip(
                label: Text(
                  days == 0
                      ? l10n.reminderSameDay
                      : l10n.reminderDaysBefore(days),
                ),
                selected: reminder.days == days,
                onSelected: (_) =>
                    ref.read(defaultReminderProvider.notifier).setDays(days),
              ),
          ],
        ),
        const SizedBox(height: TracklySpacing.md),
        PickerField(
          label: l10n.addRemindAt,
          value: reminderTimeLabel(context, reminder.minuteOfDay),
          onTap: () => _pickTime(context, ref, reminder.minuteOfDay),
        ),
      ],
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    int minuteOfDay,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
      helpText: context.l10n.addRemindAt,
    );
    if (picked != null) {
      ref
          .read(defaultReminderProvider.notifier)
          .setMinuteOfDay(picked.hour * 60 + picked.minute);
    }
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(themeModeProvider);

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ThemeMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
          ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
          ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
        ],
        selected: {mode},
        onSelectionChanged: (selection) =>
            ref.read(themeModeProvider.notifier).set(selection.single),
      ),
    );
  }
}

class _NotificationsSection extends ConsumerStatefulWidget {
  const _NotificationsSection();

  @override
  ConsumerState<_NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<_NotificationsSection> {
  /// Set after the user answered the system prompt with "don't allow", when
  /// only the phone's own settings can turn notifications on.
  var _denied = false;

  Future<void> _turnOn() async {
    final analytics = ref.read(analyticsProvider);
    final service = ref.read(notificationServiceProvider);
    final sync = ref.read(reminderSyncProvider);

    unawaited(
      analytics.logEvent(AnalyticsEvents.notificationPermissionPrompted),
    );
    final granted = await service.requestPermission();
    unawaited(
      analytics.logEvent(
        granted
            ? AnalyticsEvents.notificationPermissionGranted
            : AnalyticsEvents.notificationPermissionDenied,
      ),
    );
    if (granted) await sync.reconcile();
    if (!mounted) return;
    ref.invalidate(notificationsAllowedProvider);
    setState(() => _denied = !granted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final allowed = ref.watch(notificationsAllowedProvider);

    if (allowed.isLoading && !allowed.hasValue) {
      return const SizedBox(height: 40);
    }
    final on = allowed.value ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: Icon(
                on
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: on
                    ? context.tokens.accent
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: TracklySpacing.md),
            Expanded(
              child: Text(
                on
                    ? l10n.settingsNotificationsOn
                    : l10n.settingsNotificationsOff,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        if (!on) ...[
          const SizedBox(height: TracklySpacing.md),
          FilledButton.tonal(
            onPressed: _turnOn,
            child: Text(l10n.settingsTurnOn),
          ),
        ],
        if (!on && _denied) ...[
          const SizedBox(height: TracklySpacing.sm),
          Text(l10n.settingsAllowInPhone, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: TracklySpacing.md),
        Text(l10n.settingsReminderDelay, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _PrivacySection extends ConsumerWidget {
  const _PrivacySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final choices = ref.watch(privacyChoicesProvider);
    final controller = ref.read(privacyChoicesProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          key: const Key('settings-usage-stats'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsUsageStats),
          subtitle: Text(l10n.settingsUsageStatsHint),
          value: choices.usageStatsOn,
          onChanged: controller.setUsageStats,
        ),
        SwitchListTile(
          key: const Key('settings-error-reports'),
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.settingsErrorReports),
          subtitle: Text(l10n.settingsErrorReportsHint),
          value: choices.errorReportsOn,
          onChanged: controller.setErrorReports,
        ),
        const SizedBox(height: TracklySpacing.xs),
        Text(
          l10n.settingsPrivacyNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      children: [
        _DataAction(
          icon: Icons.ios_share_rounded,
          label: l10n.settingsExport,
          hint: l10n.settingsExportHint,
          onTap: () => _export(context, ref),
        ),
        const Divider(height: TracklySpacing.lg),
        _DataAction(
          icon: Icons.file_open_outlined,
          label: l10n.settingsImport,
          hint: l10n.settingsImportHint,
          onTap: () => _import(context, ref),
        ),
        const Divider(height: TracklySpacing.lg),
        _DataAction(
          icon: Icons.history_toggle_off_rounded,
          label: l10n.settingsClearHistory,
          hint: l10n.settingsClearHistoryHint,
          onTap: () => _run(
            context,
            ref,
            title: l10n.clearHistoryDialogTitle,
            body: l10n.clearHistoryDialogBody,
            confirm: l10n.clearHistoryConfirm,
            success: l10n.snackHistoryCleared,
            action: (reset) => reset.clearHistory(),
          ),
        ),
        const Divider(height: TracklySpacing.lg),
        _DataAction(
          icon: Icons.delete_forever_rounded,
          label: l10n.settingsDeleteAll,
          hint: l10n.settingsDeleteAllHint,
          destructive: true,
          onTap: () => _run(
            context,
            ref,
            title: l10n.deleteAllDialogTitle,
            body: l10n.deleteAllDialogBody,
            confirm: l10n.deleteAllConfirm,
            success: l10n.snackAllDeleted,
            action: (reset) => reset.deleteEverything(),
          ),
        ),
      ],
    );
  }

  /// Shares every subscription and payment as CSV files. Nothing is deleted,
  /// so there is no confirmation; the share sheet is the last step.
  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final exporter = ref.read(dataExporterProvider);
    final analytics = ref.read(analyticsProvider);
    final now = ref.read(nowProvider)();

    try {
      final shared = await exporter.run(now: now, title: l10n.exportShareTitle);
      if (shared) {
        unawaited(analytics.logEvent(AnalyticsEvents.dataExported));
      } else {
        messenger.showReplacing(SnackBar(content: Text(l10n.exportNothing)));
      }
    } catch (_) {
      messenger.showReplacing(SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  /// Reads files the person picks, shows what they would add, and adds it only
  /// after a go-ahead. Nothing already in Trackly is changed or replaced.
  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final importer = ref.read(dataImporterProvider);
    final analytics = ref.read(analyticsProvider);

    try {
      final plan = await importer.prepare();
      if (plan == null || !context.mounted) return;

      final confirmed = await showImportPreview(context, plan);
      if (confirmed != true) return;

      final result = await importer.apply(plan);
      unawaited(analytics.logEvent(AnalyticsEvents.dataImported));
      messenger.showReplacing(
        SnackBar(
          content: Text(l10n.snackImported(result.items, result.payments)),
        ),
      );
    } catch (_) {
      messenger.showReplacing(SnackBar(content: Text(l10n.importFailed)));
    }
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String body,
    required String confirm,
    required String success,
    required Future<void> Function(DataReset reset) action,
  }) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final reset = ref.read(dataResetProvider);

    final confirmed = await confirmDialog(
      context,
      title: title,
      body: body,
      confirm: confirm,
      cancel: l10n.dialogKeep,
    );
    if (confirmed != true) return;

    try {
      await action(reset);
      messenger.showReplacing(SnackBar(content: Text(success)));
    } catch (_) {
      messenger.showReplacing(SnackBar(content: Text(l10n.actionFailed)));
    }
  }
}

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? context.tokens.danger.fg
        : theme.colorScheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(TracklyRadius.medium),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, color: color)),
            const SizedBox(width: TracklySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                  Text(hint, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
