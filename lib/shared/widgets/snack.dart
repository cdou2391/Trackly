import 'package:flutter/material.dart';

extension ReplacingSnackBars on ScaffoldMessengerState {
  /// Shows [snackBar] now, replacing any message already showing instead of
  /// queueing behind it (a message with an Undo action would otherwise block
  /// the next one).
  void showReplacing(SnackBar snackBar) {
    hideCurrentSnackBar();
    showSnackBar(snackBar);
  }
}
