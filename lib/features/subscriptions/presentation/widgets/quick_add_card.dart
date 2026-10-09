import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/error_reporter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/recurrence_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../../home/application/home_providers.dart';
import '../../../home/widgets/curves.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/recurring_enums.dart';
import '../../domain/recurring_item.dart';
import '../../domain/service_catalog.dart';
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
  DateTime get _effectiveStart => _startDate ?? _today;

  double? get _amount {
    final value = double.tryParse(_amountController.text.trim().replaceAll(',', '.'));
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
    final now = ref.read(nowProvider)();
    final start = _effectiveStart;
    final currency = ref.read(defaultCurrencyProvider);
    final service = _selectedService;

    final item = RecurringItem(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: RecurringItemType.subscription,
      amount: amount,
      currencyCode: currency,
      frequency: _frequency,
      startDate: start,
      nextDueDate: firstDueDate(
        startDate: start,
        frequency: _frequency,
        today: now,
      ),
      categoryId: service?.categoryId,
      logoKey: service?.key,
      createdAt: now,
      updatedAt: now,
    );

    setState(() => _saving = true);
    final errorReporter = ref.read(errorReporterProvider);
    final analytics = ref.read(analyticsProvider);
    try {
      errorReporter.addBreadcrumb('quick_add_save_started', category: 'ui');
      await ref.read(appDatabaseProvider).recurringItemsDao.insertItem(item);

      // Names and notes are never sent; only metadata.
      final parameters = <String, Object>{
        'item_type': item.type.name,
        'frequency': item.frequency.name,
        'currency': item.currencyCode,
        'has_reminder': item.remindersEnabled,
        'is_trial': item.isTrial,
        'entry_method': 'quick_add',
      };
      analytics.logEvent(AnalyticsEvents.quickAddCompleted);
      analytics.logEvent(
        AnalyticsEvents.subscriptionCreated,
        parameters: parameters,
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
    } catch (error, stackTrace) {
      await errorReporter.captureException(error, stackTrace);
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
    final dark = theme.brightness == Brightness.dark;
    final suggestions = _selectedService == null
        ? searchServiceCatalog(_nameController.text)
        : const <CatalogService>[];

    final amountField = TextField(
      controller: _amountController,
      onChanged: (_) => _onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: l10n.quickAddAmount),
    );

    final frequencyField = DropdownButtonFormField<BillingFrequency>(
      initialValue: _frequency,
      isExpanded: true,
      decoration: InputDecoration(labelText: l10n.quickAddFrequency),
      items: [
        for (final frequency in _quickFrequencies)
          DropdownMenuItem(
            value: frequency,
            child: Text(frequency.label(context), overflow: TextOverflow.ellipsis),
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

    final dateField = InkWell(
      borderRadius: BorderRadius.circular(TracklyRadius.medium),
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(labelText: l10n.quickAddStartDate),
        child: Text(
          formatShortDate(_effectiveStart, locale: locale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    final saveButton = FilledButton(
      onPressed: _canSave ? _save : null,
      child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.quickAddSave),
    );

    return Padding(
      padding: const EdgeInsets.only(top: TracklySpacing.xl),
      child: ClipPath(
        clipper: const TopWaveClipper(),
        // Material (not ColoredBox) so the suggestion tiles can paint ink.
        child: Material(
          color: dark
              ? TracklyColors.quickAddSurface
              : theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TracklySpacing.lg,
              TracklySpacing.xl + TracklySpacing.sm,
              TracklySpacing.lg,
              TracklySpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.quickAddTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: TracklySpacing.xs),
                Text(l10n.quickAddHelper, style: theme.textTheme.bodySmall),
                const SizedBox(height: TracklySpacing.base),
                TextField(
                  controller: _nameController,
                  onChanged: (_) => _onChanged(),
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l10n.quickAddServiceHint,
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
                const SizedBox(height: TracklySpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 340) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 10, child: amountField),
                          const SizedBox(width: TracklySpacing.sm),
                          Expanded(flex: 12, child: frequencyField),
                          const SizedBox(width: TracklySpacing.sm),
                          Expanded(flex: 11, child: dateField),
                          const SizedBox(width: TracklySpacing.sm),
                          SizedBox(width: 72, child: saveButton),
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
                            Expanded(child: saveButton),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                if (_savedMessage != null)
                  _Feedback(
                    icon: Icons.check_circle_rounded,
                    color: TracklyColors.success,
                    message: _savedMessage!,
                  ),
                if (_saveFailed)
                  _Feedback(
                    icon: Icons.error_rounded,
                    color: TracklyColors.danger,
                    message: l10n.quickAddSaveError,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
              child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
