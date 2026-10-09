import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: TracklyColors.teal,
      onPrimary: TracklyColors.onTeal,
      secondary: TracklyColors.tealDark,
      surface: TracklyColors.surface1,
      onSurface: TracklyColors.textPrimary,
      onSurfaceVariant: TracklyColors.textSecondary,
      surfaceContainerHighest: TracklyColors.surface2,
      outline: TracklyColors.inputBorder,
      outlineVariant: TracklyColors.border,
      error: TracklyColors.danger,
    );

    return _build(
      scheme: scheme,
      background: TracklyColors.background,
      cardColor: TracklyColors.surface1,
      cardBorder: TracklyColors.border,
      inputFill: TracklyColors.surface2,
      inputBorder: TracklyColors.inputBorder,
      navColor: TracklyColors.navSurface,
      navBorder: TracklyColors.navBorder,
      navInactive: TracklyColors.navInactive,
      primaryText: TracklyColors.textPrimary,
      secondaryText: TracklyColors.textSecondary,
      accent: TracklyColors.teal,
      accentPressed: TracklyColors.tealDark,
      onAccent: TracklyColors.onTeal,
    );
  }

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: TracklyColors.lightTeal,
      onPrimary: Colors.white,
      surface: TracklyColors.lightSurface,
      onSurface: TracklyColors.lightTextPrimary,
      onSurfaceVariant: TracklyColors.lightTextSecondary,
      surfaceContainerHighest: TracklyColors.lightSurface2,
      error: TracklyColors.danger,
    );

    return _build(
      scheme: scheme,
      background: TracklyColors.lightBackground,
      cardColor: TracklyColors.lightSurface,
      cardBorder: const Color(0xFFDDE6EC),
      inputFill: const Color(0xFFF3F6F8),
      inputBorder: const Color(0xFFCFDAE2),
      navColor: TracklyColors.lightSurface,
      navBorder: const Color(0xFFDDE6EC),
      navInactive: TracklyColors.lightTextSecondary,
      primaryText: TracklyColors.lightTextPrimary,
      secondaryText: TracklyColors.lightTextSecondary,
      accent: TracklyColors.lightTeal,
      accentPressed: const Color(0xFF0B8B86),
      onAccent: Colors.white,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color background,
    required Color cardColor,
    required Color cardBorder,
    required Color inputFill,
    required Color inputBorder,
    required Color navColor,
    required Color navBorder,
    required Color navInactive,
    required Color primaryText,
    required Color secondaryText,
    required Color accent,
    required Color accentPressed,
    required Color onAccent,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(TracklyRadius.medium),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Inter',
      textTheme: _textTheme(primaryText, secondaryText),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TracklyRadius.medium),
          side: BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: border(inputBorder),
        enabledBorder: border(inputBorder),
        focusedBorder: border(accent, 1.5),
        errorBorder: border(TracklyColors.danger),
        focusedErrorBorder: border(TracklyColors.danger, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              foregroundColor: onAccent,
              disabledBackgroundColor: TracklyColors.disabledBg,
              disabledForegroundColor: TracklyColors.disabledFg,
              minimumSize: const Size(48, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TracklyRadius.medium),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return TracklyColors.disabledBg;
                }
                if (states.contains(WidgetState.pressed)) return accentPressed;
                return accent;
              }),
            ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.6)),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TracklyRadius.medium),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navColor,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 72,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? accent : navInactive,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: states.contains(WidgetState.selected) ? accent : navInactive,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: navBorder, thickness: 1),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        height: 1.05,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }
}
