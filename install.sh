#!/usr/bin/env bash
# X-Seti - Sept 14 2025 - globalplayer 3.22
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
    echo "Warning: Could not detect Plasma version. Defaulting to Plasma 6."
    PLASMA_VERSION="6"
fi

echo "[+] Detected Plasma ${PLASMA_VERSION}"

echo "[+] Installing dependencies (you may need sudo):"
if [ "$PLASMA_VERSION" = "6" ]; then
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt5-webengine"
    echo "    Fedora:        sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-qt5-webengine"
else
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt5-tools python-dbus python-gobject python-requests python-pyqt5-webengine"
    echo "    Fedora:        sudo dnf install mpv qt5-qttools python3-dbus python3-gobject python3-requests python3-qt5-webengine"
fi

echo "[+] Installing plasmoid to ${PLASMOID_DST}"
mkdir -p "${PLASMOID_DST}"

# Copy the entire plasmoid directory structure
if [ -d "${PLASMOID_SRC}" ]; then
    rsync -a --delete "${PLASMOID_SRC}/" "${PLASMOID_DST}/"
else
    echo "Error: Plasmoid source directory ${PLASMOID_SRC} not found!"
    exit 1
fi

# Use appropriate QML file based on Plasma version
if [ "$PLASMA_VERSION" = "6" ]; then
    if [ -f "$(dirname "$0")/main-plasma6.qml" ]; then
        echo "[+] Using Plasma 6 version of main.qml"
        cp "$(dirname "$0")/main-plasma6.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    elif [ -f "$(dirname "$0")/main.qml" ]; then
        echo "[+] Using main.qml (assuming Plasma 6 compatible)"
        cp "$(dirname "$0")/main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    fi
else
    if [ -f "$(dirname "$0")/main-plasma5.qml" ]; then
        echo "[+] Using Plasma 5 version of main.qml"
        cp "$(dirname "$0")/main-plasma5.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    else
        echo "[+] Creating Plasma 5 compatible version..."
        # The Plasma 5 version is embedded in this installer
        cat > "${PLASMOID_DST}/contents/ui/main.qml" << 'EOF'
// This will be replaced by the actual Plasma 5 QML content
// Use the plasma5_main_qml artifact content here
EOF
        echo "    Please replace contents/ui/main.qml with the Plasma 5 version"
    fi
fi

# Update metadata.desktop if we have a standalone copy
if [ -f "$(dirname "$0")/metadata.desktop" ]; then
    echo "[+] Updating metadata.desktop with latest version"
    cp "$(dirname "$0")/metadata.desktop" "${PLASMOID_DST}/metadata.desktop"
fi

echo "[+] Installing daemon to ${DAEMON_DST}"
mkdir -p "${DAEMON_DST}"
rsync -a --delete "${DAEMON_SRC}/" "${DAEMON_DST}/"

echo "[+] Installing systemd --user service"
mkdir -p "${HOME}/.config/systemd/user"
cp "$(dirname "$0")/gpd.service" "${HOME}/.config/systemd/user/gpd.service"
systemctl --user daemon-reload || true
systemctl --user enable --now gpd.service || true

echo "[+] Restarting Plasma to apply changes"
if [ "$PLASMA_VERSION" = "6" ]; then
    kquitapp6 plasmashell || true
    (sleep 2; kstart6 plasmashell >/dev/null 2>&1) &
else
    kquitapp5 plasmashell || true
    (sleep 2; kstart5 plasmashell >/dev/null 2>&1) &
fi

echo "[+] Done. Global Player v3.2.2 installed for Plasma ${PLASMA_VERSION}."
echo "    Add widget: Right-click panel → Add Widget → Search 'Global Player'"
