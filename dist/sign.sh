#!/bin/bash
set -e

# Code-sign the stayup.app bundle with a Developer ID Application certificate.
# Usage: ./dist/sign.sh
# Requires: export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/stayup.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found. Run ./dist/build.sh first."
    exit 1
fi
if [ -z "$SIGNING_IDENTITY" ]; then
    echo "Error: SIGNING_IDENTITY not set."
    echo 'export SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"'
    exit 1
fi

echo "Signing $APP_BUNDLE with hardened runtime..."
codesign --force --options runtime --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$APP_BUNDLE"

echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
echo "Signed."
