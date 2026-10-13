import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web page or a mail draft in another app. A seam, so tests do not
/// need the plugin.
abstract class LinkOpener {
  /// True when something opened the address.
  Future<bool> open(Uri uri);
}

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const UrlLauncherLinkOpener(),
);
