import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/trackly_tokens.dart';
import '../../../../core/theme/trackly_type.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/payment.dart';

/// One payment or skipped charge: what it was for, when it was due, the
/// amount, and a chip saying whether it was paid or skipped.
class PaymentRow extends StatelessWidget {
  const PaymentRow({required this.payment, this.title, this.onTap, super.key});

  final Payment payment;

  /// Usually the item's name; omitted inside the item's own history.
  final String? title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final paid = payment.status == PaymentStatus.paid;

    final due = l10n.dueOn(formatMediumDate(payment.dueDate, locale: locale));
    final chip = StatusChip(
      label: paid
          ? l10n.paidOn(
              formatShortDate(
                payment.paidDate ?? payment.dueDate,
                locale: locale,
              ),
            )
          : l10n.skippedChip,
      tone: paid ? ChipTone.success : ChipTone.neutral,
      icon: paid ? Icons.check_circle_rounded : Icons.skip_next_rounded,
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
          padding: const EdgeInsets.symmetric(
            horizontal: TracklySpacing.base,
            vertical: TracklySpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      due,
                      style: title != null
                          ? theme.textTheme.bodySmall
                          : theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Align(alignment: Alignment.centerLeft, child: chip),
                  ],
                ),
              ),
              const SizedBox(width: TracklySpacing.md),
              Text(
                formatMoney(
                  payment.amount,
                  payment.currencyCode,
                  locale: locale,
                ),
                style: sans(
                  17,
                  weight: 600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
