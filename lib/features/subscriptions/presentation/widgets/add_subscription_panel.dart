import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/recurrence_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/snack.dart';
import '../../../../shared/widgets/form_metrics.dart';
import '../../../home/application/home_providers.dart';
import '../../../settings/application/settings_providers.dart';
import '../../../../core/notifications/reminder_permission.dart';
import '../../application/add_panel_controller.dart';
import '../../application/categories_provider.dart';
import '../../application/subscription_actions.dart';
import '../../application/subscription_creator.dart';
import '../../application/subscription_edit.dart';
import '../../domain/recurring_enums.dart';
import '../../domain/recurring_item.dart';
import '../../domain/service_catalog.dart';
import '../labels.dart';

const _frequencies = [
  BillingFrequency.weekly,
  BillingFrequency.monthly,
  BillingFrequency.quarterly,
  BillingFrequency.semiAnnual,
  BillingFrequency.yearly,
];

/// Same day, 1, 3 or 7 days before.
const _reminderOptions = [0, 1, 3, 7];

/// The full add form, shown as a panel that slides up from the bottom
/// navigation. Quick Add on Home is the fast path; this has every field.
///
/// With [editing] set it edits that item instead: the same fields, filled in,
/// with the next charge date editable.
class AddSubscriptionPanel extends ConsumerStatefulWidget {
  const AddSubscriptionPanel({
    required this.maxHeight,
    this.editing,
    super.key,
  });

  final double maxHeight;
  final RecurringItem? editing;

  @override
  ConsumerState<AddSubscriptionPanel> createState() =>
      _AddSubscriptionPanelState();
}

