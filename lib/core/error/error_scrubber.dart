import 'package:sentry_flutter/sentry_flutter.dart';

/// Removes what a database error says about the values being written.
///
/// A failed SQLite statement describes itself as
/// `... Causing statement: INSERT ... VALUES (?, ?), parameters: Netflix, 15.5`
/// and Drift passes that text on. The statement is safe (it only has
/// placeholders) but the parameters are what the user typed: names, amounts,
/// notes. They must never leave the phone in an error report, so everything
/// from `parameters:` onward is replaced.
String scrubErrorText(String text) {
  return text.replaceFirst(
    RegExp(r', parameters: .*', dotAll: true),
    ', parameters: [removed]',
  );
}

/// The `beforeSend` hook for Sentry: scrubs the text of every exception and
/// message in the event, then lets it go.
SentryEvent scrubSentryEvent(SentryEvent event, Hint hint) {
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    final value = exception.value;
    if (value != null) exception.value = scrubErrorText(value);
  }
  final message = event.message;
  if (message != null) {
    message.formatted = scrubErrorText(message.formatted);
    final template = message.template;
    if (template != null) message.template = scrubErrorText(template);
    // Parameters of a log-style message could be anything the caller passed.
    message.params = null;
  }
  return event;
}
