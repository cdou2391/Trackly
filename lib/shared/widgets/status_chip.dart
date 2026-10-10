import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/trackly_tokens.dart';
import '../../core/theme/trackly_type.dart';

enum ChipTone { success, warning, danger, neutral }

/// Informational status label. Always carries text (never color alone), with
/// an optional leading icon.
class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    required this.tone,
    this.icon,
    super.key,
  });

  final String label;
  final ChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final colors = switch (tone) {
      ChipTone.success => tokens.success,
      ChipTone.warning => tokens.warning,
      ChipTone.danger => tokens.danger,
      ChipTone.neutral => tokens.neutral,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(TracklyRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              ExcludeSemantics(child: Icon(icon, size: 14, color: colors.fg)),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: sans(12, weight: 600, color: colors.fg, height: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
