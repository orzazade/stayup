#!/bin/bash
set -e

# Notarize the stayup.app bundle with Apple, then staple + zip + checksum.
# Usage: ./dist/notarize.sh [VERSION]
#
# Prerequisites:
# - App signed first (./dist/sign.sh)
# - export APPLE_ID='your@email.com'
# - export TEAM_ID='ABCD1234'
# - export APP_SPECIFIC_PASSWORD='xxxx-xxxx-xxxx-xxxx'

VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE="$SCRIPT_DIR/stayup.app"
ZIP_FILE="$SCRIPT_DIR/stayup-$VERSION.zip"
SHA256_FILE="$SCRIPT_DIR/sha256.txt"

[ -d "$APP_BUNDLE" ] || { echo "Error: $APP_BUNDLE not found. Run ./dist/build.sh."; exit 1; }
[ -n "$APPLE_ID" ] || { echo "Error: APPLE_ID not set."; exit 1; }
[ -n "$TEAM_ID" ] || { echo "Error: TEAM_ID not set."; exit 1; }
[ -n "$APP_SPECIFIC_PASSWORD" ] || { echo "Error: APP_SPECIFIC_PASSWORD not set."; exit 1; }

echo "Zipping for notarization..."
rm -f "$ZIP_FILE"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_FILE"

echo "Submitting to Apple notary service..."
xcrun notarytool submit "$ZIP_FILE" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --wait

echo "Stapling ticket..."
xcrun stapler staple "$APP_BUNDLE"

echo "Re-zipping stapled app..."
rm -f "$ZIP_FILE"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_FILE"

echo "Computing checksum..."
shasum -a 256 "$ZIP_FILE" | awk '{print $1}' > "$SHA256_FILE"
echo "Done. sha256: $(cat "$SHA256_FILE")"
echo "Release artifact: $ZIP_FILE"
