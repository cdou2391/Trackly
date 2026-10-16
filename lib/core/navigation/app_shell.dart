import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/subscriptions/application/add_panel_controller.dart';
import '../../features/subscriptions/presentation/widgets/add_subscription_panel.dart';
import '../../l10n/l10n.dart';
import '../analytics/analytics_events.dart';
import '../analytics/analytics_service.dart';
import 'app_bottom_navigation.dart';
import 'app_router.dart';

/// The frame around every screen: the current screen above the bottom
/// navigation, with the add/edit panel on top.
///
/// The bar stays visible on the tabs and on the screens opened from them
/// (item detail, All subscriptions, Payment history). The centered Add button
/// is not a tab: it opens the add panel, which slides up from the bar.
class AppFrame extends ConsumerStatefulWidget {
  const AppFrame({required this.location, required this.child, super.key});

  /// The current route's path, used to highlight the right tab.
  final String location;
  final Widget child;

  @override
  ConsumerState<AppFrame> createState() => _AppFrameState();
}

class _AppFrameState extends ConsumerState<AppFrame> {
  /// The highlighted tab. A screen opened from a tab (like an item) keeps its
  /// origin highlighted instead of lighting up nothing.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // Home is what the app opens on, so it is counted without a tab tap.
    if (AppRoutes.tabIndexOf(widget.location) == 0) _logTabOpened(0);
  }

  /// Tab screens stay alive once visited, so "opened" is logged when the
  /// tab is chosen rather than when the screen is built.
  void _logTabOpened(int index) {
    final event = switch (index) {
      0 => AnalyticsEvents.homeOpened,
      1 => AnalyticsEvents.insightsOpened,
      2 => AnalyticsEvents.calendarOpened,
      _ => null,
    };
    if (event != null) ref.read(analyticsProvider).logEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    final tab = AppRoutes.tabIndexOf(widget.location);
    if (tab != null) _tab = tab;

    final panelOpen = ref.watch(addPanelProvider).open;
    final panel = ref.read(addPanelProvider.notifier);

    // Back closes an open panel first. PopScope covers pops of this route; the
    // listener also covers screens pushed inside the frame (an item), whose
    // back press would otherwise pop that screen and leave the panel open.
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!ref.read(addPanelProvider).open) return false;
        panel.close();
        return true;
      },
      child: PopScope(
        canPop: !panelOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) panel.close();
        },
        child: Scaffold(
          // The page runs behind the floating bar; the panel (and its scrim)
          // stop at the bar's top edge.
          extendBody: true,
          body: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: navOverlayInset(context)),
                  child: const AddPanelHost(),
                ),
              ),
            ],
          ),
          bottomNavigationBar: AppBottomNavigation(
            currentIndex: _tab,
            addPanelOpen: panelOpen,
            onToggleAdd: panel.toggle,
            onSelectTab: (index) {
              panel.close();
              _logTabOpened(index);
              context.go(AppRoutes.tabPaths[index]);
            },
          ),
        ),
      ),
    );
  }
}

/// Dim scrim plus the add/edit panel, sliding up from the bottom of the body
/// (which is the top edge of the navigation bar, so the bar stays visible).
class AddPanelHost extends ConsumerStatefulWidget {
  const AddPanelHost({super.key});

  @override
  ConsumerState<AddPanelHost> createState() => _AddPanelHostState();
}

class _AddPanelHostState extends ConsumerState<AddPanelHost>
    with SingleTickerProviderStateMixin {
  static const _maxPanelWidth = 520.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AddPanelState>(addPanelProvider, (previous, next) {
      if (next.open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Nothing is built while closed, so the form state resets each time.
        if (_controller.isDismissed) return const SizedBox.shrink();

        final progress = Curves.easeOutCubic.transform(_controller.value);

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    button: true,
                    label: context.l10n.addPanelClose,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: ref.read(addPanelProvider.notifier).close,
                      child: ColoredBox(
                        color: Colors.black.withValues(
                          alpha: 0.55 * _controller.value,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - progress),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _maxPanelWidth,
                      ),
                      child: AddSubscriptionPanel(
                        // Read when the panel is built, so closing (which keeps
                        // the item) does not rebuild it into add mode.
                        editing: ref.read(addPanelProvider).editing,
                        maxHeight: constraints.maxHeight * 0.92,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
