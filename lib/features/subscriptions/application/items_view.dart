import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_reporter.dart';
import '../../settings/application/settings_store.dart';

/// How All subscriptions is drawn: drifting bubbles (the default) or a list.
/// The choice is kept on the phone.
class ItemsAsBubbles extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsStoreProvider).itemsAsBubbles ?? true;

  Future<void> set(bool bubbles) async {
    if (bubbles == state) return;
    state = bubbles;
    // The choice is already on screen, so a storage problem is reported, not
    // shown.
    try {
      await ref.read(settingsStoreProvider).setItemsAsBubbles(bubbles);
    } catch (error, stackTrace) {
      await ref.read(errorReporterProvider).captureException(error, stackTrace);
    }
  }
}

final itemsAsBubblesProvider = NotifierProvider<ItemsAsBubbles, bool>(
  ItemsAsBubbles.new,
);
