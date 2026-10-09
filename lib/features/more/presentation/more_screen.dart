import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: context.l10n.moreTitle,
      icon: Icons.more_horiz_rounded,
    );
  }
}
