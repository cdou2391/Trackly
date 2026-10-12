import 'package:flutter/material.dart';

import '../../core/theme/trackly_tokens.dart';

/// Asks the user to confirm something that cannot be undone. Resolves to true
/// only when they pick the (red) confirm button.
Future<bool?> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  required String cancel,
}) {
  final danger = context.tokens.danger.fg;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: danger),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
}
