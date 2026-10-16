import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/screen_header.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // A subtle circle behind the icons where the theme asks for one.
    final style = IconButton.styleFrom(
      backgroundColor: tokens.headerIconFill,
      side: tokens.headerIconFill == Colors.transparent
          ? null
          : BorderSide(color: tokens.cardBorder),
    );

    return ScreenHeader(
      title: context.l10n.appName,
      subtitle: context.l10n.homeSubtitle,
      actions: [
        IconButton(
          tooltip: context.l10n.searchTooltip,
          icon: Icon(
            Icons.search_rounded,
            size: 26,
            color: tokens.headerIconColor,
          ),
          style: style,
          onPressed: () => context.push(AppRoutes.search),
        ),
        IconButton(
          tooltip: context.l10n.settingsTooltip,
          icon: Icon(
            Icons.settings_outlined,
            size: 26,
            color: tokens.headerIconColor,
          ),
          style: style,
          onPressed: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }
}
