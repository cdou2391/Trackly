import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/app_bottom_navigation.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/config/app_links.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/open_link.dart';
import '../../../shared/widgets/screen_header.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: EdgeInsets.only(
              bottom: TracklySpacing.xxl + navOverlayInset(context),
            ),
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
                    const SizedBox(height: TracklySpacing.sm),
                    _MoreTile(
                      icon: Icons.info_outline_rounded,
                      label: l10n.aboutTitle,
                      onTap: () => context.push(AppRoutes.about),
                    ),
                    const SizedBox(height: TracklySpacing.sm),
                    _MoreTile(
                      icon: Icons.privacy_tip_outlined,
                      label: l10n.privacyPolicy,
                      external: true,
                      onTap: () =>
                          openLink(context, ref, AppLinks.privacyPolicyUri),
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
    this.external = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Opens the browser rather than a screen in Trackly.
  final bool external;

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
                  external
                      ? Icons.open_in_new_rounded
                      : Icons.chevron_right_rounded,
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
