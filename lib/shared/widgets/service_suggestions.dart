import 'package:flutter/material.dart';

import '../../core/database/tables/categories_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/trackly_tokens.dart';
import '../../features/subscriptions/domain/recurring_enums.dart';
import '../../features/subscriptions/domain/service_catalog.dart';
import '../../l10n/l10n.dart';
import 'service_icon.dart';

/// The matches shown under the name field while typing: each with its icon
/// (the logo, or the Trackly mark when there is none), its name and category,
/// and a "Bill" tag for bills. Tapping one fills the form from it.
class ServiceSuggestions extends StatelessWidget {
  const ServiceSuggestions({
    required this.services,
    required this.onSelected,
    super.key,
  });

  final List<CatalogService> services;
  final ValueChanged<CatalogService> onSelected;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) return const SizedBox.shrink();
    final tokens = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(top: TracklySpacing.sm),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.cardBorder),
        ),
        child: Column(
          children: [
            for (final (index, service) in services.indexed) ...[
              if (index > 0) Divider(height: 1, color: tokens.cardBorder),
              _SuggestionRow(
                service: service,
                onTap: () => onSelected(service),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.service, required this.onTap});

  final CatalogService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final category = systemCategories
        .where((c) => c.id == service.categoryId)
        .map((c) => c.name)
        .firstOrNull;
    final isBill = service.type == RecurringItemType.bill;

    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: ServiceIcon(
        logoKey: service.key,
        categoryId: service.categoryId,
        size: 36,
      ),
      title: Text(
        service.name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: category == null
          ? null
          : Text(category, style: theme.textTheme.bodySmall),
      trailing: isBill
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.tileFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  context.l10n.suggestionBillTag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.tileInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
