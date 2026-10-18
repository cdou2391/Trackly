import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/database/tables/categories_table.dart';
import '../../core/theme/category_colors.dart';
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

/// Corner radius shared by every kind of service icon.
double _cornerRadius(double size) => size * 0.3;

/// The Trackly mark: the stand-in for a service whose own logo is not bundled,
/// drawn in white on a colored tile.
const _tracklyMark = 'assets/illustrations/trackly_logo.svg';

/// A colored rounded tile with something white on it: the look of every icon
/// that is not a brand logo, so they sit comfortably beside the logos. A soft
/// lift from top to bottom gives it the same depth as an app icon.
class GlyphTile extends StatelessWidget {
  const GlyphTile({
    required this.color,
    required this.child,
    this.size = 48,
    super.key,
  });

  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, 0.14)!, color],
        ),
        borderRadius: BorderRadius.circular(_cornerRadius(size)),
      ),
      child: child,
    );
  }
}

/// Service icon. Resolution order: the catalog logo (filling the whole element),
/// then the Trackly mark for a catalog service without one, then the category
/// icon (custom items, and generic bills like Rent or Water), then a generic
/// icon. The last three sit on a tile in their category's color.
class ServiceIcon extends StatelessWidget {
  const ServiceIcon({this.logoKey, this.categoryId, this.size = 48, super.key});

  final String? logoKey;
  final String? categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final service = logoKey == null ? null : serviceCatalogByKey[logoKey];

    final logo = service?.logoAsset;

    // A logo is the icon: no tile, border or padding, filling the whole
    // element, clipped to the same rounded shape as the letter and category
    // tiles so every icon in a list matches. Black marks turn white on a dark
    // page so they stay visible.
    if (logo != null) {
      final onDark = Theme.of(context).brightness == Brightness.dark;
      return ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_cornerRadius(size)),
          child: SvgPicture.asset(
            logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
            colorFilter: onDark && service!.blackMark
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : null,
          ),
        ),
      );
    }

    final category = categoryId ?? service?.categoryId;
    final isBrand = service != null && !service.isGeneric;
    final Widget child = isBrand
        ? Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: SvgPicture.asset(
              _tracklyMark,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          )
        : Icon(
            categoryIconData(category),
            size: size * 0.52,
            color: Colors.white,
          );

    return ExcludeSemantics(
      child: GlyphTile(
        color: categoryColor(category),
        size: size,
        child: child,
      ),
    );
  }
}
