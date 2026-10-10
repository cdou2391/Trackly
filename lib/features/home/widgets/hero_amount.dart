import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../application/home_summary.dart';

/// The recurring-cost figures: label, the monthly amount, and the yearly
/// equivalent. With several currencies it lists them instead of inventing a
/// combined total.
class HeroAmount extends StatelessWidget {
  const HeroAmount({
    required this.summary,
    required this.defaultCurrency,
    super.key,
  });

  final HomeSummary summary;
  final String defaultCurrency;

  static const _maxCurrencyLines = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final secondary = theme.colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toString();

    final monthly = summary.monthlyTotalsByCurrency;
    final currencies = monthly.keys.toList()..sort();
    final single = currencies.length <= 1;
    final currency = single && currencies.isNotEmpty
        ? currencies.first
        : defaultCurrency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.heroLabel,
          style: sans(15, weight: 500, color: secondary, height: 1.3),
        ),
        const SizedBox(height: TracklySpacing.sm),
        if (single) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: formatMoney(
                  monthly[currency] ?? 0,
                  currency,
                  locale: locale,
                ),
                style: tokens.heroAmount,
                children: [
                  TextSpan(
                    text: ' ${l10n.heroMonthSuffix}',
                    style: tokens.heroAmountUnit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TracklySpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: tokens.success.fg,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l10n.heroPerYear(
                    formatMoney(
                      summary.yearlyTotalsByCurrency[currency] ?? 0,
                      currency,
                      locale: locale,
                    ),
                  ),
                  style: sans(16, color: secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ] else ...[
          for (final code in currencies.take(_maxCurrencyLines))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                formatMoney(monthly[code]!, code, locale: locale),
                style: theme.textTheme.headlineMedium,
              ),
            ),
          if (currencies.length > _maxCurrencyLines)
            Text(
              l10n.heroOtherCurrencies(currencies.length - _maxCurrencyLines),
              style: theme.textTheme.bodySmall,
            ),
        ],
      ],
    );
  }
}
