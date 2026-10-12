import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'form_metrics.dart';

/// A form field that looks like a text field but opens a picker (a date or a
/// time) when tapped.
class PickerField extends StatelessWidget {
  const PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
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
