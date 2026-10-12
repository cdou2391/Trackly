import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/trackly_tokens.dart';
import '../theme/trackly_type.dart';

/// The logo, the app name and its tagline, with a small loader underneath.
///
/// Shown while the app starts. With animations turned off (the system
/// "remove animations" setting) it appears fully drawn and the loader is still.
class SplashScreen extends StatefulWidget {
  const SplashScreen({this.error = false, this.onRetry, super.key});

  /// Replaces the loader with a message and a "Try again" button.
  final bool error;
  final VoidCallback? onRetry;

  static const logoAsset = 'assets/illustrations/trackly_logo.svg';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final size = MediaQuery.sizeOf(context);

    // Big, but never wider than half the screen or taller than a third of it.
    final logoWidth = (size.shortestSide * 0.52).clamp(140.0, 260.0);

    final logo = SizedBox(
      width: logoWidth,
      child: ExcludeSemantics(
        child: SvgPicture.asset(SplashScreen.logoAsset, width: logoWidth),
      ),
    );

    final name = Semantics(
      header: true,
      child: Text(
        l10n.appName,
        textAlign: TextAlign.center,
        style: serif(44, color: theme.colorScheme.onSurface, height: 1.1),
      ),
    );

    final tagline = Text(
      l10n.appTagline,
      textAlign: TextAlign.center,
      style: sans(
        17,
        weight: 500,
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TracklySpacing.xl),
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_entrance.value);
                // The logo settles in first; the words follow a beat later.
                final text = Curves.easeOut.transform(
                  ((_entrance.value - 0.35) / 0.65).clamp(0.0, 1.0),
                );
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: t,
                      child: Transform.scale(scale: 0.9 + 0.1 * t, child: logo),
                    ),
                    const SizedBox(height: TracklySpacing.xl),
                    Opacity(
                      opacity: text,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - text)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            name,
                            const SizedBox(height: TracklySpacing.sm),
                            tagline,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: TracklySpacing.xxl),
                    Opacity(
                      opacity: text,
                      child: widget.error
                          ? _ErrorNotice(onRetry: widget.onRetry)
                          : _Loader(controller: _pulse, color: tokens.accent),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots that swell in turn.
class _Loader extends StatelessWidget {
  const _Loader({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.splashLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: _Dot(
                      color: color,
                      // Each dot peaks a third of a cycle after the last one.
                      level: controller.isAnimating
                          ? _swell((controller.value - i / 3) % 1.0)
                          : 0.6,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 0..1 rising then falling over one cycle (a smooth hump).
  static double _swell(double phase) {
    final p = phase < 0 ? phase + 1 : phase;
    return p < 0.5
        ? Curves.easeInOut.transform(p * 2)
        : Curves.easeInOut.transform((1 - p) * 2);
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.level});

  final Color color;
  final double level;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.35 + 0.65 * level,
      child: Container(
        width: 9 + 4 * level,
        height: 9 + 4 * level,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.splashErrorTitle,
          textAlign: TextAlign.center,
          style: sans(16, weight: 600, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: TracklySpacing.xs),
        Text(
          l10n.splashErrorBody,
          textAlign: TextAlign.center,
          style: sans(14, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: TracklySpacing.base),
        FilledButton(onPressed: onRetry, child: Text(l10n.splashRetry)),
      ],
    );
  }
}
