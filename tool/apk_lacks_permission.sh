#!/usr/bin/env bash
# Fails if an APK asks for any of the given Android permissions, e.g.
#   tool/apk_lacks_permission.sh app-release.apk \
#     com.google.android.gms.permission.AD_ID
#
# Libraries add permissions to the merged manifest without asking: Firebase
# Analytics adds the advertising ID ones. Trackly shows no ads, says so in its
# privacy policy and answers "no" to Google Play's advertising ID question, so
# the built APK must not request them.
# Needs the Android SDK build-tools (ANDROID_HOME), as on the CI runners.
set -euo pipefail

apk="${1:?usage: tool/apk_lacks_permission.sh <apk> <permission>...}"
shift
if [ "$#" -eq 0 ]; then
  echo "apk_lacks_permission: name at least one permission" >&2
  exit 1
fi
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$sdk" ]; then
  echo "apk_lacks_permission: set ANDROID_HOME to the Android SDK" >&2
  exit 1
fi

aapt2="$(ls -d "$sdk"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"
if [ -z "$aapt2" ]; then
  echo "apk_lacks_permission: no aapt2 under $sdk/build-tools" >&2
  exit 1
fi

listing="$(mktemp)"
trap 'rm -f "$listing"' EXIT
if ! "$aapt2" dump permissions "$apk" > "$listing" 2>&1; then
  echo "apk_lacks_permission: aapt2 could not read $apk:" >&2
  cat "$listing" >&2
  exit 1
fi
# A listing with no permissions at all would pass every check below, so make
# sure the dump really lists this app's permissions first.
if ! grep -q "uses-permission" "$listing"; then
  echo "apk_lacks_permission: aapt2 listed no permissions for $apk:" >&2
  cat "$listing" >&2
  exit 1
fi

found=0
for permission in "$@"; do
  if grep -F "$permission" "$listing" > /dev/null; then
    echo "::error::The APK requests $permission, which Trackly must not. Check the tools:node=\"remove\" lines in android/app/src/main/AndroidManifest.xml." >&2
    found=1
  else
    echo "apk_lacks_permission: $permission is not requested"
  fi
done
exit "$found"
