import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Temporary body used by screens that are not built yet.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TracklySpacing.lg,
          TracklySpacing.base,
          TracklySpacing.lg,
          TracklySpacing.base,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.headlineLarge),
            if (subtitle != null) ...[
              const SizedBox(height: TracklySpacing.xs),
              Text(subtitle!, style: textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
