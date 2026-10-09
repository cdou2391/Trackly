import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Currency used for new items until the settings screen exists.
final defaultCurrencyProvider = Provider<String>((ref) => 'USD');
