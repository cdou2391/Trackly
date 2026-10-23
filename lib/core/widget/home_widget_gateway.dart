import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

/// Hands data to the Android home-screen widget and asks it to redraw.
abstract class HomeWidgetGateway {
  /// Replaces the values the widget reads.
  Future<void> save(Map<String, Object?> data);

  /// Redraws every placed widget.
  Future<void> refresh();
}

/// Used where there is no launcher (tests, unsupported platforms).
class NoopHomeWidgetGateway implements HomeWidgetGateway {
  const NoopHomeWidgetGateway();

  @override
  Future<void> save(Map<String, Object?> data) async {}

  @override
  Future<void> refresh() async {}
}

/// Android implementation on top of `home_widget`.
class AndroidHomeWidgetGateway implements HomeWidgetGateway {
  const AndroidHomeWidgetGateway();

  static const providerClass = 'com.corecrest.trackly.TracklyWidgetProvider';

  @override
  Future<void> save(Map<String, Object?> data) async {
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData<String?>(
        entry.key,
        entry.value as String?,
      );
    }
  }

  @override
  Future<void> refresh() async {
    await HomeWidget.updateWidget(qualifiedAndroidName: providerClass);
  }
}

/// Overridden in `main.dart` with the real implementation.
final homeWidgetGatewayProvider = Provider<HomeWidgetGateway>(
  (ref) => const NoopHomeWidgetGateway(),
);
