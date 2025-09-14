#!/usr/bin/env bash
set -euo pipefail

PLASMOID_ID="org.mooheda.globalplayer"
PLASMOID_SRC="$(dirname "$0")/${PLASMOID_ID}"
PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"

DAEMON_SRC="$(dirname "$0")/globalplayer-daemon"
DAEMON_DST="${HOME}/globalplayer-daemon"

echo "[+] Installing dependencies (you may need sudo):"
echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine"
echo "    Arch:          sudo pacman -S mpv qt5-tools python-dbus python-gobject python-requests python-pyqt5-webengine"
echo "    Fedora:        sudo dnf install mpv qt5-qttools python3-dbus python3-gobject python3-requests python3-qt5-webengine"

echo "[+] Installing plasmoid to ${PLASMOID_DST}"
mkdir -p "${PLASMOID_DST}"

# Copy the entire plasmoid directory structure
if [ -d "${PLASMOID_SRC}" ]; then
    rsync -a --delete "${PLASMOID_SRC}/" "${PLASMOID_DST}/"
else
    echo "Error: Plasmoid source directory ${PLASMOID_SRC} not found!"
    exit 1
fi

# Update the main.qml with the latest version if we have a standalone copy
if [ -f "$(dirname "$0")/main.qml" ]; then
    echo "[+] Updating main.qml with latest version"
    cp "$(dirname "$0")/main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
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
if command -v kquitapp6 >/dev/null 2>&1; then
  kquitapp6 plasmashell || true
  (sleep 2; kstart6 plasmashell >/dev/null 2>&1) &
elif command -v kquitapp5 >/dev/null 2>&1; then
  kquitapp5 plasmashell || true
  (sleep 2; kstart5 plasmashell >/dev/null 2>&1) &
else
  echo "    Manual restart: killall plasmashell && nohup plasmashell >/dev/null 2>&1 &"
fi

echo "[+] Done. The widget should now appear without hover tooltips."
echo "    Add widget: Right-click panel → Add Widget → Search 'Global Player'"