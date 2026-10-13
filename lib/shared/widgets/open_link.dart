import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/link_opener.dart';
import '../../l10n/l10n.dart';
import 'snack.dart';

/// Opens [uri] in another app. If nothing can open it, says so and shows the
/// address so the person can still reach it by hand.
Future<void> openLink(BuildContext context, WidgetRef ref, Uri uri) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  final opened = await ref.read(linkOpenerProvider).open(uri);
  if (!opened) {
    final shown = uri.scheme == 'mailto' ? uri.path : uri.toString();
    messenger.showReplacing(
      SnackBar(content: Text(l10n.linkOpenFailed(shown))),
    );
  }
}
