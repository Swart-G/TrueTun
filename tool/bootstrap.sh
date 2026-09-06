#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

flutter pub get
dart run build_runner build
dart format lib test
flutter analyze
flutter test

echo "TrueTun dependencies, generated sources, and checks are ready."
