import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/screen_header.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    // Search and settings screens are not built yet.
    return ScreenHeader(
      title: context.l10n.appName,
      subtitle: context.l10n.homeSubtitle,
      actions: [
        IconButton(
          tooltip: context.l10n.searchTooltip,
          icon: Icon(Icons.search_rounded, color: onSurface),
          onPressed: () {},
        ),
        IconButton(
          tooltip: context.l10n.settingsTooltip,
          icon: Icon(Icons.settings_rounded, color: onSurface),
          onPressed: () {},
        ),
      ],
    );
  }
}
