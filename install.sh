#!/usr/bin/env bash
# X-Seti - Sept 15 2025 - GlobalPlayer 3.2.2 - Fixed Plasma 5 Support
set -euo pipefail

PLASMOID_ID="org.mooheda.globalplayer"
PLASMOID_SRC="$(dirname "$0")/${PLASMOID_ID}"
PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"

DAEMON_SRC="$(dirname "$0")/globalplayer-daemon"
DAEMON_DST="${HOME}/globalplayer-daemon"

# Detect Plasma version
PLASMA_VERSION=""
if command -v kquitapp6 >/dev/null 2>&1; then
    PLASMA_VERSION="6"
elif command -v kquitapp5 >/dev/null 2>&1; then
    PLASMA_VERSION="5"
else
    echo "Warning: Could not detect Plasma version. Checking for plasmashell..."
    if command -v plasmashell >/dev/null 2>&1; then
        # Try to determine version from plasmashell
        PLASMA_VERSION="5"  # Default to 5 if uncertain
    else
        echo "Error: No Plasma installation detected!"
        exit 1
    fi
fi

echo "[+] Detected Plasma ${PLASMA_VERSION}"

echo "[+] Installing dependencies (you may need sudo):"
if [ "$PLASMA_VERSION" = "6" ]; then
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt6.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt6-webengine"
    echo "    Fedora:        sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-pyqt6-webengine"
else
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt5-tools python-dbus python-gobject python-requests python-pyqt5-webengine"  
    echo "    Fedora:        sudo dnf install mpv qt5-qttools python3-dbus python3-gobject python3-requests python3-pyqt5-webengine"
fi

echo "[+] Installing plasmoid to ${PLASMOID_DST}"
mkdir -p "${PLASMOID_DST}"

# Copy the entire plasmoid directory structure
#if [ -d "${PLASMOID_SRC}" ]; then
#    rsync -a --delete "${PLASMOID_SRC}/" "${PLASMOID_DST}/"
#else
#    echo "Error: Plasmoid source directory ${PLASMOID_SRC} not found!"
#    echo "Creating directory structure and files..."
#    mkdir -p "${PLASMOID_DST}/contents/ui"
#fi

# Use appropriate QML file based on Plasma version
if [ "$PLASMA_VERSION" = "6" ]; then
    if [ -f "$(dirname "$0")/main-plasma6.qml" ]; then
        echo "[+] Using Plasma 6 version of main.qml"
        cp "$(dirname "$0")/main-plasma6.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    fi
fi

if [ "$PLASMA_VERSION" = "5" ]; then
    if [ -f "$(dirname "$0")/main-plasma5.qml" ]; then
        echo "[+] Using Plasma 5 version of main.qml"
        cp "$(dirname "$0")/main-plasma5.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    fi
fi

echo "[+] Installing systemd --user service"
mkdir -p "${HOME}/.config/systemd/user"
cp "$(dirname "$0")/gpd.service" "${HOME}/.config/systemd/user/gpd.service"
systemctl --user daemon-reload || true
systemctl --user enable --now gpd.service || true

echo "[+] Restarting Plasma (optional, if the widget doesn't refresh)"
if command -v kquitapp6 >/dev/null 2>&1; then
  kquitapp6 plasmashell || true
  (sleep 1; kstart6 plasmashell)&
elif command -v kquitapp5 >/dev/null 2>&1; then
  kquitapp5 plasmashell || true
  (sleep 1; kstart5 plasmashell)&
fi

echo "[+] Done. Add/refresh the widget: 'Global Player v3.2'"

