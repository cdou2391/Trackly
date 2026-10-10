import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recurring_item.dart';

/// State of the sliding add/edit panel.
class AddPanelState {
  const AddPanelState({this.open = false, this.editing});

  final bool open;

  /// The item being edited, or null when adding a new one. Kept after the panel
  /// closes so the right screen can finish the closing animation; it is reset
  /// the next time the panel is opened.
  final RecurringItem? editing;
}

/// Controls the panel that slides up above the navigation bar (to add) or from
/// the bottom of an item's screen (to edit).
class AddPanelController extends Notifier<AddPanelState> {
  @override
  AddPanelState build() => const AddPanelState();

  void open() => state = const AddPanelState(open: true);

  void openForEdit(RecurringItem item) =>
      state = AddPanelState(open: true, editing: item);

  void close() => state = AddPanelState(open: false, editing: state.editing);

  void toggle() => state.open ? close() : open();
}

final addPanelProvider = NotifierProvider<AddPanelController, AddPanelState>(
  AddPanelController.new,
);
