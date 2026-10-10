import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/database/tables/categories_table.dart';
import '../../core/theme/trackly_tokens.dart';
import '../../core/theme/trackly_type.dart';
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

/// Service icon. Resolution order: the catalog logo (filling the whole element),
/// then a letter tile for a catalog service without one, then the category
/// icon, then a generic icon.
class ServiceIcon extends StatelessWidget {
  const ServiceIcon({this.logoKey, this.categoryId, this.size = 48, super.key});

  final String? logoKey;
  final String? categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final service = logoKey == null ? null : serviceCatalogByKey[logoKey];

    final logo = service?.logoAsset;

    // A logo is the icon: no tile, border or padding, filling the whole
    // element. Black marks turn white on a dark page so they stay visible.
    if (logo != null) {
      final onDark = Theme.of(context).brightness == Brightness.dark;
      return ExcludeSemantics(
        child: SvgPicture.asset(
          logo,
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter: onDark && service!.blackMark
              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
              : null,
        ),
      );
    }

    final Widget child = service != null
        ? Text(
            service.name.characters.first.toUpperCase(),
            style: sans(size * 0.42, weight: 700, color: tokens.tileInk),
          )
        : Icon(
            categoryIconData(categoryId),
            size: size * 0.5,
            color: tokens.tileInk,
          );

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.tileFill,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: child,
      ),
    );
  }
}
