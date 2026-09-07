#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

readonly flutter_bin="${FLUTTER_BIN:-flutter}"
readonly core_version="1.14.0-extended-2.7.1"
readonly core_archive="sing-box-${core_version}-linux-amd64-glibc.tar.gz"
readonly core_sha256="6319ad33fbd3f2e9ff15fba74fdd99747f1dbea4ce8cc9c91d59fa23a046cdc8"
readonly core_url="https://github.com/shtorm-7/sing-box-extended/releases/download/v${core_version}/${core_archive}"
readonly output_dir="build/linux/x64/debug/bundle"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

curl --fail --location --silent --show-error "$core_url" \
  --output "$temp_dir/$core_archive"
printf '%s  %s\n' "$core_sha256" "$temp_dir/$core_archive" | sha256sum --check
tar -xzf "$temp_dir/$core_archive" -C "$temp_dir"
readonly core_binary="$temp_dir/sing-box-${core_version}-linux-amd64-glibc/sing-box"

"$flutter_bin" pub get
"$flutter_bin" analyze
SING_BOX_BIN="$core_binary" "$flutter_bin" test
"$flutter_bin" build linux --debug
install -m 0755 "$core_binary" "$output_dir/sing-box"
install -m 0755 tool/truetun-core-helper.sh \
  "$output_dir/truetun-core-helper"
mv "$output_dir/truetun" "$output_dir/truetun-bin"
sed 's/@APP_BINARY@/truetun-bin/g' tool/truetun-launcher.sh.in \
  > "$output_dir/truetun"
chmod 0755 "$output_dir/truetun"

printf 'TrueTun Linux test bundle: %s\n' "$output_dir"
"$output_dir/sing-box" version
