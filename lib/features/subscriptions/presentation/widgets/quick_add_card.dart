import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/trackly_tokens.dart';
import '../../../../core/theme/trackly_type.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/recurrence_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/quick_add_fields.dart';
import '../../../home/application/home_providers.dart';
import '../../../home/widgets/curves.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/recurring_enums.dart';
import '../../domain/service_catalog.dart';
import '../../../../core/notifications/reminder_permission.dart';
import '../../application/subscription_creator.dart';
import '../labels.dart';

/// Frequencies offered inline; the rest live in the full add form.
const _quickFrequencies = [
  BillingFrequency.weekly,
  BillingFrequency.monthly,
  BillingFrequency.quarterly,
  BillingFrequency.yearly,
];

/// Inline form on Home to add a subscription in a few taps.
class QuickAddCard extends ConsumerStatefulWidget {
  const QuickAddCard({super.key});

  @override
  ConsumerState<QuickAddCard> createState() => _QuickAddCardState();
}

class _QuickAddCardState extends ConsumerState<QuickAddCard> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  CatalogService? _selectedService;
  BillingFrequency _frequency = BillingFrequency.monthly;
  DateTime? _startDate;

  bool _started = false;
  bool _saving = false;
  String? _savedMessage;
  bool _saveFailed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  DateTime get _today => dateOnly(ref.read(nowProvider)());

  /// The start date defaults to today; the field shows a "Start date"
  /// placeholder until the user picks one.
  DateTime get _effectiveStart => _startDate ?? _today;

  double? get _amount {
    final value = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    return value != null && value > 0 ? value : null;
  }

  bool get _canSave =>
      !_saving && _nameController.text.trim().isNotEmpty && _amount != null;

  void _markStarted() {
    if (_started) return;
    _started = true;
    ref.read(analyticsProvider).logEvent(AnalyticsEvents.quickAddStarted);
  }

  void _onChanged() {
    _markStarted();
    setState(() {
      _savedMessage = null;
      _saveFailed = false;
      // Typing past a chosen suggestion turns it back into a custom service.
      if (_selectedService != null &&
          _selectedService!.name != _nameController.text) {
        _selectedService = null;
      }
    });
  }

  void _selectService(CatalogService service) {
    _markStarted();
    setState(() {
      _selectedService = service;
      _nameController.text = service.name;
      _nameController.selection = TextSelection.collapsed(
        offset: service.name.length,
      );
    });
  }

  Future<void> _pickDate() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveStart,
      firstDate: DateTime(today.year - 10),
      lastDate: DateTime(today.year + 10),
    );
    if (picked != null && mounted) {
      _markStarted();
      setState(() {
        _startDate = picked;
        _savedMessage = null;
      });
    }
  }

  Future<void> _save() async {
    final amount = _amount;
    if (!_canSave || amount == null) return;

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final service = _selectedService;
    final navigator = Navigator.of(context, rootNavigator: true);
    final container = ProviderScope.containerOf(context);

    setState(() => _saving = true);
    try {
      final item = await ref
          .read(subscriptionCreatorProvider)
          .create(
            NewSubscription(
              name: _nameController.text,
              amount: amount,
              currencyCode: ref.read(defaultCurrencyProvider),
              reminderDaysBefore: ref.read(defaultReminderProvider).days,
              reminderMinuteOfDay: ref
                  .read(defaultReminderProvider)
                  .minuteOfDay,
              frequency: _frequency,
              startDate: _effectiveStart,
              categoryId: service?.categoryId,
              logoKey: service?.key,
              entryMethod: EntryMethod.quickAdd,
            ),
          );

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _saving = false;
        _savedMessage = l10n.quickAddSaved(
          formatShortDate(item.nextDueDate, locale: locale),
        );
        _nameController.clear();
        _amountController.clear();
        _selectedService = null;
        _startDate = null;
        _frequency = BillingFrequency.monthly;
        _started = false;
      });
      unawaited(offerReminders(navigator, container, item));
    } catch (_) {
      // The creator already reported the error.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final currency = ref.watch(defaultCurrencyProvider);
    final suggestions = _selectedService == null
        ? searchServiceCatalog(_nameController.text)
        : const <CatalogService>[];

    final nameField = QuickAddTextField(
      key: const Key('quick-add-name'),
      controller: _nameController,
      semanticLabel: l10n.quickAddServiceLabel,
      hint: l10n.quickAddServiceHint,
      prefixIcon: Icons.search_rounded,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      onChanged: (_) => _onChanged(),
    );

    final amountField = QuickAddTextField(
      key: const Key('quick-add-amount'),
      controller: _amountController,
      semanticLabel: l10n.quickAddAmount,
      hint: l10n.quickAddAmountHint,
      prefixText: currencySymbol(currency),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) => _onChanged(),
    );

    final frequencyField = QuickAddDropdown<BillingFrequency>(
      key: const Key('quick-add-frequency'),
      value: _frequency,
      semanticLabel: l10n.quickAddFrequency,
      items: [
        for (final frequency in _quickFrequencies)
          DropdownMenuItem(
            value: frequency,
            // Scales down a touch instead of cutting "Monthly" short.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(frequency.label(context)),
            ),
          ),
      ],
      onChanged: (value) {
        if (value == null) return;
        _markStarted();
        setState(() {
          _frequency = value;
          _savedMessage = null;
        });
      },
    );

    final dateField = QuickAddDateField(
      key: const Key('quick-add-date'),
      value: _startDate == null
          ? null
          : formatShortDate(_startDate!, locale: locale),
      hint: l10n.quickAddStartDate,
      semanticLabel: l10n.quickAddStartDate,
      onTap: _pickDate,
    );

    final saveButton = SizedBox(
      height: kQuickAddFieldHeight,
      child: FilledButton(
        key: const Key('quick-add-save'),
        onPressed: _canSave ? _save : null,
        // Tight padding so "Save" stays on one line in the compact row.
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(48, kQuickAddFieldHeight),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(l10n.quickAddSave, maxLines: 1, softWrap: false),
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.quickAddTitle, style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: TracklySpacing.xs),
        Text(
          l10n.quickAddHelper,
          style: sans(14, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: TracklySpacing.base),
        // Row 1: the service search, full width.
        nameField,
        for (final service in suggestions)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            minTileHeight: 48,
            title: Text(service.name),
            onTap: () => _selectService(service),
          ),
        const SizedBox(height: TracklySpacing.sm),
        // Row 2: amount, frequency, start date and Save.
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _singleRowWidth) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 9, child: amountField),
                  const SizedBox(width: TracklySpacing.sm),
                  Expanded(flex: 11, child: frequencyField),
                  const SizedBox(width: TracklySpacing.sm),
                  Expanded(flex: 11, child: dateField),
                  const SizedBox(width: TracklySpacing.sm),
                  SizedBox(width: 62, child: saveButton),
                ],
              );
            }
            // Narrow phones: wrap into two rows.
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: amountField),
                    const SizedBox(width: TracklySpacing.sm),
                    Expanded(child: frequencyField),
                  ],
                ),
                const SizedBox(height: TracklySpacing.sm),
                Row(
                  children: [
                    Expanded(child: dateField),
                    const SizedBox(width: TracklySpacing.sm),
                    SizedBox(width: 96, child: saveButton),
                  ],
                ),
              ],
            );
          },
        ),
        if (_savedMessage != null)
          _Feedback(
            icon: Icons.check_circle_rounded,
            color: tokens.success.fg,
            message: _savedMessage!,
          ),
        if (_saveFailed)
          _Feedback(
            icon: Icons.error_rounded,
            color: theme.colorScheme.error,
            message: l10n.quickAddSaveError,
          ),
      ],
    );

    if (tokens.quickAddWave) {
      // Dark: a full-width tinted panel with a shallow wave along its top.
      return Padding(
        padding: const EdgeInsets.only(top: TracklySpacing.xl),
        child: ClipPath(
          clipper: const TopWaveClipper(),
          // Material (not ColoredBox) so the suggestion tiles can paint ink.
          child: Material(
            color: tokens.quickAddFill,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TracklySpacing.lg,
                TracklySpacing.xl + TracklySpacing.sm,
                TracklySpacing.lg,
                TracklySpacing.xl,
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    // Light: a flat white card with a hairline border.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.base,
        TracklySpacing.xl,
        TracklySpacing.base,
        0,
      ),
      child: Material(
        color: tokens.quickAddFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TracklyRadius.section),
          side: BorderSide(color: tokens.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: content,
        ),
      ),
    );
  }

  /// Row width at which amount, frequency, date and Save share one row.
  static const _singleRowWidth = 350.0;
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TracklySpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: TracklySpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
