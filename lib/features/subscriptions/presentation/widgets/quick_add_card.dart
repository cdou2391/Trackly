import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/recurrence_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/form_metrics.dart';
import '../../../home/application/home_providers.dart';
import '../../../home/widgets/curves.dart';
import '../../../settings/application/settings_providers.dart';
import '../../domain/recurring_enums.dart';
import '../../domain/service_catalog.dart';
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

    setState(() => _saving = true);
    try {
      final item = await ref
          .read(subscriptionCreatorProvider)
          .create(
            NewSubscription(
              name: _nameController.text,
              amount: amount,
              currencyCode: ref.read(defaultCurrencyProvider),
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
    final dark = theme.brightness == Brightness.dark;
    final suggestions = _selectedService == null
        ? searchServiceCatalog(_nameController.text)
        : const <CatalogService>[];

    final amountField = TextField(
      controller: _amountController,
      onChanged: (_) => _onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: l10n.quickAddAmount,
        constraints: kFormFieldConstraints,
      ),
    );

    final frequencyField = DropdownButtonFormField<BillingFrequency>(
      initialValue: _frequency,
      isExpanded: true,
      // Compact so the dropdown matches the text fields' height.
      isDense: true,
      decoration: InputDecoration(
        labelText: l10n.quickAddFrequency,
        constraints: kFormFieldConstraints,
      ),
      items: [
        for (final frequency in _quickFrequencies)
          DropdownMenuItem(
            value: frequency,
            child: Text(
              frequency.label(context),
              overflow: TextOverflow.ellipsis,
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

    final dateField = InkWell(
      borderRadius: BorderRadius.circular(TracklyRadius.medium),
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.quickAddStartDate,
          constraints: kFormFieldConstraints,
        ),
        child: Text(
          formatShortDate(_effectiveStart, locale: locale),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    final saveButton = FilledButton(
      onPressed: _canSave ? _save : null,
      // Tight padding so "Save" stays on one line in the compact row.
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: _saving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.quickAddSave, maxLines: 1, softWrap: false),
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
                // Row 1: service name and amount side by side.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameController,
                        onChanged: (_) => _onChanged(),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          constraints: kFormFieldConstraints,
                          hintText: l10n.quickAddServiceHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: TracklySpacing.sm),
                    Expanded(flex: 2, child: amountField),
                  ],
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
                // Row 2: frequency, start date and the Save button.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: frequencyField),
                    const SizedBox(width: TracklySpacing.sm),
                    Expanded(flex: 10, child: dateField),
                    const SizedBox(width: TracklySpacing.sm),
                    SizedBox(
                      width: 80,
                      height: kFormFieldHeight,
                      child: saveButton,
                    ),
                  ],
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
