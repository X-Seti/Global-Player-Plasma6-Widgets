# Global Player Plasma 6.4 Widget - X-Seti - Oct 25 2025

## Quick Start Installation

```bash
# 1. Clone or download the repository
cd Global-Player-Plasma6-Widgets

# 2. Run the installer
chmod +x install.sh
./install.sh

# 3. Select Plasma 6.4 (option 4) and your region (e.g., UK = option 1)

# 4. Wait for Plasma to restart (10-15 seconds)

# 5. Add widget: Right-click panel → Add Widgets → "Global Player"
```

## ⚠️ Important: First-Time Setup

After adding the widget, **if you see "No stations available"**:

1. **Click the "Retry" button** in the widget's error banner, OR
2. **Open the widget** and click the refresh/reload icon

The stations will then load properly. This is a one-time issue on first launch.

## Verification

Check everything is working:

```bash
# Daemon should be running
systemctl --user status gpd.service

# Should return 25 stations (for UK preset)
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations
```

## What's New in This Version

### ✅ Plasma 6.4 Support
- Auto-detects Plasma version (5.x, 6.0-6.3, 6.4+)
- Uses SVG icons instead of Unicode symbols
- Improved compatibility with latest KDE

### ✅ Better Error Handling
- Connection retry logic (10 attempts on startup)
- Visual status indicators (red/green borders)
- Error messages shown in UI
- "Retry" button for manual reconnection

### ✅ Regional Station Presets
Choose from 6 regional station packages:
- 🇬🇧 **UK** - 25 stations (Heart, Capital, Classic FM, LBC, etc.)
- 🇺🇸 **USA** - 15+ stations (iHeartRadio, NPR, KEXP, etc.)
- 🇨🇦 **Canada** - 15 stations (Jack FM, Virgin Radio, CBC, etc.)
- 🇩🇪 **Germany** - 18 stations (1LIVE, Bayern 3, SWR3, etc.)
- 🇪🇸 **Spain** - 18 stations (Cadena SER, Los 40, Europa FM, etc.)
- 🇮🇹 **Italy** - 20 stations (RTL 102.5, Radio Deejay, RDS, etc.)

## System Requirements

### Plasma 6.4+
```bash
# Arch Linux
sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt6-webengine

# Ubuntu/Debian
sudo apt install mpv qdbus-qt6 python3-dbus python3-gi python3-requests python3-pyqt6.qtwebengine

# Fedora
sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-pyqt6-webengine
```

### Plasma 5.x
```bash
# Arch Linux
sudo pacman -S mpv qt5-tools python-dbus python-gobject python-requests python-pyqt5-webengine

# Ubuntu/Debian  
sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine

# Fedora
sudo dnf install mpv qt5-qttools python3-dbus python3-gobject python3-requests python3-pyqt5-webengine
```

## Troubleshooting

### "Daemon not connected"
```bash
# Restart the daemon
systemctl --user restart gpd.service

# Check status
systemctl --user status gpd.service

# View logs
journalctl --user -u gpd.service -n 50
```

### "No stations available" 
**Most common solution:** Click the **"Retry" button** in the widget, or open the widget and click refresh.

If that doesn't work:
```bash
# Check if stations file exists and has content
cat ~/globalplayer-daemon/stations_static.json

# Test D-Bus
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations

# If needed, reinstall with the install script
./install.sh
```

### Widget doesn't appear in "Add Widgets"
```bash
# Clear Plasma cache
rm -rf ~/.cache/plasma* ~/.cache/plasmashell

# Restart Plasma
systemctl --user restart plasma-plasmashell.service
# OR
kquitapp6 plasmashell && kstart plasmashell
```

### Stations won't play
```bash
# Test if mpv is working
mpv https://media-ssl.musicradio.com/ClassicFM

# If not, install mpv
sudo pacman -S mpv  # Arch
sudo apt install mpv  # Ubuntu/Debian
```

### Missing python3-dbus on second PC
```bash
# Install the required Python dependencies
sudo apt install python3-dbus python3-gi  # Ubuntu/Debian
sudo pacman -S python-dbus python-gobject  # Arch
sudo dnf install python3-dbus python3-gobject  # Fedora

# Restart daemon after installing
systemctl --user restart gpd.service
```

## File Structure

```
Global-Player-Plasma6-Widgets/
├── install.sh                    # Main installer (UPDATED)
├── plasma6_4_main.qml            # Plasma 6.4+ QML (SVG icons, no ScrollView)
├── plasma6_main_qml              # Plasma 6.0-6.3 QML (Unicode symbols)
├── plasma5_main_qml              # Plasma 5.x QML
├── globalplayer-daemon/          # Backend daemon
│   ├── gpd.py                    # Main daemon
│   ├── playback_mpv.py           # MPV integration
│   └── stations_static.json      # Default stations (replaced by preset)
├── Global-Player-presets/        # Regional station packages
│   ├── create_uk_package.sh
│   ├── create_usa_package.sh
│   ├── create_canada_package.sh
│   ├── create_germany_package.sh
│   ├── create_spain_package.sh
│   └── create_italy_package.sh
├── org.mooheda.globalplayer/     # Metadata files
│   ├── v5/metadata.desktop
│   └── v6/
│       ├── metadata.json
│       └── metadata.desktop
└── gpd.service                   # Systemd user service
```

## Key Changes from Original

### install.sh
- ✅ Forces overwrite of existing main.qml with `-f` flag
- ✅ Copies `plasma6_4_main.qml` (not plasma6_4_svg_icons.qml)
- ✅ Fixed typos in dependency installation commands
- ✅ Better Plasma 6.4 version detection

### plasma6_4_main.qml
- ✅ Removed broken ScrollView (not available in Plasma 6.4)
- ✅ Uses plain Item with ListView and clip: true instead
- ✅ Connection retry logic for daemon
- ✅ Visual error indicators
- ✅ SVG icons via Kirigami.Icon (system icons, no files needed)

## Usage

### Panel Mode (Compact)
- **Left click** - Play/Pause
- **Right click** - Next station
- **Middle click** - Open full widget
- **Scroll wheel** - Previous/Next station

### Full Widget
- **Station dropdown** - Select station
- **Play/Pause button** - Control playback
- **Previous/Next buttons** - Navigate stations
- **Mode switch** - Toggle Radio/Media (media mode not yet implemented)

## Credits

- **Original Author:** X-Seti (Mooheda)
- **Plasma 6.4 Fixes:** Community contributions
- **License:** GPL v3

## Support

- Check daemon status: `systemctl --user status gpd.service`
- View daemon logs: `journalctl --user -u gpd.service -f`
- Test D-Bus: `qdbus org.mooheda.gpd /org/mooheda/gpd`

For more help, check the logs and ensure all dependencies are installed correctly.
