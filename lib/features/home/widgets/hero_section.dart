import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../application/home_summary.dart';

/// Decorative hero illustration (flat teal calendar card with a reminder bell).
const heroIllustrationAsset = 'assets/illustrations/hero.svg';

class HeroSection extends StatelessWidget {
  const HeroSection({
    required this.header,
    required this.summary,
    required this.defaultCurrency,
    super.key,
  });

  /// The page header, drawn on the same teal field as the amount.
  final Widget header;
  final HomeSummary summary;
  final String defaultCurrency;

  /// Keeps content readable on tablets; the teal itself stays full width.
  static const _maxContentWidth = 520.0;

  /// How far the bottom edge dips: the sides sit this much higher than the
  /// middle.
  static const _bottomSag = 36.0;
  static const _maxCurrencyLines = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final monthly = summary.monthlyTotalsByCurrency;
    final currencies = monthly.keys.toList()..sort();
    final single = currencies.length <= 1;
    final currency = single && currencies.isNotEmpty
        ? currencies.first
        : defaultCurrency;

    // A deep teal field (the brand accent, darkened) set against the black
    // page; its bottom edge is one wide sweeping arc.
    return ClipPath(
      clipper: const _SweepingBottomClipper(sag: _bottomSag),
      child: ColoredBox(
        color: Theme.of(context).brightness == Brightness.dark
            ? TracklyColors.heroSurface
            : scheme.surfaceContainerHighest,
        child: Padding(
          // The teal runs up behind the status bar, so the content starts
          // below it.
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top,
            bottom: _bottomSag + TracklySpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  header,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TracklySpacing.xl,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.heroLabel,
                                style: textTheme.labelMedium?.copyWith(
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: TracklySpacing.md),
                              if (single) ...[
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l10n.heroPerMonth(
                                      formatMoney(
                                        monthly[currency] ?? 0,
                                        currency,
                                        locale: locale,
                                      ),
                                    ),
                                    style: textTheme.displayLarge?.copyWith(
                                      fontSize: 40,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: TracklySpacing.sm),
                                Text(
                                  l10n.heroPerYear(
                                    formatMoney(
                                      summary.yearlyTotalsByCurrency[currency] ??
                                          0,
                                      currency,
                                      locale: locale,
                                    ),
                                  ),
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ] else ...[
                                for (final code in currencies.take(
                                  _maxCurrencyLines,
                                ))
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      formatMoney(
                                        monthly[code]!,
                                        code,
                                        locale: locale,
                                      ),
                                      style: textTheme.headlineMedium,
                                    ),
                                  ),
                                if (currencies.length > _maxCurrencyLines)
                                  Text(
                                    l10n.heroOtherCurrencies(
                                      currencies.length - _maxCurrencyLines,
                                    ),
                                    style: textTheme.bodySmall,
                                  ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: TracklySpacing.sm),
                        const _HeroIllustration(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Purely decorative, so it is hidden from screen readers.
///
/// The artwork is drawn larger than the room it reserves in the row, spilling
/// leftwards over its own transparent margin, so it can be big without
/// squeezing the amount.
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  static const _slotWidth = 120.0;
  static const _slotHeight = 108.0;
  static const _artWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _slotWidth,
        height: _slotHeight,
        child: OverflowBox(
          alignment: Alignment.centerRight,
          minWidth: _artWidth,
          maxWidth: _artWidth,
          minHeight: 0,
          maxHeight: _artWidth,
          child: SvgPicture.asset(heroIllustrationAsset, width: _artWidth),
        ),
      ),
    );
  }
}

/// Clips the bottom edge to one wide arc, edge to edge: the sides sit [sag]
/// higher than the middle, which is the lowest point.
class _SweepingBottomClipper extends CustomClipper<Path> {
  const _SweepingBottomClipper({required this.sag});

  final double sag;

  @override
  Path getClip(Size size) {
    final sides = size.height - sag;
    // A quadratic curve reaches only half-way to its control point, so the
    // control point sits `sag` below the bottom for the middle to land on it.
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, sides)
      ..quadraticBezierTo(size.width / 2, size.height + sag, 0, sides)
      ..close();
  }

  @override
  bool shouldReclip(_SweepingBottomClipper old) => old.sag != sag;
}
