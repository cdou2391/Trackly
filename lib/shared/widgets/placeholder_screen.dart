import 'package:flutter/material.dart';

import 'screen_header.dart';

/// Temporary body used by screens that are not built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    this.icon,
    this.subtitle,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ScreenHeader(title: title, subtitle: subtitle, icon: icon),
      ),
    );
  }
}
