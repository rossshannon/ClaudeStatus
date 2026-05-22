#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="ClaudeStatus"
CONFIGURATION="release"
INSTALL=0
RUN_TESTS=1

for arg in "$@"; do
  case "$arg" in
    --install)
      INSTALL=1
      ;;
    --skip-tests)
      RUN_TESTS=0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

cd "$ROOT_DIR"

if [[ "$RUN_TESTS" -eq 1 ]]; then
  swift test
fi

swift build -c "$CONFIGURATION" --product "$APP_NAME"

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"

cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

echo "Built $APP_DIR"

if [[ "$INSTALL" -eq 1 ]]; then
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  rm -rf "/Applications/$APP_NAME.app"
  cp -R "$APP_DIR" /Applications/
  open "/Applications/$APP_NAME.app"
  echo "Installed and launched /Applications/$APP_NAME.app"
fi
