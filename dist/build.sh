#!/bin/bash
set -e

# Build a universal macOS .app bundle for stayup.
# Usage: ./dist/build.sh [VERSION]

VERSION="${1:-1.0.0}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="stayup"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
BINARY_NAME="$APP_NAME"

echo "Building $APP_NAME v$VERSION..."

rm -rf "$APP_BUNDLE"
rm -rf "$PROJECT_ROOT/.build"

cd "$PROJECT_ROOT"
echo "Building universal binary (arm64 + x86_64)..."
if swift build -c release --arch arm64 --arch x86_64 2>/dev/null; then
    echo "Multi-arch build successful"
    BINARY_PATH="$PROJECT_ROOT/.build/apple/Products/Release/$BINARY_NAME"
else
    echo "Multi-arch build failed, falling back to lipo..."
    swift build -c release --triple x86_64-apple-macosx
    swift build -c release --triple arm64-apple-macosx
    mkdir -p "$PROJECT_ROOT/.build/universal"
    lipo -create -output "$PROJECT_ROOT/.build/universal/$BINARY_NAME" \
        "$PROJECT_ROOT/.build/x86_64-apple-macosx/release/$BINARY_NAME" \
        "$PROJECT_ROOT/.build/arm64-apple-macosx/release/$BINARY_NAME"
    BINARY_PATH="$PROJECT_ROOT/.build/universal/$BINARY_NAME"
fi

echo "Verifying binary..."
lipo -info "$BINARY_PATH"

echo "Creating app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY_PATH" "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
sed "s/<string>1.0.0<\/string>/<string>$VERSION<\/string>/g" \
    "$SCRIPT_DIR/Info.plist" > "$APP_BUNDLE/Contents/Info.plist"

# App icon
if [ -f "$SCRIPT_DIR/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "Warning: AppIcon.icns not found — run: swift dist/make-icon.swift dist && (regenerate .icns)"
fi

echo ""
echo "Build complete: $APP_BUNDLE"
lipo -info "$APP_BUNDLE/Contents/MacOS/$BINARY_NAME"
echo "To launch: open $APP_BUNDLE"
