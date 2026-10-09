import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum PillTone { success, warning, danger, neutral }

/// Informational status label. Always carries text, never color alone.
class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, required this.tone, super.key});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (foreground, darkBackground) = switch (tone) {
      PillTone.success => (TracklyColors.success, TracklyColors.successBg),
      PillTone.warning => (TracklyColors.warning, TracklyColors.warningBg),
      PillTone.danger => (TracklyColors.danger, TracklyColors.dangerBg),
      PillTone.neutral => (TracklyColors.neutral, TracklyColors.neutralBg),
    };
    // Light theme keeps the same semantics with a tinted background and a
    // darker foreground for contrast.
    final fg = dark ? foreground : Color.lerp(foreground, Colors.black, 0.4)!;
    final bg = dark ? darkBackground : foreground.withValues(alpha: 0.16);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TracklyRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ),
    );
  }
}
