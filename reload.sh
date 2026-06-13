#!/usr/bin/env bash
# X-Seti - Jun 2026 - Global Player - Dev reload script
# Usage: ./reload.sh [64|66]  (default: 64)

PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/org.mooheda.globalplayer/contents/ui/main.qml"
DIR="$(dirname "$0")"
VER="${1:-64}"

case "$VER" in
    66) SRC="$DIR/plasma6_6_main.qml" ;;
    *)  SRC="$DIR/plasma6_4_main.qml" ;;
esac

if [ ! -f "$SRC" ]; then
    echo "ERROR: $SRC not found"
    exit 1
fi

cp -f "$SRC" "$PLASMOID_DST" && echo "Deployed $SRC -> $PLASMOID_DST"

echo "Restarting Plasma shell..."
kquitapp6 plasmashell 2>/dev/null || kquitapp5 plasmashell 2>/dev/null
sleep 1
kstart6 plasmashell 2>/dev/null || kstart5 plasmashell 2>/dev/null &

echo "Done."
