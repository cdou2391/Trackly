import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/config/app_links.dart';
import '../../../core/startup/splash_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/open_link.dart';
import '../../../shared/widgets/sub_page_header.dart';
import '../application/app_info.dart';

/// The app's name, version, who makes it, and where to find the policy and
/// support.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final info = ref.watch(appInfoProvider).value;
    final version = info?.label ?? '';

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                SubPageHeader(title: l10n.aboutTitle),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TracklySpacing.base,
                      TracklySpacing.lg,
                      TracklySpacing.base,
                      TracklySpacing.xxl,
                    ),
                    children: [
                      Center(
                        child: ExcludeSemantics(
                          child: SvgPicture.asset(
                            SplashScreen.logoAsset,
                            width: 96,
                          ),
                        ),
                      ),
                      const SizedBox(height: TracklySpacing.md),
                      Center(
                        child: Text(
                          l10n.appName,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: TracklySpacing.xs),
                      Center(
                        child: Text(
                          l10n.appTagline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      if (version.isNotEmpty) ...[
                        const SizedBox(height: TracklySpacing.sm),
                        Center(
                          child: Text(
                            l10n.aboutVersion(version),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                      const SizedBox(height: TracklySpacing.xl),
                      _AboutCard(
                        children: [
                          _AboutRow(
                            icon: Icons.privacy_tip_outlined,
                            label: l10n.privacyPolicy,
                            external: true,
                            onTap: () => openLink(
                              context,
                              ref,
                              AppLinks.privacyPolicyUri,
                            ),
                          ),
                          const Divider(height: 1),
                          _AboutRow(
                            icon: Icons.mail_outline_rounded,
                            label: l10n.aboutContact,
                            hint: AppLinks.supportEmail,
                            onTap: () =>
                                openLink(context, ref, AppLinks.supportUri),
                          ),
                          const Divider(height: 1),
                          _AboutRow(
                            icon: Icons.description_outlined,
                            label: l10n.aboutLicenses,
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: l10n.appName,
                              applicationVersion: version.isEmpty
                                  ? null
                                  : version,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TracklySpacing.lg),
                      Center(
                        child: Text(
                          l10n.aboutMadeBy,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
    this.external = false,
  });

  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback onTap;

  /// Opens another app or the browser, rather than a screen in Trackly.
  final bool external;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TracklySpacing.base,
            vertical: TracklySpacing.sm,
          ),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, color: context.tokens.accent)),
              const SizedBox(width: TracklySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.titleMedium),
                    if (hint != null)
                      Text(hint!, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  external
                      ? Icons.open_in_new_rounded
                      : Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
