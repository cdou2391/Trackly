import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/screen_header.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.only(bottom: TracklySpacing.xxl),
            children: [
              ScreenHeader(
                title: l10n.moreTitle,
                icon: Icons.more_horiz_rounded,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TracklySpacing.base,
                ),
                child: Column(
                  children: [
                    _MoreTile(
                      icon: Icons.list_alt_rounded,
                      label: l10n.allSubscriptionsTitle,
                      onTap: () => context.push(AppRoutes.subscriptionsPath()),
                    ),
                    const SizedBox(height: TracklySpacing.sm),
                    _MoreTile(
                      icon: Icons.history_rounded,
                      label: l10n.historyTitle,
                      onTap: () => context.push(AppRoutes.history),
                    ),
                    const SizedBox(height: TracklySpacing.sm),
                    _MoreTile(
                      icon: Icons.settings_rounded,
                      label: l10n.settingsTitle,
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TracklySpacing.base,
            vertical: TracklySpacing.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(icon, color: context.tokens.accent),
                ),
                const SizedBox(width: TracklySpacing.md),
                Expanded(
                  child: Text(label, style: theme.textTheme.titleMedium),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
