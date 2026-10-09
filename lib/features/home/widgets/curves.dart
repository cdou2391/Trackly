import 'package:flutter/material.dart';

/// Shallow wave along the bottom edge (hero section).
class BottomWaveClipper extends CustomClipper<Path> {
  const BottomWaveClipper({this.waveHeight = 40});

  final double waveHeight;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..lineTo(0, h - waveHeight)
      ..quadraticBezierTo(w * 0.25, h, w * 0.55, h - waveHeight * 0.45)
      ..quadraticBezierTo(w * 0.8, h - waveHeight * 0.95, w, h - waveHeight * 0.3)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(BottomWaveClipper old) => old.waveHeight != waveHeight;
}

/// Shallow wave along the top edge (Quick Add section).
class TopWaveClipper extends CustomClipper<Path> {
  const TopWaveClipper({this.waveHeight = 20});

  final double waveHeight;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(0, waveHeight * 0.6)
      ..quadraticBezierTo(w * 0.3, -waveHeight * 0.2, w * 0.6, waveHeight * 0.5)
      ..quadraticBezierTo(w * 0.85, waveHeight, w, waveHeight * 0.3)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
  }

  @override
  bool shouldReclip(TopWaveClipper old) => old.waveHeight != waveHeight;
}
