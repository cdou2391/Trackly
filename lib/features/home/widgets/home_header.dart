import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.lg,
        TracklySpacing.base,
        TracklySpacing.sm,
        TracklySpacing.base,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appName,
                  style: textTheme.headlineMedium,
                ),
                Text(context.l10n.homeSubtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
          // Search and settings screens are not built yet.
          IconButton(
            tooltip: context.l10n.searchTooltip,
            icon: Icon(Icons.search_rounded, color: scheme.onSurface),
            onPressed: () {},
          ),
          IconButton(
            tooltip: context.l10n.settingsTooltip,
            icon: Icon(Icons.settings_rounded, color: scheme.onSurface),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
