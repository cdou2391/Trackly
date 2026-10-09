import 'package:flutter/material.dart';

/// Design tokens from the Trackly design guide (dark theme is the reference).
class TracklyColors {
  const TracklyColors._();

  // Background and surfaces
  static const background = Color(0xFF000000);
  static const surface1 = Color(0xFF0D1B28);
  static const surface2 = Color(0xFF122433);
  static const surface3 = Color(0xFF183040);
  static const quickAddSurface = Color(0xFF0D2730);
  static const heroSurface = Color(0xFF0B3138);
  static const navSurface = Color(0xFF000000);

  // Borders
  static const border = Color(0xFF173142);
  static const inputBorder = Color(0xFF244052);
  static const navBorder = Color(0xFF000000);

  // Brand teal
  static const teal = Color(0xFF16C7BE);
  static const tealDark = Color(0xFF0E8F89);
  static const tealLight = Color(0xFF4EDDD5);
  static const onTeal = Color(0xFF041112);

  // Status
  static const success = Color(0xFF24C97A);
  static const successBg = Color(0xFF123D2E);
  static const warning = Color(0xFFFFB629);
  static const warningBg = Color(0xFF3A2B12);
  static const danger = Color(0xFFFF5D62);
  static const dangerBg = Color(0xFF3A181D);
  static const neutral = Color(0xFFA9C0D2);
  static const neutralBg = Color(0xFF12293A);

  // Text
  static const textPrimary = Color(0xFFF7FAFC);
  static const textSecondary = Color(0xFFAAB8C5);
  static const textMuted = Color(0xFF728394);

  // Navigation
  static const navInactive = Color(0xFF8394A5);

  // Disabled primary action
  static const disabledBg = Color(0xFF274149);
  static const disabledFg = Color(0xFF70848B);

  // Light theme
  static const lightBackground = Color(0xFFF5F8FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurface2 = Color(0xFFEDF5F5);
  static const lightTextPrimary = Color(0xFF0D1B28);
  static const lightTextSecondary = Color(0xFF607184);
  static const lightTeal = Color(0xFF0FA9A3);
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
