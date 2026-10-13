import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The installed version, as shown on the About screen.
class AppInfo {
  const AppInfo({required this.version, required this.build});

  /// For example `1.0.0`.
  final String version;

  /// The version code Android compares for updates, for example `8`.
  final String build;

  /// `1.0.0 (8)`, or just `1.0.0` when the build number is unknown.
  String get label => build.isEmpty ? version : '$version ($build)';
}

final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return AppInfo(version: info.version, build: info.buildNumber);
});
