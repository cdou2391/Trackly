import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/database/tables/categories_table.dart';
import 'package:trackly/core/theme/category_colors.dart';
import 'package:trackly/core/theme/app_theme.dart';
import 'package:trackly/shared/widgets/service_icon.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

/// WCAG contrast of white on [color].
double _contrastWithWhite(Color color) => 1.05 / (_luminance(color) + 0.05);

Widget _app(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

/// The tile color a [ServiceIcon] ended up with: its gradient's last stop.
Color _tileColor(WidgetTester tester) {
  final box =
      tester
              .widget<Container>(
                find
                    .descendant(
                      of: find.byType(GlyphTile),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .decoration!
          as BoxDecoration;
  return (box.gradient! as LinearGradient).colors.last;
}

void main() {
  group('category colors', () {
    test('every category has its own color', () {
      final colors = [
        for (final category in systemCategories) categoryColor(category.id),
      ];

      expect(colors.toSet(), hasLength(systemCategories.length));
    });

    test('white on each reaches 3:1, the minimum for an icon', () {
      for (final entry in categoryColorEntries) {
        expect(
          _contrastWithWhite(entry.value),
          greaterThanOrEqualTo(3),
          reason: entry.key,
        );
      }
      expect(
        _contrastWithWhite(subscriptionTileColor),
        greaterThanOrEqualTo(3),
      );
      expect(_contrastWithWhite(billTileColor), greaterThanOrEqualTo(3));
    });

    test('an unknown or missing category falls back to Other', () {
      expect(categoryColor(null), categoryColor('other'));
      expect(categoryColor('nonsense'), categoryColor('other'));
    });

    test('colors cover exactly the seeded categories', () {
      expect(
        {for (final entry in categoryColorEntries) entry.key},
        {for (final category in systemCategories) category.id},
      );
    });
  });

  group('ServiceIcon without a logo', () {
    testWidgets('a custom item takes its category color', (tester) async {
      await tester.pumpWidget(
        _app(const ServiceIcon(categoryId: 'health', size: 48)),
      );

      expect(_tileColor(tester), categoryColor('health'));
    });

    testWidgets('a bill like Rent takes its category color', (tester) async {
      await tester.pumpWidget(
        _app(const ServiceIcon(logoKey: 'rent', size: 48)),
      );

      expect(_tileColor(tester), categoryColor('housing'));
    });

    testWidgets('a brand without a logo draws the Trackly mark in white', (
      tester,
    ) async {
      // Hulu has no bundled logo.
      await tester.pumpWidget(
        _app(const ServiceIcon(logoKey: 'hulu', size: 48)),
      );

      expect(_tileColor(tester), categoryColor('entertainment'));
      expect(find.byType(Icon), findsNothing); // the mark, not a glyph
    });

    testWidgets('the glyph is white, in light and dark', (tester) async {
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          _app(const ServiceIcon(categoryId: 'fitness', size: 48), dark: dark),
        );

        expect(tester.widget<Icon>(find.byType(Icon)).color, Colors.white);
        expect(_tileColor(tester), categoryColor('fitness'));
      }
    });

    testWidgets('no category at all is the Other color', (tester) async {
      await tester.pumpWidget(_app(const ServiceIcon(size: 48)));

      expect(_tileColor(tester), categoryColor('other'));
    });

    testWidgets('a real logo is left as it is', (tester) async {
      await tester.pumpWidget(
        _app(const ServiceIcon(logoKey: 'netflix', size: 48)),
      );

      expect(find.byType(GlyphTile), findsNothing);
    });
  });
}
