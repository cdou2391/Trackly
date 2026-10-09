import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the add-subscription panel is open above the bottom navigation.
class AddPanelController extends Notifier<bool> {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
  void toggle() => state = !state;
}

final addPanelProvider = NotifierProvider<AddPanelController, bool>(
  AddPanelController.new,
);
