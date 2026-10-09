import 'package:flutter/material.dart';

import '../../core/database/tables/categories_table.dart';
import '../../core/theme/app_colors.dart';
import '../../features/subscriptions/domain/service_catalog.dart';

const _categoryIcons = <String, IconData>{
  'movie': Icons.movie_rounded,
  'apps': Icons.apps_rounded,
  'bolt': Icons.bolt_rounded,
  'home': Icons.home_rounded,
  'directions_car': Icons.directions_car_rounded,
  'shield': Icons.shield_rounded,
  'favorite': Icons.favorite_rounded,
  'school': Icons.school_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'work': Icons.work_rounded,
  'category': Icons.category_rounded,
};

IconData categoryIconData(String? categoryId) {
  final key = systemCategories
      .where((category) => category.id == categoryId)
      .map((category) => category.icon)
      .firstOrNull;
  return _categoryIcons[key] ?? Icons.receipt_long_rounded;
}

/// Service tile. Resolution order: catalog service (monogram until a logo
/// asset exists), then the category icon, then a generic icon.
class ServiceIcon extends StatelessWidget {
  const ServiceIcon({this.logoKey, this.categoryId, this.size = 44, super.key});

  final String? logoKey;
  final String? categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final service = logoKey == null ? null : serviceCatalogByKey[logoKey];

    final Widget child = service != null
        ? Text(
            service.name.characters.first.toUpperCase(),
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          )
        : Icon(
            categoryIconData(categoryId),
            size: size * 0.5,
            color: scheme.onSurfaceVariant,
          );

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(TracklyRadius.small),
        ),
        child: child,
      ),
    );
  }
}
