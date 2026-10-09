import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/service_icon.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../subscriptions/domain/recurring_item.dart';
import '../../subscriptions/presentation/labels.dart';

/// One row for both Upcoming charges and Recent payments, so the two lists
/// share a single card style.
class ChargeRow extends StatelessWidget {
  const ChargeRow({
    required this.item,
    required this.pills,
    this.amount,
    this.onTap,
    super.key,
  });

  final RecurringItem item;
  final List<StatusPill> pills;

  /// Defaults to the item's amount; recent payments pass the amount paid.
  final double? amount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ServiceIcon(
                logoKey: item.logoKey,
                categoryId: item.categoryId,
                size: 46,
              ),
              const SizedBox(width: TracklySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      context.l10n.frequencyAndCurrency(
                        item.frequency.label(context),
                        item.currencyCode,
                      ),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: pills),
                  ],
                ),
              ),
              const SizedBox(width: TracklySpacing.sm),
              Text(
                formatMoney(
                  amount ?? item.amount,
                  item.currencyCode,
                  locale: locale,
                ),
                style: theme.textTheme.titleMedium,
              ),
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
