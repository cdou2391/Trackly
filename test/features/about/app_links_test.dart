import 'package:flutter_test/flutter_test.dart';
import 'package:trackly/core/config/app_links.dart';
import 'package:trackly/features/about/application/app_info.dart';

void main() {
  test('the privacy policy is Trackly\'s own page, over https', () {
    // This address is given to Google Play and baked into every installed
    // app, so a change here must be deliberate.
    expect(
      AppLinks.privacyPolicy,
      'https://corecrest.tech/trackly/privacy-policy',
    );
    final uri = AppLinks.privacyPolicyUri;
    expect(uri.scheme, 'https');
    expect(uri.host, 'corecrest.tech');
    expect(uri.path, '/trackly/privacy-policy');
  });

  test('support opens a mail draft to the support address', () {
    final uri = AppLinks.supportUri;
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'info@corecrest.tech');
    expect(uri.queryParameters['subject'], 'Trackly support');
  });

  test('the version label shows the build number when known', () {
    expect(const AppInfo(version: '1.0.0', build: '8').label, '1.0.0 (8)');
    expect(const AppInfo(version: '1.0.0', build: '').label, '1.0.0');
  });
}
