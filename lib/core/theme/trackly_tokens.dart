import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'trackly_type.dart';

/// Foreground and background for one semantic tone (chips, icon circles).
@immutable
class ToneColors {
  const ToneColors({required this.fg, required this.bg});

  final Color fg;
  final Color bg;
}

/// How the Home hero is drawn.
enum HeroStyle {
  /// Full-bleed colored field with the header inside it and an arc below.
  fullBleedArc,

  /// A rounded card under a plain header.
  card,
}

/// Every per-theme value the widgets need beyond [ColorScheme]: accent, chip
/// tones, hero and Quick Add treatment, navigation colors and the type that
/// differs between the themes.
///
/// Widgets read these through `context.tokens` instead of hard-coding colors.
@immutable
class TracklyTokens extends ThemeExtension<TracklyTokens> {
  const TracklyTokens({
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.primaryActionPressed,
    required this.cardBorder,
    required this.fieldFill,
    required this.fieldBorder,
    required this.heroStyle,
    required this.heroFill,
    required this.heroFillEnd,
    required this.heroBorder,
    required this.heroIllustration,
    required this.quickAddFill,
    required this.quickAddWave,
    required this.success,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.summaryActive,
    required this.summaryTrial,
    required this.summaryCancelled,
    required this.tileFill,
    required this.tileInk,
    required this.navBackground,
    required this.navBorder,
    required this.navInactive,
    required this.navActive,
    required this.navCenterFill,
    required this.navCenterIcon,
    required this.pageTitle,
    required this.pageSubtitle,
    required this.sectionHeading,
    required this.heroAmount,
    required this.heroAmountUnit,
  });

  /// Brand accent: gold in the light theme, teal in the dark one.
  final Color accent;

  /// Accent for small text on the page ("See all", nav labels): a deeper shade
  /// of the accent that keeps 4.5:1 contrast.
  final Color accentText;
  final Color onAccent;

  /// Primary buttons (Save): ink navy in light, teal in dark.
  final Color primaryAction;
  final Color onPrimaryAction;
  final Color primaryActionPressed;

  final Color cardBorder;
  final Color fieldFill;
  final Color fieldBorder;

  final HeroStyle heroStyle;
  final Color heroFill;

  /// Second stop for the subtle tonal depth of the light hero card.
  final Color heroFillEnd;
  final Color heroBorder;
  final String heroIllustration;

  final Color quickAddFill;

  /// Dark theme keeps its wave on the Quick Add panel; light is a flat card.
  final bool quickAddWave;

  /// Semantic tones for status chips.
  final ToneColors success;
  final ToneColors warning;
  final ToneColors danger;
  final ToneColors neutral;

  /// Icon circles on the Active / Trial / Cancelled cards.
  final ToneColors summaryActive;
  final ToneColors summaryTrial;
  final ToneColors summaryCancelled;

  /// Service icon tile.
  final Color tileFill;
  final Color tileInk;

  final Color navBackground;
  final Color navBorder;
  final Color navInactive;
  final Color navActive;
  final Color navCenterFill;
  final Color navCenterIcon;

  final TextStyle pageTitle;
  final TextStyle pageSubtitle;
  final TextStyle sectionHeading;
  final TextStyle heroAmount;
  final TextStyle heroAmountUnit;

