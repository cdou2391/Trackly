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

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: summary.when(
            data: (data) => _HomeContent(summary: data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) {
              ref.read(errorReporterProvider).captureException(error, stackTrace);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.summary});

  final HomeSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider)();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const HomeHeader(),
        HeroSection(
          summary: summary,
          defaultCurrency: ref.watch(defaultCurrencyProvider),
        ),
        StatusSummary(summary: summary),
        const QuickAddCard(),
        UpcomingSection(summary: summary, now: now),
        RecentPaymentsSection(summary: summary),
      ],
    );
  }
}
