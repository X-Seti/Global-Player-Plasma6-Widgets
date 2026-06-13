#!/usr/bin/env bash
# X-Seti - Jun 2026 - Global Player - Dev reload script
# Copies plasma6_4_main.qml to install location and restarts Plasma shell

PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/org.mooheda.globalplayer/contents/ui/main.qml"
SRC="$(dirname "$0")/plasma6_4_main.qml"

if [ ! -f "$SRC" ]; then
    echo "ERROR: $SRC not found"
    exit 1
fi

cp -f "$SRC" "$PLASMOID_DST" && echo "Copied to $PLASMOID_DST"

echo "Restarting Plasma shell..."
kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null
sleep 1
kstart6 plasmashell 2>/dev/null || kstart5 plasmashell 2>/dev/null &

echo "Done."
