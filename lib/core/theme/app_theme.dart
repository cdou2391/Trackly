import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'trackly_tokens.dart';
import 'trackly_type.dart';

class AppTheme {
  const AppTheme._();

  /// Warm premium light theme (the redesign reference).
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: TracklyColors.lightInk,
      onPrimary: Colors.white,
      secondary: TracklyColors.gold,
      onSecondary: Colors.white,
      secondaryContainer: TracklyColors.goldTint,
      onSecondaryContainer: TracklyColors.lightInk,
      surface: TracklyColors.lightSurface,
      onSurface: TracklyColors.lightTextPrimary,
      onSurfaceVariant: TracklyColors.lightTextSecondary,
      surfaceContainerHighest: TracklyColors.lightSurface2,
      outline: TracklyColors.lightBorder,
      outlineVariant: TracklyColors.lightBorderSoft,
      error: TracklyColors.lightDanger,
    );

    return _build(
      scheme: scheme,
      tokens: TracklyTokens.light,
      background: TracklyColors.lightBackground,
      hintColor: TracklyColors.lightTextSecondary,
      disabledBackground: const Color(0xFFEAE7E1),
      disabledForeground: const Color(0xFF9AA2AE),
    );
  }

  /// Steel & Champagne: navy page and surfaces, champagne accent.
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: TracklyColors.champagne,
      onPrimary: TracklyColors.onChampagne,
      secondary: TracklyColors.steel,
      secondaryContainer: TracklyColors.surface3,
      onSecondaryContainer: TracklyColors.textPrimary,
      // Cards share the page colour; popups and sheets stay raised.
      surface: TracklyColors.background,
      surfaceContainer: TracklyColors.surface1,
      surfaceContainerHigh: TracklyColors.surface1,
      onSurface: TracklyColors.textPrimary,
      onSurfaceVariant: TracklyColors.textSecondary,
      surfaceContainerHighest: TracklyColors.surface3,
      outline: TracklyColors.border,
      outlineVariant: TracklyColors.borderSoft,
      error: TracklyColors.danger,
    );

    return _build(
      scheme: scheme,
      tokens: TracklyTokens.dark,
      background: TracklyColors.background,
      hintColor: TracklyColors.textMuted,
      disabledBackground: TracklyColors.disabledBg,
      disabledForeground: TracklyColors.disabledFg,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required TracklyTokens tokens,
    required Color background,
    required Color hintColor,
    required Color disabledBackground,
    required Color disabledForeground,
  }) {
    final primaryText = scheme.onSurface;
    final secondaryText = scheme.onSurfaceVariant;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      extensions: [tokens],
      textTheme: _textTheme(tokens, primaryText, secondaryText),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TracklyRadius.large),
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: sans(15, color: hintColor),
        labelStyle: sans(14, color: secondaryText),
        floatingLabelStyle: sans(12, weight: 500, color: secondaryText),
        prefixIconColor: secondaryText,
        suffixIconColor: secondaryText,
        border: border(tokens.fieldBorder),
        enabledBorder: border(tokens.fieldBorder),
        focusedBorder: border(tokens.focus, 1.5),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              foregroundColor: tokens.onPrimaryAction,
              disabledForegroundColor: disabledForeground,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: sans(16, weight: 600),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return disabledBackground;
                }
                if (states.contains(WidgetState.pressed)) {
                  return tokens.primaryActionPressed;
                }
                return tokens.primaryAction;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.primaryAction,
          side: BorderSide(color: tokens.primaryAction.withValues(alpha: 0.35)),
          minimumSize: const Size(48, 48),
          textStyle: sans(15, weight: 600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.accentText,
          minimumSize: const Size(48, 48),
          textStyle: sans(15, weight: 600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.onAccent
              : secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? tokens.accent
              : tokens.fieldFill,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : tokens.fieldBorder,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.fieldFill,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: tokens.fieldBorder),
        labelStyle: sans(14, weight: 500, color: primaryText),
        checkmarkColor: primaryText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TracklyRadius.pill),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: sans(14, weight: 600),
          side: BorderSide(color: tokens.fieldBorder),
          foregroundColor: secondaryText,
          selectedForegroundColor: scheme.onSecondaryContainer,
          selectedBackgroundColor: scheme.secondaryContainer,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryText,
        unselectedLabelColor: secondaryText,
        labelStyle: sans(15, weight: 600),
        unselectedLabelStyle: sans(15, weight: 500),
        indicatorColor: tokens.accent,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: tokens.accent, width: 3),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
        dividerColor: tokens.cardBorder,
        overlayColor: WidgetStatePropertyAll(
          tokens.accent.withValues(alpha: 0.08),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.primaryAction,
        contentTextStyle: sans(14, weight: 500, color: tokens.onPrimaryAction),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.navBackground,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? tokens.navActive
                : tokens.navInactive,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => sans(
            12,
            weight: 500,
            color: states.contains(WidgetState.selected)
                ? tokens.accentText
                : tokens.navInactive,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.navBorder, thickness: 1),
    );
  }

  static TextTheme _textTheme(
    TracklyTokens tokens,
    Color primary,
    Color secondary,
  ) {
    return TextTheme(
      displayLarge: tokens.heroAmount,
      headlineLarge: tokens.pageTitle,
      headlineMedium: tokens.sectionHeading,
      titleLarge: sans(22, weight: 600, color: primary, height: 1.25),
      titleMedium: sans(17, weight: 600, color: primary, height: 1.25),
      bodyLarge: sans(16, color: primary),
      bodyMedium: sans(14, color: primary),
      bodySmall: sans(13, color: secondary),
      labelLarge: sans(14, weight: 600, color: primary),
      labelMedium: sans(12, weight: 500, color: secondary),
    );
  }
}
