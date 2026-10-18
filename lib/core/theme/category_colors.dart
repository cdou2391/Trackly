import 'package:flutter/material.dart';

/// One color per category, for the icons of items that have no logo of their
/// own (a custom subscription, a bill like Rent or Water, or a service whose
/// logo is not bundled). Each is saturated enough to sit beside the real
/// brand logos, and dark enough for a white glyph on top to reach 3:1.
///
/// The same in light and dark, like a logo: a tile does not change with the
/// theme.
const _categoryColors = <String, Color>{
  'entertainment': Color(0xFFE5484D), // red
  'software': Color(0xFF3E63DD), // blue
  'utilities': Color(0xFFD97706), // amber
  'housing': Color(0xFF0E8F80), // teal
  'transport': Color(0xFF0B83B8), // sky
  'insurance': Color(0xFF2F855A), // green
  'health': Color(0xFFD6409F), // pink
  'education': Color(0xFF8E4EC6), // purple
  'fitness': Color(0xFFE8590C), // orange
  'business': Color(0xFF5B6776), // slate
  'other': Color(0xFF6B7A8C), // grey-blue
};

/// The tile color for [categoryId]; "Other" for an unknown or missing one.
Color categoryColor(String? categoryId) =>
    _categoryColors[categoryId] ?? _categoryColors['other']!;

/// The tile colors for the Subscriptions and Bills rows on Insights.
const subscriptionTileColor = Color(0xFF3E63DD);
const billTileColor = Color(0xFFD97706);

/// Every color, for tests that check them all.
Iterable<MapEntry<String, Color>> get categoryColorEntries =>
    _categoryColors.entries;
