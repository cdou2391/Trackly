import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_router.dart';
import 'core/notifications/reminder_sync.dart';
import 'core/notifications/reminder_taps.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/application/settings_providers.dart';
import 'features/subscriptions/application/catalog_backfill.dart';
import 'l10n/app_localizations.dart';

class TracklyApp extends ConsumerWidget {
  const TracklyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Give existing items their catalog logo (runs once per launch).
    ref.watch(catalogBackfillProvider);
    // Keep scheduled reminders in step with the data, and open tapped ones.
    ref.watch(reminderSyncProvider);
    ref.watch(reminderTapsProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) {
        // Status and navigation bar icons must contrast with the page.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarContrastEnforced: false,
          ),
          child: child!,
        );
      },
    );
  }
}
