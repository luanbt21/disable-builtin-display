#!/bin/sh
# Build, install the binary, and (re)load the launch agent that keeps the built-in display off.
# Override the install location with PREFIX (default: ~/.local).
set -eu

cd "$(dirname "$0")/.."

LABEL=com.local.builtin-display
PREFIX="${PREFIX:-$HOME/.local}"
BINARY="$PREFIX/bin/builtin-display"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/builtin-display.log"
DOMAIN="gui/$(id -u)"

swift build -c release

# Stop the running agent first so the binary isn't replaced underneath it.
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true

mkdir -p "$PREFIX/bin" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
install -m 755 .build/release/builtin-display "$BINARY"

sed -e "s|__BINARY__|$BINARY|g" -e "s|__LOG__|$LOG|g" \
    "launchd/$LABEL.plist.template" > "$PLIST"
plutil -lint "$PLIST" >/dev/null

launchctl bootstrap "$DOMAIN" "$PLIST"

echo "installed $BINARY"
echo "launch agent $LABEL loaded (log: $LOG)"
