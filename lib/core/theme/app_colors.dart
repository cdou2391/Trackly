import 'package:flutter/material.dart';

/// Design tokens from the Trackly design guide (dark theme is the reference).
class TracklyColors {
  const TracklyColors._();

  // Dark theme: Steel & Champagne. Champagne is kept for primary actions,
  // selected navigation and key financial figures; steel blue carries the
  // secondary detail (icons, illustration, supporting text).
  static const background = Color(0xFF0B121C);
  static const backgroundDeep = Color(0xFF09111B);
  static const surface1 = Color(0xFF142438);
  static const surface2 = Color(0xFF192D43);
  static const surface3 = Color(0xFF1D334A);

  // Borders
  static const border = Color(0xFF2D455D);
  static const borderSoft = Color(0xFF243A50);

  // Steel blue (secondary accent)
  static const steel = Color(0xFF79A6C8);
  static const steelLight = Color(0xFFA6C7E1);

  // Champagne (primary accent)
  static const champagne = Color(0xFFD7B987);
  static const champagneLight = Color(0xFFF0CE97);
  static const onChampagne = Color(0xFF1B1409);

  // Status
  static const success = Color(0xFF8DC9B0);
  static const successBg = Color(0xFF173A33);
  static const warning = Color(0xFFE3AF89);
  static const warningBg = Color(0xFF3B2B22);
  static const danger = Color(0xFFE38B91);
  static const dangerBg = Color(0xFF3B2228);
  static const neutral = Color(0xFFA8BBD0);
  static const neutralBg = Color(0xFF1D334A);

  // Text
  static const textPrimary = Color(0xFFF3F4F3);
  static const textSecondary = Color(0xFFA8BBD0);
  static const textMuted = Color(0xFF839AAF);

  // Disabled primary action
  static const disabledBg = Color(0xFF26394D);
  static const disabledFg = Color(0xFF8DA0B3);

  // Light theme: warm, premium. Gold is a restrained accent, never dominant.
  static const lightBackground = Color(0xFFFAF8F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFF4F1EB);
  static const lightBorder = Color(0xFFE7E4DE);
  static const lightBorderSoft = Color(0xFFEFECE6);
  static const lightFieldFill = Color(0xFFFBFAF7);
  static const lightTextPrimary = Color(0xFF0B1322);
  static const lightTextSecondary = Color(0xFF657286);
  static const lightTextMuted = Color(0xFF8A94A3);
  static const lightInk = Color(0xFF1A2130);
  static const lightInkPressed = Color(0xFF0B1322);
  static const gold = Color(0xFFC99A3D);
  static const goldLight = Color(0xFFD8AD5A);
  static const goldDark = Color(0xFF9A7326);
  static const goldTint = Color(0xFFF6EBD3);
  static const lightSuccess = Color(0xFF16A36F);
  static const lightWarning = Color(0xFFF2A51A);
  static const lightDanger = Color(0xFFE95359);
}

class TracklyRadius {
  const TracklyRadius._();

  static const small = 12.0;
  static const medium = 16.0;
  static const large = 20.0;
  static const section = 24.0;
  static const pill = 999.0;
}

class TracklySpacing {
  const TracklySpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const base = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