  /// Light: warm, premium. Gold is used sparingly.
  static final light = TracklyTokens(
    accent: TracklyColors.gold,
    accentText: const Color(0xFF8F6A22),
    onAccent: Colors.white,
    primaryAction: TracklyColors.lightInk,
    onPrimaryAction: Colors.white,
    primaryActionPressed: TracklyColors.lightInkPressed,
    cardBorder: TracklyColors.lightBorder,
    fieldFill: TracklyColors.lightFieldFill,
    fieldBorder: TracklyColors.lightBorder,
    heroStyle: HeroStyle.card,
    heroFill: const Color(0xFFFBF6EC),
    heroFillEnd: const Color(0xFFF4EBDA),
    heroBorder: const Color(0xFFEFE6D4),
    heroIllustration: 'assets/illustrations/hero_light.svg',
    quickAddFill: TracklyColors.lightSurface,
    quickAddWave: false,
    // Text and icons use slightly deeper shades than the brand colors so small
    // chip labels stay above 4.5:1 contrast.
    success: const ToneColors(fg: Color(0xFF0F7A53), bg: Color(0xFFE3F5EC)),
    warning: const ToneColors(fg: Color(0xFF8F5400), bg: Color(0xFFFDF1D6)),
    danger: const ToneColors(fg: Color(0xFFBF3037), bg: Color(0xFFFDECEC)),
    neutral: const ToneColors(fg: Color(0xFF4F5B6E), bg: Color(0xFFEDF0F5)),
    summaryActive: const ToneColors(
      fg: Color(0xFF3B6FD4),
      bg: Color(0xFFE8EFFC),
    ),
    summaryTrial: const ToneColors(
      fg: Color(0xFFB97800),
      bg: Color(0xFFFDF0D2),
    ),
    summaryCancelled: const ToneColors(
      fg: Color(0xFFE04B52),
      bg: Color(0xFFFCE6E7),
    ),
    tileFill: TracklyColors.lightSurface2,
    tileInk: TracklyColors.lightInk,
    navBackground: TracklyColors.lightSurface,
    navBorder: const Color(0xFFEDEAE4),
    navInactive: TracklyColors.lightTextSecondary,
    navActive: const Color(0xFFB88A2E),
    navCenterFill: TracklyColors.gold,
    navCenterIcon: Colors.white,
    pageTitle: serif(
      40,
      weight: 600,
      color: TracklyColors.lightTextPrimary,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    pageSubtitle: sans(
      18,
      color: TracklyColors.lightTextSecondary,
      height: 1.3,
    ),
    sectionHeading: sans(
      24,
      weight: 600,
      color: TracklyColors.lightTextPrimary,
      height: 1.25,
    ),
    heroAmount: sans(
      50,
      weight: 700,
      color: TracklyColors.lightTextPrimary,
      height: 1.05,
      letterSpacing: -1,
    ),
    heroAmountUnit: sans(
      20,
      weight: 500,
      color: TracklyColors.lightTextSecondary,
    ),
  );

  /// Dark: black page, deep-teal hero, teal accent.
  static final dark = TracklyTokens(
    accent: TracklyColors.teal,
    accentText: TracklyColors.teal,
    onAccent: TracklyColors.onTeal,
    primaryAction: TracklyColors.teal,
    onPrimaryAction: TracklyColors.onTeal,
    primaryActionPressed: TracklyColors.tealDark,
    cardBorder: TracklyColors.border,
    fieldFill: TracklyColors.surface2,
    fieldBorder: TracklyColors.inputBorder,
    heroStyle: HeroStyle.fullBleedArc,
    heroFill: TracklyColors.heroSurface,
    heroFillEnd: TracklyColors.heroSurface,
    heroBorder: TracklyColors.heroSurface,
    heroIllustration: 'assets/illustrations/hero.svg',
    quickAddFill: TracklyColors.quickAddSurface,
    quickAddWave: true,
    success: const ToneColors(
      fg: TracklyColors.success,
      bg: TracklyColors.successBg,
    ),
    warning: const ToneColors(
      fg: TracklyColors.warning,
      bg: TracklyColors.warningBg,
    ),
    danger: const ToneColors(
      fg: TracklyColors.danger,
      bg: TracklyColors.dangerBg,
    ),
    neutral: const ToneColors(
      fg: TracklyColors.neutral,
      bg: TracklyColors.neutralBg,
    ),
    summaryActive: const ToneColors(
      fg: TracklyColors.success,
      bg: TracklyColors.successBg,
    ),
    summaryTrial: const ToneColors(
      fg: TracklyColors.warning,
      bg: TracklyColors.warningBg,
    ),
    summaryCancelled: const ToneColors(
      fg: TracklyColors.danger,
      bg: TracklyColors.dangerBg,
    ),
    tileFill: TracklyColors.surface2,
    tileInk: TracklyColors.teal,
    navBackground: TracklyColors.navSurface,
    navBorder: TracklyColors.navBorder,
    navInactive: TracklyColors.navInactive,
    navActive: TracklyColors.teal,
    navCenterFill: TracklyColors.teal,
    navCenterIcon: TracklyColors.onTeal,
    pageTitle: sans(24, weight: 700, color: TracklyColors.textPrimary),
    pageSubtitle: sans(13, color: TracklyColors.textSecondary),
    sectionHeading: sans(24, weight: 700, color: TracklyColors.textPrimary),
    heroAmount: sans(
      44,
      weight: 700,
      color: TracklyColors.textPrimary,
      height: 1.05,
    ),
    heroAmountUnit: sans(20, weight: 500, color: TracklyColors.textSecondary),
  );

  @override
  TracklyTokens copyWith() => this;

  @override
  TracklyTokens lerp(ThemeExtension<TracklyTokens>? other, double t) {
    // Themes switch discretely; no in-between values are needed.
    if (other is! TracklyTokens) return this;
    return t < 0.5 ? this : other;
  }
}

extension TracklyTokensContext on BuildContext {
  TracklyTokens get tokens => Theme.of(this).extension<TracklyTokens>()!;
}
