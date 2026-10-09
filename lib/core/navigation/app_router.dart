import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/subscriptions/presentation/add_subscription_screen.dart';
import '../../l10n/l10n.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const insights = '/insights';
  static const calendar = '/calendar';
  static const more = '/more';
  static const add = '/add';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.insights,
              builder: (context, state) => const InsightsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.calendar,
              builder: (context, state) => const CalendarScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.more,
              builder: (context, state) => const MoreScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.add,
        builder: (context, state) => const AddSubscriptionScreen(),
      ),
    ],
  );
});

/// Bottom navigation shell: Home, Insights, Add, Calendar, More.
///
/// The centered Add button opens the full add flow and is not a tab, so it is
/// laid out between the two tab pairs rather than being a destination.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final current = shell.currentIndex;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navTheme = theme.navigationBarTheme;

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: navTheme.backgroundColor,
          border: Border(top: BorderSide(color: theme.dividerTheme.color!)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: context.l10n.navHome,
                  selected: current == 0,
                  onTap: () => shell.goBranch(0),
                ),
                _NavItem(
                  icon: Icons.insights_rounded,
                  label: context.l10n.navInsights,
                  selected: current == 1,
                  onTap: () => shell.goBranch(1),
                ),
                Expanded(
                  child: Center(
                    child: Semantics(
                      button: true,
                      label: context.l10n.navAdd,
                      child: Material(
                        color: scheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => context.push(AppRoutes.add),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              Icons.add_rounded,
                              color: scheme.onPrimary,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: context.l10n.navCalendar,
                  selected: current == 2,
                  onTap: () => shell.goBranch(2),
                ),
                _NavItem(
                  icon: Icons.more_horiz_rounded,
                  label: context.l10n.navMore,
                  selected: current == 3,
                  onTap: () => shell.goBranch(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final navTheme = Theme.of(context).navigationBarTheme;
    final states = <WidgetState>{if (selected) WidgetState.selected};
    final color = navTheme.iconTheme!.resolve(states)!.color!;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
