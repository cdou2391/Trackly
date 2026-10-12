#!/usr/bin/env bash
# Prints who signed an APK: the certificate subject and SHA-256 fingerprint.
# Needs the Android SDK build-tools (ANDROID_HOME), as on the CI runners.
#
# On any problem it says what happened and exits non-zero, with apksigner's
# full output, so a CI failure explains itself.
set -euo pipefail

apk="${1:?usage: tool/apk_cert.sh <apk>}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [ -z "$sdk" ]; then
  echo "apk_cert: set ANDROID_HOME to the Android SDK" >&2
  exit 1
fi

apksigner="$(ls -d "$sdk"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1 || true)"
if [ -z "$apksigner" ]; then
  echo "apk_cert: no apksigner under $sdk/build-tools" >&2
  exit 1
fi
echo "apk_cert: using $apksigner" >&2

if ! output="$("$apksigner" verify --print-certs "$apk" 2>&1)"; then
  echo "apk_cert: apksigner rejected $apk:" >&2
  echo "$output" >&2
  exit 1
fi

if ! echo "$output" | grep -iE 'certificate (DN|SHA-256)'; then
  echo "apk_cert: apksigner printed no certificate lines. Full output:" >&2
  echo "$output" >&2
  exit 1
fi
