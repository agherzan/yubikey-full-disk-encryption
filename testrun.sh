#!/usr/bin/env bash
CONFFILE="/etc/ykfde.conf"
[ -e "src/hooks/ykfde" ] || {
  echo "ERROR: src/hooks/ykfde not found."
  exit 1
}
. "$CONFFILE"
[ -z "$YKFDE_LUKS_NAME" ] && {
  echo "ERROR: YKFDE_LUKS_NAME not set (check '$CONFFILE')."
  exit 1
}
[ -e "/dev/mapper/$YKFDE_LUKS_NAME" ] && cryptsetup luksClose "$YKFDE_LUKS_NAME"
. src/hooks/ykfde
run_hook
