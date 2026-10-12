import 'package:flutter/material.dart';

import '../../core/utils/format_utils.dart';
import '../../l10n/l10n.dart';

/// One money line per currency (never a merged total), sorted by currency
/// code. Shows at most [maxLines] currencies, then "+ N other currencies".
///
/// With no amounts at all it shows zero in [emptyCurrency].
class CurrencyAmounts extends StatelessWidget {
  const CurrencyAmounts({
    required this.totals,
    required this.emptyCurrency,
    required this.style,
    this.maxLines = 3,
    super.key,
  });

  final Map<String, double> totals;
  final String emptyCurrency;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final currencies = totals.keys.toList()..sort();
    final shown = currencies.take(maxLines).toList();
    final hidden = currencies.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (currencies.isEmpty)
          _line(formatMoney(0, emptyCurrency, locale: locale))
        else
          for (final currency in shown)
            _line(formatMoney(totals[currency]!, currency, locale: locale)),
        if (hidden > 0)
          Text(
            context.l10n.heroOtherCurrencies(hidden),
            style: style.copyWith(
              fontSize: (style.fontSize ?? 16) * 0.7,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _line(String text) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(text, style: style, maxLines: 1),
  );
}
