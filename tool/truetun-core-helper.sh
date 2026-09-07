#!/usr/bin/env bash
set -euo pipefail

readonly core="/usr/local/libexec/truetun/sing-box"

if [[ $# -ne 1 ]]; then
  echo "Usage: truetun-core-helper check|run" >&2
  exit 64
fi

case "$1" in
  check|run)
    # The configuration arrives on stdin, so the unprivileged application
    # cannot replace a pathname after sudo has authorised this helper.
    exec "$core" "$1" -c /dev/stdin
    ;;
  *)
    echo "Unsupported TrueTun core command: $1" >&2
    exit 64
    ;;
esac
