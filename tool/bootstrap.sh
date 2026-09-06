#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

flutter create --platforms=android,linux --project-name truetun .
flutter pub get
dart format lib test
flutter analyze
flutter test

echo "TrueTun Android/Linux Flutter shells are ready."
