import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class AddSubscriptionScreen extends StatelessWidget {
  const AddSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlaceholderScreen(title: context.l10n.addSubscriptionTitle),
    );
  }
}
