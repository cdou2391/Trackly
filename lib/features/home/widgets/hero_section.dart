import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/trackly_tokens.dart';
import '../application/home_summary.dart';
import 'hero_amount.dart';

/// The Home top section: header and recurring-cost hero.
///
/// Light draws a rounded cream card under a plain header. Dark draws a
/// full-bleed teal field that runs up behind the status bar, with the header
/// inside it and one wide arc as its bottom edge.
class HeroSection extends StatelessWidget {
  const HeroSection({
    required this.header,
    required this.summary,
    required this.defaultCurrency,
    super.key,
  });

  final Widget header;
  final HomeSummary summary;
  final String defaultCurrency;

  @override
  Widget build(BuildContext context) {
    final amount = HeroAmount(
      summary: summary,
      defaultCurrency: defaultCurrency,
    );
    final asset = context.tokens.heroIllustration;

    return switch (context.tokens.heroStyle) {
      HeroStyle.card => _HeroCard(header: header, amount: amount, asset: asset),
      HeroStyle.fullBleedArc => _ArcHero(
        header: header,
        amount: amount,
        asset: asset,
      ),
    };
  }
}

/// Keeps content readable on tablets.
const _maxContentWidth = 520.0;

// ---------------------------------------------------------------- light card

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.header,
    required this.amount,
    required this.asset,
  });

  final Widget header;
  final Widget amount;
  final String asset;

  static const _radius = 28.0;
  static const _minHeight = 236.0;

  /// Share of the card the illustration may take; the amount stays left of it.
  static const _artShare = 0.56;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            // Stretch: inside Center a Column would otherwise shrink to its
            // narrowest content and the card would not span the screen.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TracklySpacing.base,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tokens.heroFill, tokens.heroFillEnd],
                    ),
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: tokens.heroBorder),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_radius - 1),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: _minHeight,
                          ),
                          child: Stack(
                            children: [
                              // Purely decorative, so hidden from screen
                              // readers.
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: ExcludeSemantics(
                                    child: SvgPicture.asset(
                                      asset,
                                      width: width * _artShare,
                                      alignment: Alignment.bottomRight,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  TracklySpacing.xl - 2,
                                  TracklySpacing.xl,
                                  0,
                                  TracklySpacing.xl,
                                ),
                                child: SizedBox(
                                  // Leaves the right side to the illustration.
                                  width: width * 0.58,
                                  child: amount,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- dark arc

class _ArcHero extends StatelessWidget {
  const _ArcHero({
    required this.header,
    required this.amount,
    required this.asset,
  });

  final Widget header;
  final Widget amount;
  final String asset;

  /// How far the bottom edge dips: the sides sit this much higher than the
  /// middle.
  static const _bottomSag = 36.0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // A deep teal field (the brand accent, darkened) set against the black
    // page; its bottom edge is one wide sweeping arc.
    return ClipPath(
      clipper: const _SweepingBottomClipper(sag: _bottomSag),
      child: ColoredBox(
        color: tokens.heroFill,
        child: Padding(
          // The teal runs up behind the status bar, so the content starts
          // below it.
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top,
            bottom: _bottomSag + TracklySpacing.md,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TracklySpacing.xl,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: amount),
                        const SizedBox(width: TracklySpacing.sm),
                        _ArcIllustration(asset: asset),
                      ],
                    ),
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

/// The artwork is drawn larger than the room it reserves in the row, spilling
/// leftwards over its own transparent margin, so it can be big without
/// squeezing the amount.
class _ArcIllustration extends StatelessWidget {
  const _ArcIllustration({required this.asset});

  final String asset;

  static const _slotWidth = 120.0;
  static const _slotHeight = 108.0;
  static const _artWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _slotWidth,
        height: _slotHeight,
        child: OverflowBox(
          alignment: Alignment.centerRight,
          minWidth: _artWidth,
          maxWidth: _artWidth,
          minHeight: 0,
          maxHeight: _artWidth,
          child: SvgPicture.asset(asset, width: _artWidth),
        ),
      ),
    );
  }
}

/// Clips the bottom edge to one wide arc, edge to edge: the sides sit [sag]
/// higher than the middle, which is the lowest point.
class _SweepingBottomClipper extends CustomClipper<Path> {
  const _SweepingBottomClipper({required this.sag});

  final double sag;

  @override
  Path getClip(Size size) {
    final sides = size.height - sag;
    // A quadratic curve reaches only half-way to its control point, so the
    // control point sits `sag` below the bottom for the middle to land on it.
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, sides)
      ..quadraticBezierTo(size.width / 2, size.height + sag, 0, sides)
      ..close();
  }

  @override
  bool shouldReclip(_SweepingBottomClipper old) => old.sag != sag;
}
