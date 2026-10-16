import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/navigation/app_bottom_navigation.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../../../core/theme/trackly_type.dart';
import '../../../core/utils/format_utils.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/service_icon.dart';
import '../application/bubble_physics.dart';
import '../domain/recurring_enums.dart';
import '../domain/recurring_item.dart';
import 'labels.dart';

/// Subscriptions and bills as circles that drift around the screen. Bigger
/// means costlier (within a currency). Tap one to open it.
///
/// The bubbles stand still for anyone who asked their phone to reduce motion
/// or who uses a screen reader, where things that move are hard to hit. With
/// many items the field grows taller and scrolls, so every bubble stays a
/// comfortable size.
class SubscriptionBubbles extends StatelessWidget {
  const SubscriptionBubbles({
    required this.items,
    required this.now,
    required this.onOpen,
    super.key,
  });

  final List<RecurringItem> items;
  final DateTime now;
  final void Function(RecurringItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    // Larger text makes the bubbles larger too, so names stay readable.
    final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(
      1.0,
      1.3,
    );

    final radii = bubbleRadii(items, scale: textScale);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = bubbleFieldHeight(
          radii,
          width: width,
          minHeight: constraints.maxHeight.isFinite ? constraints.maxHeight : 0,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.only(bottom: navOverlayInset(context)),
          child: SizedBox(
            width: width,
            height: height,
            child: _BubbleField(
              // New items, or a changed cost, start a new layout.
              key: ValueKey(
                '${items.map((i) => i.id).join(',')}|'
                '${radii.map((r) => r.round()).join(',')}|'
                '${width.round()}x${height.round()}',
              ),
              items: items,
              radii: radii,
              now: now,
              onOpen: onOpen,
              size: Size(width, height),
            ),
          ),
        );
      },
    );
  }
}

class _BubbleField extends StatefulWidget {
  const _BubbleField({
    required this.items,
    required this.radii,
    required this.now,
    required this.onOpen,
    required this.size,
    super.key,
  });

  final List<RecurringItem> items;
  final List<double> radii;
  final DateTime now;
  final void Function(RecurringItem item) onOpen;
  final Size size;

  @override
  State<_BubbleField> createState() => _BubbleFieldState();
}

class _BubbleFieldState extends State<_BubbleField>
    with SingleTickerProviderStateMixin {
  /// Nudged on every frame that moves the bubbles.
  final _moved = ValueNotifier<int>(0);

  late final BubblePhysics _physics;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _pending = 0;

  /// About 30 frames a second is plenty for a slow drift and halves the
  /// battery cost of 60.
  static const _frame = 1 / 30;

  @override
  void initState() {
    super.initState();
    _physics = BubblePhysics(
      radii: widget.radii,
      seed: Object.hashAll(widget.items.map((i) => i.id)),
    )..resize(widget.size);
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (still) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    _pending += (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (_pending < _frame) return;
    _physics.step(_pending);
    _pending = 0;
    _moved.value++;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _moved.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Each bubble is placed in the layout (not just drawn somewhere else), so
    // the spot that takes a tap moves with it.
    return Stack(
      children: [
        for (var i = 0; i < widget.items.length; i++)
          AnimatedBuilder(
            animation: _moved,
            // The bubble itself is built once; only its place changes.
            child: RepaintBoundary(
              child: _Bubble(
                item: widget.items[i],
                radius: widget.radii[i],
                now: widget.now,
                onTap: () => widget.onOpen(widget.items[i]),
              ),
            ),
            builder: (context, child) {
              final b = _physics.bubbles[i];
              return Positioned(
                left: b.x - b.radius,
                top: b.y - b.radius,
                child: child!,
              );
            },
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.item,
    required this.radius,
    required this.now,
    required this.onTap,
  });

  final RecurringItem item;
  final double radius;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final locale = Localizations.localeOf(context).toString();

    final chips = itemChips(context, item, now);
    final trial = chips.any((chip) => chip.label == l10n.pillTrial);
    final cancelled = item.status == ItemStatus.cancelled;
    final amount = formatMoney(item.amount, item.currencyCode, locale: locale);
    final status = chips.map((chip) => chip.label).join(', ');

    // A trial wears the accent as its ring; a cancelled item fades back.
    final ring = trial ? tokens.accent : tokens.cardBorder;
    final diameter = radius * 2;
    final nameSize = 11 + 2 * ((radius - bubbleMinRadius) / 24).clamp(0.0, 1.0);

    return Semantics(
      container: true,
      button: true,
      label: l10n.bubbleSemantics(item.name, amount, status),
      excludeSemantics: true,
      child: Opacity(
        opacity: cancelled ? 0.55 : 1,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Material(
            color: theme.colorScheme.surface,
            elevation: 1.5,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            shape: CircleBorder(side: BorderSide(color: ring, width: 2)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  radius * 0.1,
                  radius * 0.16,
                  radius * 0.1,
                  radius * 0.14,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ServiceIcon(
                      logoKey: item.logoKey,
                      categoryId: item.categoryId,
                      size: math.max(28, radius * 0.9),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textScaler: TextScaler.noScaling,
                      textAlign: TextAlign.center,
                      style: sans(
                        nameSize,
                        weight: 600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
