import 'package:flutter/material.dart';

import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/service_icon.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../subscriptions/domain/recurring_item.dart';
import '../../subscriptions/presentation/labels.dart';

/// One row for both Upcoming charges and Recent payments, so the two lists
/// share a single style: icon, name and "Monthly • USD", a status chip, the
/// amount and a chevron.
///
/// With room the chip sits between the name and the amount; when the real text
/// would not fit (a long name, a narrow screen, large text) it drops under the
/// name so nothing is cut short.
class SubscriptionRow extends StatelessWidget {
  const SubscriptionRow({
    required this.item,
    required this.chips,
    this.amount,
    this.onTap,
    super.key,
  });

  final RecurringItem item;
  final List<StatusChip> chips;

  /// Defaults to the item's amount; recent payments pass the amount paid.
  final double? amount;
  final VoidCallback? onTap;

  static const _iconSize = 44.0;
  static const _gapAfterIcon = 10.0;
  static const _gapBeforeChip = 6.0;
  static const _gapBeforeAmount = 8.0;
  static const _chevronWidth = 24.0;
  static const _slack = 2.0;

  /// Whether name, chip, amount and chevron all fit on one line in [maxWidth].
  /// Measures the real text so scaling and long names are handled.
  bool _fitsInline(
    BuildContext context,
    double maxWidth, {
    required String name,
    required String subtitle,
    required String amount,
  }) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    double width(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      return painter.width;
    }

    final textWidth = [
      width(name, theme.textTheme.titleMedium),
      width(subtitle, theme.textTheme.bodySmall),
    ].reduce((a, b) => a > b ? a : b);

    // Chip: padding 20, plus an icon and its gap when it has one.
    var chipWidth = chips.isEmpty ? 0.0 : (chips.length - 1) * 6.0;
    for (final chip in chips) {
      chipWidth +=
          width(chip.label, sans(12, weight: 600)) +
          20 +
          (chip.icon != null ? 19 : 0);
    }

    final needed =
        _iconSize +
        _gapAfterIcon +
        textWidth +
        _gapBeforeChip +
        chipWidth +
        _gapBeforeAmount +
        width(amount, sans(17, weight: 600)) +
        _chevronWidth +
        _slack;
    return needed <= maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toString();

    final name = Text(
      item.name,
      style: theme.textTheme.titleMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final subtitleLabel = context.l10n.frequencyAndCurrency(
      item.frequency.label(context),
      item.currencyCode,
    );
    final subtitle = Text(
      subtitleLabel,
      style: theme.textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final amountLabel = formatMoney(
      amount ?? item.amount,
      item.currencyCode,
      locale: locale,
    );
    final amountText = Text(
      amountLabel,
      style: sans(17, weight: 600, color: theme.colorScheme.onSurface),
    );

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final inline =
                  chips.isNotEmpty &&
                  _fitsInline(
                    context,
                    constraints.maxWidth,
                    name: item.name,
                    subtitle: subtitleLabel,
                    amount: amountLabel,
                  );

              return Row(
                children: [
                  ServiceIcon(
                    logoKey: item.logoKey,
                    categoryId: item.categoryId,
                    size: _iconSize,
                  ),
                  const SizedBox(width: _gapAfterIcon),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        name,
                        subtitle,
                        if (!inline && chips.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(spacing: 6, runSpacing: 4, children: chips),
                        ],
                      ],
                    ),
                  ),
                  if (inline && chips.isNotEmpty) ...[
                    const SizedBox(width: _gapBeforeChip),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 4,
                        children: chips,
                      ),
                    ),
                  ],
                  const SizedBox(width: _gapBeforeAmount),
                  amountText,
                  const SizedBox(width: 2),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
