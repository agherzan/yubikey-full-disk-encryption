#!/usr/bin/env bash

set -euo pipefail

CONFFILE=""
YKFDE_CHALLENGE=""
YKFDE_CHALLENGE_PASSWORD_NEEDED=""
YKFDE_CHALLENGE_SLOT=""

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Please run this script as 'root'."
  exit 1
fi

CONFFILE="/etc/ykfde.conf"
. "$CONFFILE"
[ "$YKFDE_CHALLENGE_PASSWORD_NEEDED" ] && YKFDE_CHALLENGE=""

if [ -z "$YKFDE_CHALLENGE" ] && [ -z "$YKFDE_CHALLENGE_PASSWORD_NEEDED" ]; then
  printf '%s\n' "ERROR: No ykfde mode enabled. Please enable 'Automatic mode with stored challenge (1FA)' or 'Manual mode with secret challenge (2FA)' in \"$CONFFILE\"."
  exit 1
elif [ "$YKFDE_CHALLENGE" ]; then
  echo "INFO: 'Automatic mode with stored challenge (1FA)' is enabled."
elif [ "$YKFDE_CHALLENGE_PASSWORD_NEEDED" ]; then
  echo "INFO: 'Manual mode with secret challenge (2FA)' is enabled."
fi

if [ -z "$YKFDE_CHALLENGE_SLOT" ]; then
  echo "WARNING: YubiKey slot configured for 'HMAC-SHA1 Challenge-Response' mode is not selected. Falling back to slot \"2\"."
fi

umask 0077
YKFDE_TMPFILE=""
YKFDE_TMPFILE="$(mktemp /dev/shm/ykfde-XXXXXX)"
truncate -s 10M "$YKFDE_TMPFILE"

cleanup() {
  rm -f "$YKFDE_TMPFILE"
}
trap cleanup EXIT

echo "INFO: Testing 'ykfde-format' script."
ykfde-format "$YKFDE_TMPFILE"
echo "Test 'ykfde-format' script succesfully passed."

echo "INFO: Testing 'ykfde-enroll' script."
printf '%s\n' "test" | cryptsetup luksFormat "$YKFDE_TMPFILE"
echo "INFO: Old LUKS passphrase is \"test\"."
ykfde-enroll -d "$YKFDE_TMPFILE" -s 7 -v
echo "Test 'ykfde-enroll' script succesfully passed."

echo "INFO: Testing 'ykfde-open' script."
ykfde-open -d "$YKFDE_TMPFILE" -n ykfde-test -v
cryptsetup close ykfde-test
echo "Test 'ykfde-open' script succesfully passed."

echo "All tests succesfully passed."

exit 0
