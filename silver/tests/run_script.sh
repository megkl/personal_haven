#!/usr/bin/env bash
# Runs the Dart test suite and emits flutter test JSON reporter output.
set -euo pipefail
cd /app
flutter test --reporter json --no-pub 2>&1 || true
