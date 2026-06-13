# Global Player v3.3.0 - Plasma 6 Widget - X-Seti - Jun 13 2026

Internet radio player widget for KDE Plasma 6. Streams UK/EU/US radio via a background daemon using mpv and D-Bus.

---

## Quick Install

```bash
git clone https://github.com/X-Seti/Global-Player-Plasma6-Widgets.git
cd Global-Player-Plasma6-Widgets
chmod +x install.sh
./install.sh
```

Choose your Plasma version when prompted:

1. Automatic detection (recommended)
2. Plasma 5.x
3. Plasma 6.0-6.3
4. Plasma 6.4+
5. Plasma 6.6+ (development build)

Then choose a regional station preset.

---

## Development Reload

For testing changes without running the full installer:

```bash
./reload.sh 64   # deploy plasma6_4_main.qml (stable)
./reload.sh 66   # deploy plasma6_6_main.qml (development)
```

---

## Version Management

To update the version number across all files at once:

```bash
./set_version.sh 3.3.1
```

Updates: install.sh, uninstall.sh, metadata.json, metadata.desktop, plasma6_4_main.qml.

---

## Requirements

```bash
# Arch
sudo pacman -S mpv python-dbus python-gobject python-requests

# Debian/Ubuntu
sudo apt install mpv python3-dbus python3-gi python3-requests

# Fedora
sudo dnf install mpv python3-dbus python3-gobject python3-requests
```

---

## Files

```
plasma6_4_main.qml          QML widget - Plasma 6.4+ stable
plasma6_6_main.qml          QML widget - Plasma 6.6 dev sandbox
plasma6_main_qml            QML widget - Plasma 6.0-6.3
plasma5_main_qml            QML widget - Plasma 5.x
install.sh                  Installer
reload.sh                   Fast dev deploy
set_version.sh              Version sync tool
uninstall.sh                Uninstaller
globalplayer-daemon/        Background daemon (mpv + D-Bus)
Global-Player-presets/      Regional station packages
org.mooheda.globalplayer/   Plasma metadata
support/                    Diagnostics and fix history
```

---

## Controls

Panel icon: left-click play/pause, right-click next station, scroll wheel previous/next, middle-click or hold to open widget.

---

## Troubleshooting

Daemon not running:
```bash
systemctl --user restart gpd.service
journalctl --user -u gpd.service -n 50
```

No stations loading:
```bash
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations
```

Widget not appearing after install:
```bash
rm -rf ~/.cache/plasma* ~/.cache/plasmashell
kquitapp6 plasmashell && kstart6 plasmashell
```

Run full diagnostics:
```bash
./support/diagnose.sh
```

---

## TODO

- Artwork display - artworkPath not reliably returned by daemon for all stations
- VU meter - rendering varies by Plasma configuration
- Media player mode - currently stub only
- Favorite button - not wired to backend
- SetPlayDelay - not implemented in daemon
- Auto-detect Plasma 6.6 in installer (currently requires manual selection)

---

## Changelog

See support/FIX_SUMMARY.md

---

## License

GPL v3 - X-Seti (Mooheda)
