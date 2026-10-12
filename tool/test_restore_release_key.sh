#!/usr/bin/env bash
# Tests tool/restore_release_key.sh against a throwaway keystore: the good case,
# harmless copy artifacts (line wraps, CRLF), and the ways a pasted secret or a
# wrong password typically breaks. Needs keytool (any JDK).
set -uo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
script="$here/restore_release_key.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

keytool -genkeypair -keystore "$work/t.jks" -storepass testpass123 \
  -keypass testpass123 -alias trackly -keyalg RSA -keysize 2048 -validity 2 \
  -dname "CN=Test Only" >/dev/null 2>&1 || { echo "could not create the test keystore"; exit 1; }
good="$(base64 -w0 "$work/t.jks")"

failures=0
# expect <name> <exit 0|1> <base64> <alias> <store password> <key password>
expect() {
  local name="$1" want="$2" b64="$3" alias="$4" store="$5" key="$6" got
  KEYSTORE_BASE64="$b64" ANDROID_KEYSTORE_PASSWORD="$store" \
    ANDROID_KEY_ALIAS="$alias" ANDROID_KEY_PASSWORD="$key" \
    bash "$script" "$work/out.jks" >"$work/log" 2>&1
  got=$?
  rm -f "$work/out.jks"
  if [ "$got" -eq "$want" ]; then
    echo "ok    $name"
  else
    echo "FAIL  $name (exit $got, wanted $want)"; sed 's/^/        /' "$work/log"
    failures=$((failures + 1))
  fi
}

expect "valid key"                       0 "$good" trackly testpass123 testpass123
expect "line-wrapped value with CRLF"    0 "$(base64 "$work/t.jks" | sed 's/$/\r/')" trackly testpass123 testpass123
expect "trailing prompt character"       1 "${good}%" trackly testpass123 testpass123
expect "value in quotes"                 1 "\"$good\"" trackly testpass123 testpass123
expect "value cut off"                   1 "${good:0:-3}" trackly testpass123 testpass123
expect "empty value"                     1 "" trackly testpass123 testpass123
expect "wrong store password"            1 "$good" trackly nope nope
expect "wrong alias"                     1 "$good" nosuch testpass123 testpass123
expect "key password differs (PKCS12)"   1 "$good" trackly testpass123 different999

# No secret may be printed, even for a malformed value.
KEYSTORE_BASE64="${good}%" ANDROID_KEYSTORE_PASSWORD=testpass123 ANDROID_KEY_ALIAS=trackly \
  ANDROID_KEY_PASSWORD=testpass123 bash "$script" "$work/out.jks" >"$work/log" 2>&1
if grep -q "${good:0:40}" "$work/log" || grep -q testpass123 "$work/log"; then
  echo "FAIL  the script printed a secret"; failures=$((failures + 1))
else
  echo "ok    prints no secret"
fi

[ "$failures" -eq 0 ] && echo "all passed" || { echo "$failures failed"; exit 1; }
