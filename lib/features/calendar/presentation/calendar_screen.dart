import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../shared/widgets/placeholder_screen.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: context.l10n.calendarTitle,
      icon: Icons.calendar_month_rounded,
    );
  }
}
