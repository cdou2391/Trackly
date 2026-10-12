#!/usr/bin/env bash
# Fails unless an APK still contains a named resource, e.g.
#   tool/apk_has_resource.sh app-release.apk drawable/ic_stat_notify
#
# Release builds delete resources nothing references. Anything the app looks
# up by name at run time (the reminder icon) must survive, or the feature
# breaks only in release builds and only silently.
# Needs the Android SDK build-tools (ANDROID_HOME), as on the CI runners.
set -euo pipefail

apk="${1:?usage: tool/apk_has_resource.sh <apk> <type/name>}"
resource="${2:?usage: tool/apk_has_resource.sh <apk> <type/name>}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$sdk" ]; then
  echo "apk_has_resource: set ANDROID_HOME to the Android SDK" >&2
  exit 1
fi

aapt2="$(ls -d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"
if [ -z "$aapt2" ]; then
  echo "apk_has_resource: no aapt2 under $sdk/build-tools" >&2
  exit 1
fi

# Write to a file first: grep -q would close the pipe early and, with
# pipefail, turn a match into a failure.
listing="$(mktemp)"
trap 'rm -f "$listing"' EXIT
if ! "$aapt2" dump resources "$apk" > "$listing" 2>&1; then
  echo "apk_has_resource: aapt2 could not read $apk:" >&2
  cat "$listing" >&2
  exit 1
fi

if grep -F ":$resource" "$listing" > /dev/null; then
  echo "apk_has_resource: $resource is in the APK"
else
  echo "::error::$resource is missing from the APK. The release build removed it, so reminders would never show. Check android/app/src/main/res/raw/keep.xml." >&2
  echo "Resources matching the name:" >&2
  grep -F "${resource#*/}" "$listing" >&2 || echo "  (none)" >&2
  exit 1
fi
