#!/bin/bash
set -e

APP_NAME="Insomnia"
BUILD_DIR=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"

echo "Building $APP_NAME (release)..."
swift build -c release

echo "Creating .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS_DIR/MacOS"
mkdir -p "$CONTENTS_DIR/Resources"

cp "$BUILD_DIR/$APP_NAME" "$CONTENTS_DIR/MacOS/$APP_NAME"
cp "Sources/$APP_NAME/Info.plist" "$CONTENTS_DIR/Info.plist"

echo "✅ $APP_BUNDLE created!"
echo "open $APP_BUNDLE"
