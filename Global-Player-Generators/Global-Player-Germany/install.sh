#!/usr/bin/env bash
set -euo pipefail

PLASMOID_ID="org.mooheda.globalplayer.germany"
PLASMOID_SRC="$(dirname "$0")/${PLASMOID_ID}"
PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"

DAEMON_SRC="$(dirname "$0")/globalplayer-daemon"
DAEMON_DST="${HOME}/globalplayer-daemon-germany"

echo "[+] Installing Global Player Deutschland für Plasma 6..."
echo ""
echo "🇩🇪 Deutsche Radiosender:"
echo "   • Öffentlich-rechtlich: 1LIVE, WDR 2, Bayern 3, SWR3, NDR 2, HR3"
echo "   • Jugendwellen: MDR Jump, Radio Fritz, DLF Nova"
echo "   • Privat: Antenne Bayern, Radio Hamburg, BigFM, Energy Berlin"
echo "   • Spezial: Deutschlandfunk, Klassik Radio, Radio Bob, Rock Antenne"
echo ""
echo "[+] Abhängigkeiten benötigt:"
echo "    Arch:          sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests"
echo "    Debian/Ubuntu: sudo apt install mpv qt6-base-dev python3-dbus python3-gi python3-requests"
echo "    Fedora:        sudo dnf install mpv qt6-qtbase-devel python3-dbus python3-gobject python3-requests"

echo "[+] Installing plasmoid to ${PLASMOID_DST}"
mkdir -p "${PLASMOID_DST}"
rsync -a --delete "${PLASMOID_SRC}/" "${PLASMOID_DST}/" || cp -rf "${PLASMOID_SRC}/." "${PLASMOID_DST}/"

echo "[+] Installing daemon to ${DAEMON_DST}"
mkdir -p "${DAEMON_DST}"
rsync -a --delete "${DAEMON_SRC}/" "${DAEMON_DST}/" || cp -rf "${DAEMON_SRC}/." "${DAEMON_DST}/"

echo "[+] Installing systemd --user service"
mkdir -p "${HOME}/.config/systemd/user"
cp "$(dirname "$0")/gpd-germany.service" "${HOME}/.config/systemd/user/gpd-germany.service"
systemctl --user daemon-reload || true
systemctl --user enable --now gpd-germany.service || true

echo "[+] Restarting Plasma..."
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service
elif command -v kquitapp6 >/dev/null 2>&1; then
  kquitapp6 plasmashell 2>/dev/null || true
  sleep 2
  nohup plasmashell > /dev/null 2>&1 &
else
  pkill plasmashell 2>/dev/null || true
  sleep 2
  nohup plasmashell > /dev/null 2>&1 &
fi

echo "[+] Waiting for services to start..."
sleep 5

if systemctl --user is-active gpd-germany.service >/dev/null 2>&1; then
  echo "    ✓ Deutschland Daemon läuft"
else
  echo "    ⚠ Deutschland Daemon läuft möglicherweise nicht. Prüfen: systemctl --user status gpd-germany.service"
fi

echo ""
echo "🇩🇪 Global Player Deutschland erfolgreich installiert!"
echo ""
echo "📱 Widget hinzufügen:"
echo "   Rechtsklick auf Panel → Widgets hinzufügen → 'Global Player Deutschland' suchen"
