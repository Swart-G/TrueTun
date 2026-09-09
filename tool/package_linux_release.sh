#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

readonly flutter_bin="${FLUTTER_BIN:-flutter}"
readonly version="${TRUETUN_VERSION:-0.4.1}"
readonly core_version="1.14.0-lx.35"

case "$(uname -m)" in
  x86_64)
    readonly core_arch="amd64"
    readonly flutter_arch="x64"
    readonly release_arch="x86_64"
    readonly core_sha256="36445e7f6818c652dda529b6ba7e02c3b5ae703328ee294c585c914f45734863"
    ;;
  aarch64|arm64)
    readonly core_arch="arm64"
    readonly flutter_arch="arm64"
    readonly release_arch="aarch64"
    readonly core_sha256="3937ce411b78b14be2cc328ad37287f6a1ef61c50643c628af3209dfa4dfae74"
    ;;
  *)
    echo "Unsupported Linux architecture: $(uname -m)" >&2
    exit 64
    ;;
esac

readonly core_archive="sing-box-${core_version}-linux-${core_arch}.tar.gz"
readonly core_url="https://github.com/Leadaxe/sing-box-lx/releases/download/v${core_version}/${core_archive}"
readonly bundle_dir="build/linux/${flutter_arch}/release/bundle"
readonly dist_dir="dist"
readonly package_name="TrueTun-linux-${release_arch}-v${version}"
readonly package_dir="$dist_dir/$package_name"
readonly archive="$dist_dir/${package_name}.tar.gz"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

mkdir -p "$dist_dir"
rm -rf "$package_dir" "$archive"

curl --fail --location --silent --show-error "$core_url" \
  --output "$temp_dir/$core_archive"
printf '%s  %s\n' "$core_sha256" "$temp_dir/$core_archive" | sha256sum --check
tar -xzf "$temp_dir/$core_archive" -C "$temp_dir"
core_binary="$(find "$temp_dir" -type f -name sing-box -perm -u+x | head -n 1)"
if [[ -z "$core_binary" ]]; then
  echo "Unable to locate sing-box in $core_archive" >&2
  exit 1
fi
readonly core_binary

"$flutter_bin" build linux --release

if [[ ! -x "$bundle_dir/truetun" ]]; then
  echo "Flutter Linux bundle was not created at $bundle_dir" >&2
  exit 1
fi

cp -a "$bundle_dir" "$package_dir"
install -m 0755 "$core_binary" "$package_dir/sing-box"
install -m 0755 tool/truetun-core-helper.sh "$package_dir/truetun-core-helper"
mv "$package_dir/truetun" "$package_dir/truetun-bin"
sed 's/@APP_BINARY@/truetun-bin/g' tool/truetun-launcher.sh.in \
  > "$package_dir/truetun"
chmod 0755 "$package_dir/truetun"
install -m 0755 tool/linux_install_desktop.sh "$package_dir/install-desktop.sh"
install -m 0755 tool/linux_uninstall.sh "$package_dir/uninstall.sh"
install -m 0644 LICENSE "$package_dir/LICENSE"
install -m 0644 THIRD_PARTY_NOTICES.md "$package_dir/THIRD_PARTY_NOTICES.md"

cat > "$package_dir/README-LINUX.txt" <<EOF
TrueTun ${version} for Linux (${release_arch})

Run:
  ./truetun

Optional desktop-menu integration:
  ./install-desktop.sh

Uninstall privileged helper and desktop integration:
  ./uninstall.sh

The first connection/first launch after a core update uses PolicyKit (pkexec)
to install a root-owned sing-box core and a narrow helper under
/usr/local/libexec/truetun. The GUI remains unprivileged. A per-user sudoers
entry allows only the TrueTun helper's check/run commands so reconnects do not
show repeated password prompts.

Runtime requirements typically provided by desktop Linux distributions:
GTK 3, libstdc++, libsecret, PolicyKit/pkexec and sudo/visudo.

Embedded core:
  sing-box-lx ${core_version}
  ${core_url}
  SHA-256 ${core_sha256}

See THIRD_PARTY_NOTICES.md for licensing information.
EOF

"$package_dir/sing-box" version

tar -C "$dist_dir" -czf "$archive" "$package_name"
sha256sum "$archive" > "$archive.sha256"

printf 'Created Linux release bundle: %s\n' "$archive"
