#!/usr/bin/env bash
set -euo pipefail

PLASMOID_ID="org.mooheda.globalplayer.germany"

echo "[+] Deinstalliere Global Player Deutschland..."

systemctl --user disable --now gpd-germany.service || true
rm -f "${HOME}/.config/systemd/user/gpd-germany.service"
systemctl --user daemon-reload || true

rm -rf "${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"
rm -rf "${HOME}/globalplayer-daemon-germany"
rm -rf "${HOME}/.config/globalplayer-germany"
rm -rf "${HOME}/.cache/globalplayer-germany"

if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
  systemctl --user restart plasma-plasmashell.service
else
  pkill plasmashell 2>/dev/null || true
  sleep 2
  nohup plasmashell > /dev/null 2>&1 &
fi

echo "[✓] Global Player Deutschland vollständig entfernt."
