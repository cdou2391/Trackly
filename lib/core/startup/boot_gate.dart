import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';

/// Shows the [SplashScreen] while the app starts, then swaps in the app.
///
/// [bootstrap] does the real start-up work (database, notifications,
/// preferences) and returns the app to show. The splash stays for at least
/// [minimumDisplay] so a fast start does not flash the logo and vanish, and for
/// as long as start-up takes if that is longer. If start-up fails the splash
/// offers "Try again" instead of spinning forever.
class BootGate extends StatefulWidget {
  const BootGate({
    required this.bootstrap,
    this.onError,
    this.minimumDisplay = defaultMinimumDisplay,
    super.key,
  });

  /// Long enough for the logo to settle in and be read, short enough not to
  /// feel like waiting.
  static const defaultMinimumDisplay = Duration(milliseconds: 1000);

  final Future<Widget> Function() bootstrap;

  /// Told about a failed start (for error reporting).
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Duration minimumDisplay;

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  Widget? _app;
  bool _failed = false;

  /// Guards against an old attempt finishing after a retry.
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    if (_failed) setState(() => _failed = false);

    final minimum = Future<void>.delayed(widget.minimumDisplay);
    try {
      final app = await widget.bootstrap();
      await minimum;
      if (!mounted || attempt != _attempt) return;
      setState(() => _app = app);
    } catch (error, stackTrace) {
      widget.onError?.call(error, stackTrace);
      if (!mounted || attempt != _attempt) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = _app;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: app != null
          ? KeyedSubtree(key: const ValueKey('app'), child: app)
          : _SplashApp(
              key: const ValueKey('splash'),
              error: _failed,
              onRetry: _start,
            ),
    );
  }
}

/// A minimal app around the splash: the theme and strings, no providers.
class _SplashApp extends StatelessWidget {
  const _SplashApp({required this.error, required this.onRetry, super.key});

  final bool error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // The app starts in the light theme until the user can choose one.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        ),
        child: child!,
      ),
      home: SplashScreen(error: error, onRetry: onRetry),
    );
  }
}
