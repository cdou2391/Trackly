/// Addresses the app points people to. Change them here, in one place.
///
/// The privacy policy is its own page for Trackly, separate from the CoreCrest
/// website's policy: it must describe what this app collects (usage metrics
/// and crash reports) and is the URL given to Google Play. The address is
/// permanent once published, because every installed copy of the app uses it.
abstract final class AppLinks {
  static const privacyPolicy = 'https://corecrest.tech/trackly/privacy-policy';

  static const supportEmail = 'info@corecrest.tech';

  static Uri get privacyPolicyUri => Uri.parse(privacyPolicy);

  static Uri get supportUri => Uri(
    scheme: 'mailto',
    path: supportEmail,
    queryParameters: {'subject': 'Trackly support'},
  );
}
