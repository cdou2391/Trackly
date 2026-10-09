import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Page header shared by every screen, so titles keep one size and position.
///
/// Optional [icon] sits to the left of the title; [actions] sit on the right.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        TracklySpacing.lg,
        TracklySpacing.base,
        actions.isEmpty ? TracklySpacing.lg : TracklySpacing.sm,
        TracklySpacing.base,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            ExcludeSemantics(
              child: Icon(icon, size: 28, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: TracklySpacing.md),
          ],
          Expanded(
            child: Column(
              // Shrink-wrap: inside a loosely bounded parent a max-size Column
              // would fill the screen and push the icon to mid-height.
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(title, style: theme.textTheme.headlineMedium),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}