class _AddSubscriptionPanelState extends ConsumerState<AddSubscriptionPanel> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  CatalogService? _selectedService;
  RecurringItemType _type = RecurringItemType.subscription;
  late String _currency = ref.read(defaultCurrencyProvider);
  BillingFrequency _frequency = BillingFrequency.monthly;
  DateTime? _startDate;

  /// Editing only: the next charge date.
  DateTime? _nextDue;
  bool _isTrial = false;
  DateTime? _trialEnd;
  bool _remindersEnabled = true;
  int _reminderDays = 3;
  String? _categoryId;

  bool _saving = false;
  bool _saveFailed = false;

  RecurringItem? get _editing => widget.editing;

  @override
  void initState() {
    super.initState();
    final item = _editing;
    if (item == null) return;
    _nameController.text = item.name;
    _amountController.text = _formatAmount(item.amount);
    _notesController.text = item.notes ?? '';
    final service = item.logoKey == null
        ? null
        : serviceCatalogByKey[item.logoKey];
    _selectedService = service?.name == item.name ? service : null;
    _type = item.type;
    _currency = item.currencyCode;
    _frequency = item.frequency;
    _nextDue = item.nextDueDate;
    _isTrial = item.isTrial;
    _trialEnd = item.trialEndDate;
    _remindersEnabled = item.remindersEnabled;
    _reminderDays = item.reminderDaysBefore;
    _categoryId = item.categoryId;
  }

  /// "15.49" and "35" (no trailing ".0") for the amount field.
  static String _formatAmount(double amount) {
    final text = amount.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  DateTime get _today => dateOnly(ref.read(nowProvider)());
  DateTime get _effectiveStart => _startDate ?? _today;

  double? get _amount {
    final value = double.tryParse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    return value != null && value > 0 ? value : null;
  }

  bool get _canSave =>
      !_saving &&
      _nameController.text.trim().isNotEmpty &&
      _amount != null &&
      (!_isTrial || _trialEnd != null);

  void _onChanged() {
    setState(() {
      _saveFailed = false;
      // Typing past a chosen suggestion turns it back into a custom service.
      if (_selectedService != null &&
          _selectedService!.name != _nameController.text) {
        _selectedService = null;
      }
    });
  }

  void _selectService(CatalogService service) {
    setState(() {
      _selectedService = service;
      _nameController.text = service.name;
      _nameController.selection = TextSelection.collapsed(
        offset: service.name.length,
      );
      _categoryId ??= service.categoryId;
    });
  }

  Future<DateTime?> _pickDate({
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
  }

  /// The start date when adding; the next charge when editing.
  DateTime get _mainDate =>
      _editing != null ? (_nextDue ?? _editing!.nextDueDate) : _effectiveStart;

  Future<void> _pickStartDate() async {
    final today = _today;
    final picked = await _pickDate(
      initial: _mainDate,
      first: DateTime(today.year - 10),
      last: DateTime(today.year + 10),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (_editing != null) {
        _nextDue = picked;
      } else {
        _startDate = picked;
      }
    });
  }

  Future<void> _pickTrialEnd() async {
    final today = _today;
    final picked = await _pickDate(
      initial: _trialEnd ?? today,
      first: today,
      last: DateTime(today.year + 2),
    );
    if (picked != null && mounted) setState(() => _trialEnd = picked);
  }

  Future<void> _saveEdit(double amount) async {
    final original = _editing!;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final closePanel = ref.read(addPanelProvider.notifier).close;
    final service = _selectedService;
    final navigator = Navigator.of(context, rootNavigator: true);
    final container = ProviderScope.containerOf(context);

    setState(() => _saving = true);
    try {
      final edited = buildEditedItem(
        original,
        EditedSubscription(
          name: _nameController.text,
          type: _type,
          amount: amount,
          currencyCode: _currency,
          frequency: _frequency,
          nextDueDate: _mainDate,
          remindersEnabled: _remindersEnabled,
          reminderDaysBefore: _reminderDays,
          isTrial: _isTrial,
          trialEndDate: _trialEnd,
          categoryId: _categoryId,
          // Keep the logo while the name is unchanged; a renamed custom item
          // no longer matches it.
          logoKey:
              service?.key ??
              (_nameController.text.trim() == original.name
                  ? original.logoKey
                  : null),
          notes: _notesController.text,
        ),
        now: ref.read(nowProvider)(),
      );
      await ref.read(subscriptionActionsProvider).update(edited);

      messenger.showReplacing(SnackBar(content: Text(l10n.editSaved)));
      closePanel();
      unawaited(offerReminders(navigator, container, edited));
    } catch (_) {
      // The actions layer already reported the error.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  Future<void> _save() async {
    final amount = _amount;
    if (!_canSave || amount == null) return;
    if (_editing != null) return _saveEdit(amount);

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    // Captured before the panel closes and is disposed.
    final messenger = ScaffoldMessenger.of(context);
    final closePanel = ref.read(addPanelProvider.notifier).close;
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
              type: _type,
              amount: amount,
              currencyCode: _currency,
              frequency: _frequency,
              startDate: _effectiveStart,
              categoryId: _categoryId,
              logoKey: service?.key,
              remindersEnabled: _remindersEnabled,
              reminderDaysBefore: _reminderDays,
              isTrial: _isTrial,
              trialEndDate: _trialEnd,
              notes: _notesController.text,
              entryMethod: EntryMethod.fullForm,
            ),
          );

      messenger.showReplacing(
        SnackBar(
          content: Text(
            l10n.quickAddSaved(
              formatShortDate(item.nextDueDate, locale: locale),
            ),
          ),
        ),
      );
      closePanel();
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
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final suggestions = _selectedService == null
        ? searchServiceCatalog(_nameController.text)
        : const <CatalogService>[];
    final currencies = {...commonCurrencyCodes, _currency}.toList();

    return Material(
      key: const Key('add-panel'),
      color: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TracklyRadius.section),
        ),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: TracklySpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TracklySpacing.lg,
                TracklySpacing.md,
                TracklySpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        _editing != null
                            ? l10n.editSubscriptionTitle
                            : l10n.addSubscriptionTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.addPanelClose,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: ref.read(addPanelProvider.notifier).close,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  TracklySpacing.lg,
                  TracklySpacing.sm,
                  TracklySpacing.lg,
                  TracklySpacing.base,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<RecurringItemType>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: RecurringItemType.subscription,
                            label: Text(l10n.addTypeSubscription),
                          ),
                          ButtonSegment(
                            value: RecurringItemType.bill,
                            label: Text(l10n.addTypeBill),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (value) =>
                            setState(() => _type = value.single),
                      ),
                    ),
                    const SizedBox(height: TracklySpacing.base),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => _onChanged(),
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        constraints: kFormFieldConstraints,
                        hintText: l10n.addNameHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    for (final service in suggestions)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        minTileHeight: 48,
                        title: Text(service.name),
                        onTap: () => _selectService(service),
                      ),
                    const SizedBox(height: TracklySpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _amountController,
                            onChanged: (_) => _onChanged(),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.quickAddAmount,
                              constraints: kFormFieldConstraints,
                            ),
                          ),
                        ),
                        const SizedBox(width: TracklySpacing.sm),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _currency,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: l10n.addCurrency,
                              constraints: kFormFieldConstraints,
                            ),
                            items: [
                              for (final code in currencies)
                                DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _currency = value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    _SectionLabel(l10n.addSectionBilling),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<BillingFrequency>(
                            initialValue: _frequency,
                            isExpanded: true,
                            isDense: true,
                            decoration: InputDecoration(
                              labelText: l10n.quickAddFrequency,
                              constraints: kFormFieldConstraints,
                            ),
                            items: [
                              for (final frequency in _frequencies)
                                DropdownMenuItem(
                                  value: frequency,
                                  child: Text(
                                    frequency.label(context),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _frequency = value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: TracklySpacing.sm),
                        Expanded(
                          child: _isTrial
                              ? _DateField(
                                  label: l10n.addTrialEnds,
                                  value: _trialEnd == null
                                      ? null
                                      : formatShortDate(
                                          _trialEnd!,
                                          locale: locale,
                                        ),
                                  onTap: _pickTrialEnd,
                                )
                              : _DateField(
                                  // Adding: when billing started. Editing:
                                  // when the next charge is due.
                                  label: _editing != null
                                      ? l10n.editNextCharge
                                      : l10n.quickAddStartDate,
                                  value: formatShortDate(
                                    _mainDate,
                                    locale: locale,
                                  ),
                                  onTap: _pickStartDate,
                                ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.addTrialSwitch),
                      value: _isTrial,
                      onChanged: (value) => setState(() => _isTrial = value),
                    ),
                    _SectionLabel(l10n.addSectionReminder),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.addRemindMe),
                      value: _remindersEnabled,
                      onChanged: (value) =>
                          setState(() => _remindersEnabled = value),
                    ),
                    if (_remindersEnabled)
                      Wrap(
                        spacing: TracklySpacing.sm,
                        children: [
                          for (final days in _reminderOptions)
                            ChoiceChip(
                              label: Text(
                                days == 0
                                    ? l10n.reminderSameDay
                                    : l10n.reminderDaysBefore(days),
                              ),
                              selected: _reminderDays == days,
                              onSelected: (_) =>
                                  setState(() => _reminderDays = days),
                            ),
                        ],
                      ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(
                        bottom: TracklySpacing.sm,
                      ),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(l10n.addMoreDetails),
                      children: [
                        DropdownButtonFormField<String?>(
                          initialValue: _categoryId,
                          isExpanded: true,
                          isDense: true,
                          decoration: InputDecoration(
                            labelText: l10n.addCategory,
                            constraints: kFormFieldConstraints,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.addCategoryNone),
                            ),
                            for (final category in categories)
                              DropdownMenuItem<String?>(
                                value: category.id,
                                child: Text(category.name),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _categoryId = value),
                        ),
                        const SizedBox(height: TracklySpacing.sm),
                        TextField(
                          controller: _notesController,
                          minLines: 2,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(labelText: l10n.addNotes),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TracklySpacing.lg,
                TracklySpacing.sm,
                TracklySpacing.lg,
                TracklySpacing.base,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_saveFailed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: TracklySpacing.sm),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          l10n.quickAddSaveError,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: kFormFieldHeight,
                    child: FilledButton(
                      onPressed: _canSave ? _save : null,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _editing != null
                                  ? l10n.editSaveChanges
                                  : l10n.quickAddSave,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: TracklySpacing.base,
        bottom: TracklySpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(letterSpacing: 0.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(TracklyRadius.medium),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          constraints: kFormFieldConstraints,
        ),
        child: Text(value ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
