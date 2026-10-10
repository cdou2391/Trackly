import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';

/// Header for screens reached from another screen: a back button and a title.
class SubPageHeader extends StatelessWidget {
  const SubPageHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TracklySpacing.xs,
        TracklySpacing.xs,
        TracklySpacing.base,
        TracklySpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.back,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.headlineMedium),
            ),
          ),
        ],
      ),
    );
  }
}
