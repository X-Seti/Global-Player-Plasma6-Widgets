#!/usr/bin/env bash
# Quick Plasma reset script
set -euo pipefail

echo "=== Plasma Reset Script ==="

# Clear all caches
echo "[+] Clearing caches..."
rm -rf ~/.cache/plasma* ~/.cache/plasmashell ~/.cache/krunner 2>/dev/null || true
echo "    ✓ Cleared Plasma caches"

# Restart Plasma
echo "[+] Restarting Plasma..."
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
    echo "    → Using systemd service"
    systemctl --user restart plasma-plasmashell.service
elif command -v kquitapp6 >/dev/null 2>&1; then
    echo "    → Using kquitapp6"
    kquitapp6 plasmashell || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
else
    echo "    → Using pkill fallback"
    pkill plasmashell 2>/dev/null || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
fi

echo "✅ Plasma restarted!"
echo "💡 Wait a few seconds for Plasma to fully load"