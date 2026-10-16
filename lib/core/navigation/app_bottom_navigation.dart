import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/trackly_tokens.dart';
import '../theme/trackly_type.dart';

/// Bottom navigation: a floating pill with Home, Insights, Calendar and More,
/// and a round Add button floating beside it on the right.
///
/// The Add button is not a tab: it toggles the add panel and turns into a
/// cross while the panel is open.
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

  static const barHeight = 68.0;

  /// Space the floating bar takes from the bottom of the screen (its height
  /// plus the margins around it), not counting the system inset.
  static const overlayHeight = barHeight + 8 + 12;
  static const _addButtonSize = 64.0;
  static const _margin = 16.0;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = context.l10n;

    // Transparent: the page shows around the floating pieces.
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_margin, 8, _margin, _margin - 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.navBackground,
                  borderRadius: BorderRadius.circular(barHeight / 2),
                  border: Border.all(color: tokens.navBorder),
                  boxShadow: _shadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(barHeight / 2),
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
              ),
            ),
            const SizedBox(width: _gap),
            Semantics(
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
          ],
        ),
      ),
    );
  }

  static final _shadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];
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

/// How far the floating navigation bar reaches up from the bottom of the
/// screen. Scrollable screens add it to their bottom padding so their last
/// item can be scrolled clear of the bar.
double navOverlayInset(BuildContext context) =>
    MediaQuery.viewPaddingOf(context).bottom +
    AppBottomNavigation.overlayHeight;
