import 'package:flutter/material.dart';

import '../../core/theme/trackly_tokens.dart';
import '../../core/theme/trackly_type.dart';

/// A compact pill for choosing a filter. Sized to its label (at least 48 dp
/// wide and 44 dp tall to tap), with the selected state shown by color.
class FilterPill extends StatelessWidget {
  const FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? tokens.primaryAction : theme.colorScheme.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? Colors.transparent : tokens.cardBorder,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: sans(
                    14,
                    weight: 600,
                    color: selected
                        ? tokens.onPrimaryAction
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
