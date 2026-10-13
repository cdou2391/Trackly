import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/payments/presentation/history_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/subscriptions/application/items_filter.dart';
import '../../features/subscriptions/presentation/item_detail_screen.dart';
import '../../features/subscriptions/presentation/items_screen.dart';
import 'app_shell.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const insights = '/insights';
  static const calendar = '/calendar';
  static const more = '/more';
  static const tabPaths = [home, insights, calendar, more];

  /// The tab a route path belongs to, or null for screens opened from a tab.
  static int? tabIndexOf(String location) {
    final path = Uri.parse(location).path;
    final index = tabPaths.indexOf(path);
    return index == -1 ? null : index;
  }

  static const item = '/item/:id';
  static const subscriptions = '/subscriptions';
  static const history = '/history';
  static const settings = '/settings';
  static const search = '/search';
  static const about = '/about';

  static String itemPath(String id) => '/item/$id';
  static String subscriptionsPath([String? filter]) =>
      filter == null ? subscriptions : '$subscriptions?filter=$filter';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // One frame (the navigation bar and the add/edit panel) around the tabs
      // and the screens opened from them, so the bar is always visible.
      ShellRoute(
        builder: (context, state, child) =>
            AppFrame(location: state.uri.toString(), child: child),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, shell) => shell,
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.home,
                    builder: (context, state) => const HomeScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.insights,
                    builder: (context, state) => const InsightsScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.calendar,
                    builder: (context, state) => const CalendarScreen(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.more,
                    builder: (context, state) => const MoreScreen(),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.item,
            builder: (context, state) =>
                ItemDetailScreen(itemId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: AppRoutes.subscriptions,
            builder: (context, state) => ItemsScreen(
              initialFilter: ItemFilter.parse(
                state.uri.queryParameters['filter'],
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.history,
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutes.about,
            builder: (context, state) => const AboutScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
