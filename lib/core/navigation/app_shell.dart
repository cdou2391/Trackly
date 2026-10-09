import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/subscriptions/application/add_panel_controller.dart';
import '../../features/subscriptions/presentation/widgets/add_subscription_panel.dart';
import '../../l10n/l10n.dart';

/// Bottom navigation shell: Home, Insights, Add, Calendar, More.
///
/// The centered Add button is not a tab. It opens the add panel, which slides
/// up from the navigation bar over the current screen.
class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = shell.currentIndex;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final navTheme = theme.navigationBarTheme;
    final panelOpen = ref.watch(addPanelProvider);
    final panel = ref.read(addPanelProvider.notifier);

    void goTo(int index) {
      panel.close();
      shell.goBranch(index);
    }

    return PopScope(
      // Back closes the panel first instead of leaving the app.
      canPop: !panelOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) panel.close();
      },
      child: Scaffold(
        body: Stack(children: [shell, const AddPanelHost()]),
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
                    onTap: () => goTo(0),
                  ),
                  _NavItem(
                    icon: Icons.insights_rounded,
                    label: context.l10n.navInsights,
                    selected: current == 1,
                    onTap: () => goTo(1),
                  ),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        button: true,
                        label: panelOpen
                            ? context.l10n.addPanelClose
                            : context.l10n.navAdd,
                        child: Material(
                          color: scheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: panel.toggle,
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              // The plus turns into a cross while open.
                              child: AnimatedRotation(
                                turns: panelOpen ? 0.125 : 0,
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
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
                  ),
                  _NavItem(
                    icon: Icons.calendar_month_rounded,
                    label: context.l10n.navCalendar,
                    selected: current == 2,
                    onTap: () => goTo(2),
                  ),
                  _NavItem(
                    icon: Icons.more_horiz_rounded,
                    label: context.l10n.navMore,
                    selected: current == 3,
                    onTap: () => goTo(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dim scrim plus the add panel, sliding up from the bottom of the body (which
/// is the top edge of the navigation bar, so the bar stays visible).
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
    ref.listen<bool>(addPanelProvider, (previous, open) {
      if (open) {
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
