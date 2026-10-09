import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: context.l10n.insightsTitle,
      icon: Icons.insights_rounded,
    );
  }
}
