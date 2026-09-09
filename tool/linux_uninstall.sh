#!/usr/bin/env bash
set -euo pipefail

login_user="$(id -un)"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"

rm -f "$config_home/autostart/truetun.desktop"
rm -f "$data_home/applications/truetun.desktop"

if [[ -d /usr/local/libexec/truetun || -e "/etc/sudoers.d/truetun-${login_user}" ]]; then
  if ! command -v pkexec >/dev/null 2>&1; then
    echo "pkexec is required to remove the privileged TrueTun core helper." >&2
    exit 1
  fi
  pkexec /bin/bash -c \
    'set -eu
     user_name="$1"
     rm -rf /usr/local/libexec/truetun
     rm -f "/etc/sudoers.d/truetun-${user_name}"' \
    truetun-uninstall "$login_user"
fi

printf 'Removed TrueTun desktop/autostart entries and privileged helper.\n'
printf 'The unpacked application directory can now be deleted.\n'
