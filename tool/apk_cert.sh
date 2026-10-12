#!/usr/bin/env bash
# Prints who signed an APK: the certificate subject and SHA-256 fingerprint.
# Needs the Android SDK build-tools (ANDROID_HOME), as on the CI runners.
set -euo pipefail

apk="${1:?usage: tool/apk_cert.sh <apk>}"
sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:?set ANDROID_HOME}}"
apksigner="$(ls -d "$sdk"/build-tools/*/apksigner | sort -V | tail -1)"

"$apksigner" verify --print-certs "$apk" \
  | grep -E 'Signer #1 certificate (DN|SHA-256)'
