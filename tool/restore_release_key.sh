#!/usr/bin/env bash
# Restores the release keystore from the ANDROID_KEYSTORE_BASE64 secret and
# checks that it opens, so a bad secret fails in seconds with a clear reason
# instead of after the tests and the build.
#
# Reads KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and
# ANDROID_KEY_PASSWORD from the environment, writes the keystore to $1 and
# needs keytool (any JDK). It never prints a secret; when the keystore value is
# malformed it reports only counts.
set -euo pipefail

dest="${1:?usage: tool/restore_release_key.sh <output .jks path>}"

fail() {
  echo "::error::$*"
  exit 1
}

missing=0
for name in KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
  if [ -z "${!name:-}" ]; then
    echo "::error::The value for $name is missing or empty. See docs/release_signing.md."
    missing=1
  fi
done
[ "$missing" -eq 0 ] || exit 1

# Copying a long value often adds spaces, line breaks or a CR; those are harmless.
clean="$(printf '%s' "$KEYSTORE_BASE64" | tr -d ' \t\r\n')"
length="${#clean}"

bad="$(printf '%s' "$clean" | tr -d 'A-Za-z0-9+/=' | wc -c | tr -d ' ')"
if [ "$bad" -ne 0 ]; then
  fail "ANDROID_KEYSTORE_BASE64 contains $bad characters that are not base64 (length $length). It was probably copied with extra text such as a shell prompt, quotes or a label. Re-create it with: base64 -w0 trackly-release.jks | base64 -d | cmp - trackly-release.jks && base64 -w0 trackly-release.jks"
fi

if [ $((length % 4)) -ne 0 ]; then
  fail "ANDROID_KEYSTORE_BASE64 has length $length, which is not a multiple of 4: the value was cut off or altered when it was copied. Set it again, preferably straight from the command (see docs/release_signing.md)."
fi

if ! printf '%s' "$clean" | base64 -d > "$dest" 2>/dev/null || [ ! -s "$dest" ]; then
  fail "ANDROID_KEYSTORE_BASE64 (length $length) is not valid base64. Set it again from the output of: base64 -w0 trackly-release.jks"
fi
echo "Decoded the keystore ($(wc -c < "$dest" | tr -d ' ') bytes)."

if ! listing="$(keytool -list -keystore "$dest" \
  -storepass "$ANDROID_KEYSTORE_PASSWORD" -alias "$ANDROID_KEY_ALIAS" 2>&1)"; then
  echo "$listing" | grep -v '^Picked up' >&2 || true
  fail "The keystore would not open with ANDROID_KEYSTORE_PASSWORD and ANDROID_KEY_ALIAS. Check the password and the alias (the doc uses 'trackly'). If the base64 value was made from a different file, re-create it."
fi

# Opening the keystore proves the store password and alias, not the key's own
# password, which Gradle also needs. A PKCS12 keystore (the keytool default)
# protects the key with the store password, so the two must be identical.
# (No -alias here: with it, keytool leaves out the "Keystore type" line.)
details="$(keytool -list -v -keystore "$dest" \
  -storepass "$ANDROID_KEYSTORE_PASSWORD" 2>/dev/null || true)"
if echo "$details" | grep -q '^Keystore type: PKCS12'; then
  if [ "$ANDROID_KEY_PASSWORD" != "$ANDROID_KEYSTORE_PASSWORD" ]; then
    fail "This is a PKCS12 keystore, which uses one password for the store and the key. Set ANDROID_KEY_PASSWORD to the same value as ANDROID_KEYSTORE_PASSWORD."
  fi
fi

# Shown so it can be compared with the fingerprint saved when the key was made.
echo "$listing" | grep -i 'fingerprint' || true
echo "Release key OK."
