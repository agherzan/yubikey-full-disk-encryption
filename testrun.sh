#!/bin/bash

set -euo pipefail

# set default values:
YKFDE_CONFIG_FILE="/etc/ykfde.conf"
YKFDE_CHALLENGE=""
YKFDE_CHALLENGE_PASSWORD_NEEDED=""
YKFDE_CHALLENGE_SLOT=""

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Please run this script as 'root'."
  exit 1
fi

# shellcheck source=src/ykfde.conf
. "$YKFDE_CONFIG_FILE"
[ "$YKFDE_CHALLENGE_PASSWORD_NEEDED" ] && YKFDE_CHALLENGE=""

if [ -z "$YKFDE_CHALLENGE" ] && [ -z "$YKFDE_CHALLENGE_PASSWORD_NEEDED" ]; then
  printf '%s\n' "ERROR: No ykfde mode enabled. Please enable 'Automatic mode with stored challenge (1FA)' or 'Manual mode with secret challenge (2FA)' in '$YKFDE_CONFIG_FILE'."
  exit 1
elif [ "$YKFDE_CHALLENGE" ]; then
  echo "INFO: 'Automatic mode with stored challenge (1FA)' is enabled."
elif [ "$YKFDE_CHALLENGE_PASSWORD_NEEDED" ]; then
  echo "INFO: 'Manual mode with secret challenge (2FA)' is enabled."
fi

if [ -z "$YKFDE_CHALLENGE_SLOT" ]; then
  echo "WARNING: YubiKey slot configured for 'HMAC-SHA1 Challenge-Response' mode is not selected. Falling back to slot '2'."
fi

umask 0077
YKFDE_TMPFILE=""
YKFDE_TMPFILE="$(mktemp /dev/shm/ykfde-XXXXXX)"
truncate -s 20M "$YKFDE_TMPFILE"

cleanup() {
  rm -f "$YKFDE_TMPFILE"
  rm -rf initramfs
}
trap cleanup EXIT

echo "INFO: Testing 'ykfde-format' script."
DBG=1 bash "$(pwd)/src/ykfde-format" "$YKFDE_TMPFILE"
echo "Test 'ykfde-format' script successfully passed."

echo "INFO: Testing 'ykfde-enroll' script."
printf '%s\n' "test" | cryptsetup luksFormat "$YKFDE_TMPFILE"
echo "INFO: Old LUKS passphrase is 'test'."
bash "$(pwd)/src/ykfde-enroll" -d "$YKFDE_TMPFILE" -s 7 -v
echo "Test 'ykfde-enroll' script successfully passed."

echo "INFO: Testing 'ykfde-open' script."
bash "$(pwd)/src/ykfde-open" -d "$YKFDE_TMPFILE" -n ykfde-test -v
cryptsetup close ykfde-test
echo "Test 'ykfde-open' script successfully passed."

echo "INFO: Testing initramfs..."
mkdir -p "$(pwd)/initramfs"
mkinitcpio -d "$(pwd)/initramfs"
status=1
status=$(chroot "$(pwd)/initramfs" /bin/sh -c "export CRYPTOGRAPHY_OPENSSL_NO_LEGACY=1; ykman otp info; exit 0" 2>&1 | awk '
  { 
    if ($0 ~ /No YubiKey detected/) {
    print "0";
    exit 0;
    }
  }' 
)
if [[ "$status" == 0 ]]
then
  echo "All tests successfully passed."
else
  echo "The image didnot pass the test, please file a bug report to: https://github.com/agherzan/yubikey-full-disk-encryption/issues"
  exit 127
fi
exit 0
