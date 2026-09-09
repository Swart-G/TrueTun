#!/usr/bin/env bash
set -euo pipefail

bundle_dir="$(cd "$(dirname "$0")" && pwd)"
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
applications_dir="$data_home/applications"
desktop_file="$applications_dir/truetun.desktop"
icon="$bundle_dir/data/flutter_assets/assets/tray_icon.png"

mkdir -p "$applications_dir"
cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=TrueTun
Comment=Android and Linux proxy client
Exec="$bundle_dir/truetun"
Icon=$icon
Terminal=false
Categories=Network;Utility;
StartupNotify=true
EOF
chmod 0644 "$desktop_file"

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$applications_dir" >/dev/null 2>&1 || true
fi

printf 'Installed desktop entry: %s\n' "$desktop_file"
printf 'You can now launch TrueTun from the application menu.\n'
