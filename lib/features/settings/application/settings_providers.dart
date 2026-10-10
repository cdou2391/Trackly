import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currency used for new items until the settings screen exists.
final defaultCurrencyProvider = Provider<String>((ref) => 'USD');

/// App theme. Light is the current design; the settings screen will let the
/// user choose (and persist) light, dark or system.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
