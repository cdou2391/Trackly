import 'package:flutter/painting.dart';

/// Text styles for the bundled variable fonts.
///
/// The fonts are variable (weight axis), so the weight is set both as a
/// [FontWeight] (for layout and fallback) and as the `wght` variation (which
/// is what actually selects the weight).
TextStyle _style(
  String family,
  double size,
  int weight, {
  Color? color,
  double? height,
  double letterSpacing = 0,
}) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}

/// Inter: all interface text.
TextStyle sans(
  double size, {
  int weight = 400,
  Color? color,
  double? height,
  double letterSpacing = 0,
}) => _style(
  'Inter',
  size,
  weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);

/// Playfair Display: the wordmark and page titles only.
TextStyle serif(
  double size, {
  int weight = 600,
  Color? color,
  double? height,
  double letterSpacing = 0,
}) => _style(
  'PlayfairDisplay',
  size,
  weight,
  color: color,
  height: height,
  letterSpacing: letterSpacing,
);
