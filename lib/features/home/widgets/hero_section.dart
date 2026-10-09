import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../application/home_summary.dart';
import 'curves.dart';

/// Where the hero illustration SVG will live once it is added.
const heroIllustrationAsset = 'assets/illustrations/hero.svg';

class HeroSection extends StatelessWidget {
  const HeroSection({
    required this.summary,
    required this.defaultCurrency,
    super.key,
  });

  final HomeSummary summary;
  final String defaultCurrency;

  static const _waveHeight = 40.0;
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

    return ClipPath(
      clipper: const BottomWaveClipper(waveHeight: _waveHeight),
      child: ColoredBox(
        color: Theme.of(context).brightness == Brightness.dark
            ? TracklyColors.surface1
            : scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TracklySpacing.xl,
            TracklySpacing.lg,
            TracklySpacing.xl,
            TracklySpacing.lg + _waveHeight,
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
                      style: textTheme.labelMedium?.copyWith(letterSpacing: 1),
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
                          style: textTheme.displayLarge?.copyWith(fontSize: 40),
                        ),
                      ),
                      const SizedBox(height: TracklySpacing.sm),
                      Text(
                        l10n.heroPerYear(
                          formatMoney(
                            summary.yearlyTotalsByCurrency[currency] ?? 0,
                            currency,
                            locale: locale,
                          ),
                        ),
                        style: textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      for (final code in currencies.take(_maxCurrencyLines))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            formatMoney(monthly[code]!, code, locale: locale),
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
              const SizedBox(width: TracklySpacing.base),
              const _HeroIllustrationSlot(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder until the hero SVG ([heroIllustrationAsset]) is provided.
class _HeroIllustrationSlot extends StatelessWidget {
  const _HeroIllustrationSlot();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.autorenew_rounded, size: 44, color: scheme.primary),
      ),
    );
  }
}
