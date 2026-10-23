import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared timings and curves, so every animation in the app feels related.
abstract final class Motion {
  static const enter = Duration(milliseconds: 380);
  static const page = Duration(milliseconds: 340);
  static const pageBack = Duration(milliseconds: 240);
  static const stagger = Duration(milliseconds: 70);
  static const countUp = Duration(milliseconds: 800);
  static const select = Duration(milliseconds: 240);
  static const swap = Duration(milliseconds: 260);

  static const curve = Curves.easeOutCubic;
}

/// [duration], or none when the system asks to reduce motion.
Duration motionDuration(BuildContext context, Duration duration) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

/// A page that fades in while rising a little, and fades out going back.
/// Used for the screens opened from a tab (item, lists, settings...).
CustomTransitionPage<void> motionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.page,
    reverseTransitionDuration: Motion.pageBack,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Reduced motion: still a quick fade, but no travel.
      if (MediaQuery.disableAnimationsOf(context)) {
        return FadeTransition(opacity: animation, child: child);
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.curve,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Fades and slides [child] in when it first appears, [index] steps after the
/// start so a column of sections arrives one after another.
///
/// Plays once, and not at all when the system asks to reduce motion.
class Reveal extends StatefulWidget {
  const Reveal({required this.child, this.index = 0, super.key});

  final Widget child;
  final int index;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.enter,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.curve,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    // Capped so a long list does not make the last rows wait.
    final steps = widget.index.clamp(0, 6);
    Future<void>.delayed(Motion.stagger * steps, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}
