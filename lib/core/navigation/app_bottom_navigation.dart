import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/trackly_tokens.dart';
import '../theme/trackly_type.dart';

/// Bottom navigation: Home, Insights, Add, Calendar, More.
///
/// The centered Add button is not a tab: it toggles the add panel and turns
/// into a cross while the panel is open.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.currentIndex,
    required this.addPanelOpen,
    required this.onSelectTab,
    required this.onToggleAdd,
    super.key,
  });

  /// Selected tab (0 Home, 1 Insights, 2 Calendar, 3 More).
  final int currentIndex;
  final bool addPanelOpen;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onToggleAdd;

  static const barHeight = 76.0;
  static const _addButtonSize = 62.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.navBackground,
        border: Border(top: BorderSide(color: tokens.navBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                selected: currentIndex == 0,
                onTap: () => onSelectTab(0),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: l10n.navInsights,
                selected: currentIndex == 1,
                onTap: () => onSelectTab(1),
              ),
              Expanded(
                child: Center(
                  child: Semantics(
                    button: true,
                    label: addPanelOpen ? l10n.addPanelClose : l10n.navAdd,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.navCenterFill,
                        boxShadow: [
                          BoxShadow(
                            color: tokens.navCenterFill.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onToggleAdd,
                          child: SizedBox(
                            width: _addButtonSize,
                            height: _addButtonSize,
                            // The plus turns into a cross while open.
                            child: AnimatedRotation(
                              turns: addPanelOpen ? 0.125 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                Icons.add_rounded,
                                color: tokens.navCenterIcon,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                label: l10n.navCalendar,
                selected: currentIndex == 2,
                onTap: () => onSelectTab(2),
              ),
              _NavItem(
                icon: Icons.more_horiz_rounded,
                label: l10n.navMore,
                selected: currentIndex == 3,
                onTap: () => onSelectTab(3),
              ),
            ],
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
    final tokens = context.tokens;
    final iconColor = selected ? tokens.navActive : tokens.navInactive;
    // Text uses the deeper accent shade so small labels keep their contrast.
    final labelColor = selected ? tokens.accentText : tokens.navInactive;

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
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(height: 2),
                // One line always: at large text sizes the label scales down
                // instead of wrapping and overflowing the bar.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: sans(
                        12,
                        weight: selected ? 600 : 500,
                        color: labelColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // A small dot marks the current tab.
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? tokens.navActive : Colors.transparent,
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
