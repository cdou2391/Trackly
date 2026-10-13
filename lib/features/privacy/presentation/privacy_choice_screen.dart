import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/config/app_links.dart';
import '../../../core/startup/splash_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/open_link.dart';
import '../application/privacy_choices.dart';

/// Shown once, on the first launch, before anything is sent anywhere. It says
/// what Trackly can send and lets the person say yes or no with equal weight.
/// The choice can be changed at any time in Settings.
class PrivacyChoiceScreen extends ConsumerWidget {
  const PrivacyChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(privacyChoicesProvider.notifier);

    return Scaffold(
      key: const Key('privacy-choice'),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TracklySpacing.lg,
                      TracklySpacing.xl,
                      TracklySpacing.lg,
                      TracklySpacing.base,
                    ),
                    children: [
                      Center(
                        child: ExcludeSemantics(
                          child: SvgPicture.asset(
                            SplashScreen.logoAsset,
                            width: 72,
                          ),
                        ),
                      ),
                      const SizedBox(height: TracklySpacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.privacyChoiceTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                      ),
                      const SizedBox(height: TracklySpacing.md),
                      Text(
                        l10n.privacyChoiceIntro,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: TracklySpacing.lg),
                      Text(
                        l10n.privacyChoiceAsk,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: TracklySpacing.sm),
                      _Collected(
                        icon: Icons.insights_rounded,
                        title: l10n.privacyChoiceUsageTitle,
                        body: l10n.privacyChoiceUsageBody,
                      ),
                      const SizedBox(height: TracklySpacing.sm),
                      _Collected(
                        icon: Icons.bug_report_outlined,
                        title: l10n.privacyChoiceErrorsTitle,
                        body: l10n.privacyChoiceErrorsBody,
                      ),
                      const SizedBox(height: TracklySpacing.lg),
                      Text(
                        l10n.privacyChoiceNothing,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: TracklySpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: () =>
                              openLink(context, ref, AppLinks.privacyPolicyUri),
                          child: Text(l10n.privacyChoiceRead),
                        ),
                      ),
                    ],
                  ),
                ),
                // Both answers look and weigh the same: neither is the
                // "default" button, and saying no costs one tap.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TracklySpacing.lg,
                    TracklySpacing.sm,
                    TracklySpacing.lg,
                    TracklySpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.tonal(
                        key: const Key('privacy-allow'),
                        style: _buttonStyle,
                        onPressed: () => controller.chooseAll(true),
                        child: Text(l10n.privacyChoiceAllow),
                      ),
                      const SizedBox(height: TracklySpacing.sm),
                      FilledButton.tonal(
                        key: const Key('privacy-decline'),
                        style: _buttonStyle,
                        onPressed: () => controller.chooseAll(false),
                        child: Text(l10n.privacyChoiceDecline),
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

  static final _buttonStyle = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
  );
}

class _Collected extends StatelessWidget {
  const _Collected({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: context.tokens.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TracklySpacing.base),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, color: context.tokens.accent)),
            const SizedBox(width: TracklySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: TracklySpacing.xs),
                  Text(body, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
