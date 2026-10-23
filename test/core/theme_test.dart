import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/theme/app_colors.dart';
import 'package:trackly/core/theme/app_theme.dart';
import 'package:trackly/core/theme/trackly_tokens.dart';
import 'package:trackly/features/settings/application/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// WCAG relative luminance and contrast ratio.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final l1 = _luminance(a);
  final l2 = _luminance(b);
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

void main() {
  final light = AppTheme.light;
  final tokens = TracklyTokens.light;

  test('light is the default theme mode', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  group('light palette', () {
    test('uses the warm premium colors', () {
      expect(light.scaffoldBackgroundColor, const Color(0xFFFFFFFF));
      expect(light.colorScheme.surface, const Color(0xFFFFFFFF));
      expect(light.colorScheme.onSurface, const Color(0xFF0B1322));
      expect(light.colorScheme.onSurfaceVariant, const Color(0xFF657286));
      expect(tokens.cardBorder, const Color(0xFFEEEBE6));
      expect(tokens.accent, const Color(0xFFC99A3D)); // gold
      expect(tokens.primaryAction, const Color(0xFF1A2130)); // Save
    });

    test('has no purple and no teal accent', () {
      for (final color in [
        tokens.accent,
        tokens.primaryAction,
        tokens.navActive,
        tokens.navCenterFill,
        light.colorScheme.primary,
        light.colorScheme.secondary,
      ]) {
        final hsl = HSLColor.fromColor(color);
        final purple = hsl.hue >= 250 && hsl.hue <= 310 && hsl.saturation > .2;
        final teal = hsl.hue >= 160 && hsl.hue <= 200 && hsl.saturation > .3;
        expect(purple, isFalse, reason: '$color');
        expect(teal, isFalse, reason: '$color');
      }
    });

    test('Save is navy, with pressed and disabled states', () {
      final bg = light.filledButtonTheme.style!.backgroundColor!;
      expect(bg.resolve({}), tokens.primaryAction);
      expect(bg.resolve({WidgetState.pressed}), tokens.primaryActionPressed);
      expect(bg.resolve({WidgetState.disabled}), isNot(tokens.primaryAction));
      expect(
        light.filledButtonTheme.style!.foregroundColor!.resolve({}),
        Colors.white,
      );
    });

    test('inputs show gold focus and red error borders', () {
      final theme = light.inputDecorationTheme;
      expect(
        (theme.focusedBorder as OutlineInputBorder).borderSide.color,
        tokens.accent,
      );
      expect(
        (theme.errorBorder as OutlineInputBorder).borderSide.color,
        light.colorScheme.error,
      );
    });
  });

  group('type scale', () {
    final text = light.textTheme;

    test('serif is only for the title; the rest is Inter', () {
      expect(tokens.pageTitle.fontFamily, 'PlayfairDisplay');
      for (final style in [
        text.displayLarge,
        text.headlineMedium,
        text.titleLarge,
        text.titleMedium,
        text.bodyLarge,
        text.bodyMedium,
        text.bodySmall,
        text.labelMedium,
        tokens.pageSubtitle,
        tokens.sectionHeading,
      ]) {
        expect(style!.fontFamily, 'Inter');
      }
    });

    test('sizes follow the spec', () {
      expect(tokens.pageTitle.fontSize, inInclusiveRange(38, 44));
      expect(tokens.pageSubtitle.fontSize, inInclusiveRange(18, 20));
      expect(tokens.heroAmount.fontSize, inInclusiveRange(46, 54));
      expect(tokens.heroAmount.fontWeight, FontWeight.w700);
      expect(tokens.sectionHeading.fontSize, inInclusiveRange(24, 28));
      expect(text.titleMedium!.fontSize, inInclusiveRange(17, 18));
      expect(text.bodySmall!.fontSize, inInclusiveRange(13, 15));
    });

    test('weights are set as variable-font axes, not just FontWeight', () {
      final variation = tokens.heroAmount.fontVariations!.single;
      expect(variation.axis, 'wght');
      expect(variation.value, 700);
    });
  });

  group('contrast (WCAG AA for text is 4.5:1)', () {
    final page = light.scaffoldBackgroundColor;
    const white = Colors.white;

    test('body text on the page and on cards', () {
      expect(_contrast(light.colorScheme.onSurface, page), greaterThan(7));
      expect(_contrast(light.colorScheme.onSurface, white), greaterThan(7));
      expect(
        _contrast(light.colorScheme.onSurfaceVariant, page),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(light.colorScheme.onSurfaceVariant, white),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('placeholder text on a field', () {
      final hint = light.inputDecorationTheme.hintStyle!.color!;
      expect(_contrast(hint, tokens.fieldFill), greaterThanOrEqualTo(4.5));
    });

    test('every status chip tone', () {
      for (final entry in {
        'success': tokens.success,
        'warning': tokens.warning,
        'danger': tokens.danger,
        'neutral': tokens.neutral,
      }.entries) {
        expect(
          _contrast(entry.value.fg, entry.value.bg),
          greaterThanOrEqualTo(4.5),
          reason: entry.key,
        );
      }
    });

    test('gold text and the active nav label', () {
      expect(_contrast(tokens.accentText, page), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(tokens.accentText, tokens.navBackground),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(tokens.navInactive, tokens.navBackground),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('Save label on the navy button', () {
      expect(
        _contrast(tokens.onPrimaryAction, tokens.primaryAction),
        greaterThan(7),
      );
    });

    test('icons and graphics reach 3:1', () {
      expect(
        _contrast(tokens.navActive, tokens.navBackground),
        greaterThanOrEqualTo(3),
      );
      for (final tone in [
        tokens.summaryActive,
        tokens.summaryTrial,
        tokens.summaryCancelled,
      ]) {
        expect(_contrast(tone.fg, tone.bg), greaterThanOrEqualTo(3));
      }
    });
  });

  test('dark theme keeps its own tokens', () {
    final dark = TracklyTokens.dark;
    expect(dark.heroStyle, HeroStyle.card);
    expect(dark.accent, TracklyColors.champagne);
    expect(AppTheme.dark.scaffoldBackgroundColor, TracklyColors.background);
    expect(tokens.heroStyle, HeroStyle.card);
  });
}
