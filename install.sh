#!/usr/bin/env bash
# Simple Global Player installer - just copy QML and restart Plasma
set -euo pipefail

PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/org.mooheda.globalplayer"

echo "=== Simple Global Player Installer ==="

# Detect Plasma version
if command -v kquitapp6 >/dev/null 2>&1; then
    PLASMA_VERSION="6"
elif command -v kquitapp5 >/dev/null 2>&1; then
    PLASMA_VERSION="5"
else
    PLASMA_VERSION="5"  # Default to 5
fi

echo "[+] Detected Plasma ${PLASMA_VERSION}"

# Create directory structure
mkdir -p "${PLASMOID_DST}/contents/ui"

# Copy the right QML file
if [ "$PLASMA_VERSION" = "6" ]; then
    echo "[+] Copying plasma6_main_qml → main.qml"
    if [ -f "plasma6_main_qml" ]; then
        cp "plasma6_main_qml" "${PLASMOID_DST}/contents/ui/main.qml"
        echo "    ✓ Copied $(wc -l < plasma6_main_qml) lines"
    else
        echo "    ✗ plasma6_main_qml not found!"
        exit 1
    fi
else
    echo "[+] Copying plasma5_main_qml → main.qml"
    if [ -f "plasma5_main_qml" ]; then
        cp "plasma5_main_qml" "${PLASMOID_DST}/contents/ui/main.qml"
        echo "    ✓ Copied $(wc -l < plasma5_main_qml) lines"
    else
        echo "    ✗ plasma5_main_qml not found!"
        exit 1
    fi
fi

# Copy metadata
if [ "$PLASMA_VERSION" = "6" ]; then
    if [ -f "org.mooheda.globalplayer/v6/metadata.json" ]; then
        echo "[+] Copying v6 metadata.json"
        cp "org.mooheda.globalplayer/v6/metadata.json" "${PLASMOID_DST}/metadata.json"
    elif [ -f "org.mooheda.globalplayer/v6/metadata.desktop" ]; then
        echo "[+] Copying v6 metadata.desktop"
        cp "org.mooheda.globalplayer/v6/metadata.desktop" "${PLASMOID_DST}/metadata.desktop"
    fi
else
    if [ -f "org.mooheda.globalplayer/v5/metadata.desktop" ]; then
        echo "[+] Copying v5 metadata.desktop"
        cp "org.mooheda.globalplayer/v5/metadata.desktop" "${PLASMOID_DST}/metadata.desktop"
    fi
fi

# Clear Plasma cache
echo "[+] Clearing Plasma cache"
rm -rf ~/.cache/plasma* ~/.cache/plasmashell ~/.cache/krunner 2>/dev/null || true

# Restart Plasma
echo "[+] Restarting Plasma"
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
    systemctl --user restart plasma-plasmashell.service
elif command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
else
    pkill plasmashell 2>/dev/null || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
fi

echo ""
echo "✅ Simple install complete!"
echo "📁 Installed to: ${PLASMOID_DST}"
echo "🔧 Plasma ${PLASMA_VERSION} cache cleared and restarted"
echo ""
echo "📋 Next steps:"
echo "   1. Add widget: Right-click panel → Add Widgets → Search 'Global Player'"
echo "   2. Check console: journalctl --user -f | grep -i 'global'"