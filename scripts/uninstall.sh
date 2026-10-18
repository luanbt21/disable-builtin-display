#!/bin/sh
# Stop and remove the launch agent and binary, and bring the built-in display back first.
set -eu

LABEL=com.local.builtin-display
PREFIX="${PREFIX:-$HOME/.local}"
BINARY="$PREFIX/bin/builtin-display"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true

[ -x "$BINARY" ] && "$BINARY" on || true

rm -f "$PLIST" "$BINARY"
echo "uninstalled $LABEL"
