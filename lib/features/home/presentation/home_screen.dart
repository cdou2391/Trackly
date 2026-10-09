import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_reporter.dart';
import '../../settings/application/settings_providers.dart';
import '../../subscriptions/presentation/widgets/quick_add_card.dart';
import '../application/home_providers.dart';
import '../application/home_summary.dart';
import '../widgets/charge_sections.dart';
import '../widgets/hero_section.dart';
import '../widgets/home_header.dart';
import '../widgets/status_summary.dart';

/// Keeps content readable on tablets and large phones.
const _maxContentWidth = 520.0;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(homeSummaryProvider);

    return summary.when(
      data: (data) => _HomeContent(summary: data),
      loading: () =>
          const SafeArea(child: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) {
        ref.read(errorReporterProvider).captureException(error, stackTrace);
        return const SizedBox.shrink();
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider)();

    // The teal hero (with the header inside it) is full width and runs up
    // behind the status bar; everything else is held to a readable width.
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        HeroSection(
          header: const HomeHeader(),
          summary: summary,
          defaultCurrency: ref.watch(defaultCurrencyProvider),
        ),
        _Constrained(child: StatusSummary(summary: summary)),
        const _Constrained(child: QuickAddCard()),
        _Constrained(
          child: UpcomingSection(summary: summary, now: now),
        ),
        _Constrained(child: RecentPaymentsSection(summary: summary)),
      ],
    );
  }
}

class _Constrained extends StatelessWidget {
  const _Constrained({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: child,
      ),
    );
  }
}
