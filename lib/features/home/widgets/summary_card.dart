import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../l10n/l10n.dart';

/// One of the Active / Trial / Cancelled cards on Home, and the count cards on
/// Insights: a tinted icon circle, the count, the label and, when the card can
/// be tapped, a chevron.
///
/// With room (about 118 dp and up, normal text size) the icon sits beside the
/// count; otherwise it stacks above it so the label never gets squeezed.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.icon,
    required this.tone,
    required this.count,
    required this.label,
    this.onTap,
    this.showChevron = true,
    this.semanticsLabel,
    super.key,
  });

  final IconData icon;
  final ToneColors tone;
  final int count;
  final String label;
  final VoidCallback? onTap;

  /// The small arrow that says the card opens something. Off for cards that
  /// only inform.
  final bool showChevron;

  /// Read by screen readers instead of "label, count".
  final String? semanticsLabel;

  /// Card width needed for the icon, "Cancelled", and the chevron side by side.
  static const _sideBySideWidth = 118.0;
  static const _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 12);

  /// Room the chevron takes beside the text.
  static const _chevronWidth = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chevron = Icon(
      Icons.chevron_right_rounded,
      size: 16,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final countText = Text(
      '$count',
      style: sans(
        24,
        weight: 700,
        color: theme.colorScheme.onSurface,
        height: 1.1,
      ),
    );
    final labelText = Text(
      label,
      style: sans(12.5, color: theme.colorScheme.onSurfaceVariant),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Semantics(
      container: true,
      label: semanticsLabel ?? context.l10n.statusCount(label, count),
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        clipBehavior: Clip.antiAlias,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: context.tokens.cardBorder),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: _padding,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale =
                    MediaQuery.textScalerOf(context).scale(13) / 13;
                final needed =
                    _sideBySideWidth -
                    _padding.horizontal -
                    (showChevron ? 0 : _chevronWidth);
                final fits =
                    constraints.maxWidth >= needed && textScale <= 1.15;
                if (fits) {
                  return Row(
                    children: [
                      _IconCircle(icon: icon, tone: tone, size: 30),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            countText,
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: labelText,
                            ),
                          ],
                        ),
                      ),
                      if (showChevron) chevron,
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _IconCircle(icon: icon, tone: tone, size: 36),
                        const Spacer(),
                        if (showChevron) chevron,
                      ],
                    ),
                    const SizedBox(height: TracklySpacing.sm),
                    countText,
                    labelText,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({
    required this.icon,
    required this.tone,
    required this.size,
  });

  final IconData icon;
  final ToneColors tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone.bg, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.55, color: tone.fg),
    );
  }
}
