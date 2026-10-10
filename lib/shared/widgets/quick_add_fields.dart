import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/trackly_type.dart';

/// Height shared by every Quick Add field and its Save button.
const kQuickAddFieldHeight = 48.0;

const _compactPadding = EdgeInsets.symmetric(horizontal: 10, vertical: 12);

InputDecoration _decoration(
  BuildContext context, {
  String? hint,
  Widget? prefixIcon,
  double prefixWidth = 40,
  String? prefixText,
}) {
  final theme = Theme.of(context);
  return InputDecoration(
    constraints: const BoxConstraints.tightFor(height: kQuickAddFieldHeight),
    contentPadding: _compactPadding,
    hintText: hint,
    hintStyle: sans(14, color: theme.inputDecorationTheme.hintStyle?.color),
    prefixIcon: prefixIcon,
    prefixIconConstraints: BoxConstraints(minWidth: prefixWidth, minHeight: 40),
    prefixText: prefixText,
  );
}

/// A single-line text field for the Quick Add form.
class QuickAddTextField extends StatelessWidget {
  const QuickAddTextField({
    required this.controller,
    required this.semanticLabel,
    required this.onChanged,
    this.hint,
    this.prefixIcon,
    this.prefixText,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    super.key,
  });

  final TextEditingController controller;

  /// Read by screen readers; the visible text is only a hint.
  final String semanticLabel;
  final ValueChanged<String> onChanged;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefixText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      textField: true,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        style: sans(14, color: Theme.of(context).colorScheme.onSurface),
        decoration: _decoration(
          context,
          hint: hint,
          prefixIcon: prefixText != null
              // Always visible (a prefixText would only show while typing).
              ? Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      prefixText!,
                      style: sans(
                        14,
                        weight: 500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                )
              : prefixIcon == null
              ? null
              : Icon(prefixIcon, size: 20),
          prefixWidth: prefixText == null ? 40 : 18,
        ),
      ),
    );
  }
}

/// A dropdown field for the Quick Add form.
class QuickAddDropdown<T> extends StatelessWidget {
  const QuickAddDropdown({
    required this.value,
    required this.items,
    required this.semanticLabel,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final String semanticLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: semanticLabel,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        isDense: true,
        iconSize: 20,
        icon: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: scheme.onSurfaceVariant,
        ),
        style: sans(14, color: scheme.onSurface),
        decoration: _decoration(context),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// A tappable date field (opens a date picker) for the Quick Add form. Shows
/// [hint] until a date is chosen.
class QuickAddDateField extends StatelessWidget {
  const QuickAddDateField({
    required this.value,
    required this.hint,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String? value;
  final String hint;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null;

    return Semantics(
      button: true,
      label: semanticLabel,
      value: value,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ExcludeSemantics(
          child: InputDecorator(
            decoration: _decoration(
              context,
              prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
              prefixWidth: 28,
            ),
            // Scales down a touch instead of cutting "Start date" short.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value ?? hint,
                maxLines: 1,
                style: sans(
                  14,
                  color: hasValue
                      ? scheme.onSurface
                      : Theme.of(context).inputDecorationTheme.hintStyle?.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
