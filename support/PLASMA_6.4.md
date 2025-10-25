# Global Player v3.2.2 - Plasma 6.4 Fix Guide - X-Seti

## Issues Fixed

### 1. Plasma Version Detection
**Problem:** Install script checked for `kquitapp5` first, failing on Plasma 6.4
**Fix:** Improved detection that checks `plasmashell --version` first

### 2. Radio Stations Not Loading
**Problems:**
- D-Bus connection failing silently
- No error messages when stations don't load
- Daemon not starting properly

**Fixes:**
- Added connection retry logic (10 attempts)
- Better error messages in UI
- Connection status indicator
- Improved D-Bus error handling

### 3. QML Compatibility
**Problem:** Old imports not compatible with Plasma 6.4
**Fix:** Updated to Plasma 6.4 compatible imports

## Installation Instructions

### Step 1: Backup Current Installation (Optional)
```bash
mv ~/.local/share/plasma/plasmoids/org.mooheda.globalplayer ~/.local/share/plasma/plasmoids/org.mooheda.globalplayer.backup
mv ~/globalplayer-daemon ~/globalplayer-daemon.backup
```

### Step 2: Install Updated Files

Replace these 3 files in your Global Player directory:

1. **install.sh** → Replace with `install_fixed.sh`
2. **plasma6_main_qml** → Replace with `plasma6_4_main.qml`
3. Add **diagnose.sh** for troubleshooting

```bash
# Make scripts executable
chmod +x install_fixed.sh diagnose.sh

# Run installation
./install_fixed.sh
```

### Step 3: Verify Installation

```bash
# Make diagnostic script executable and run it
chmod +x diagnose.sh
./diagnose.sh
```

## Key Improvements in Updated Files

### install_fixed.sh
- ✅ Better Plasma 6.4 detection
- ✅ Tests D-Bus connection after installation
- ✅ Shows station count after loading
- ✅ More detailed error messages
- ✅ Verifies daemon is running before finishing

### plasma6_4_main.qml
- ✅ Connection retry logic (10 attempts on startup)
- ✅ Visual connection status indicator
- ✅ Error messages shown in UI
- ✅ Better tooltips with connection status
- ✅ "Retry" and "Check Service" buttons
- ✅ Shows station count in UI
- ✅ Improved D-Bus error handling

### diagnose.sh (NEW)
- ✅ Comprehensive system check
- ✅ Verifies all components
- ✅ Tests D-Bus connection
- ✅ Shows daemon logs
- ✅ Lists loaded stations
- ✅ Provides fix recommendations

## Troubleshooting Steps

### Problem: "Daemon not connected"

1. Check if daemon is running:
```bash
systemctl --user status gpd.service
```

2. If not running, start it:
```bash
systemctl --user start gpd.service
```

3. Check logs for errors:
```bash
journalctl --user -u gpd.service -n 50
```

### Problem: "No stations available"

1. Check if stations file exists:
```bash
ls -lh ~/globalplayer-daemon/stations_static.json
```

2. View stations:
```bash
cat ~/globalplayer-daemon/stations_static.json | python3 -m json.tool | head -30
```

3. Test D-Bus stations method:
```bash
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations
```

### Problem: Widget shows "?" in panel

This means the daemon isn't connected. Run the diagnostic:
```bash
./diagnose.sh
```

### Problem: Can't find widget in "Add Widgets"

1. Verify installation:
```bash
ls -la ~/.local/share/plasma/plasmoids/org.mooheda.globalplayer/
```

2. Check metadata exists:
```bash
cat ~/.local/share/plasma/plasmoids/org.mooheda.globalplayer/metadata.json
```

3. Restart Plasma:
```bash
systemctl --user restart plasma-plasmashell.service
```

## Quick Fix Commands

### Restart Everything
```bash
systemctl --user restart gpd.service
systemctl --user restart plasma-plasmashell.service
```

### View Live Logs
```bash
journalctl --user -u gpd.service -f
```

### Test Playing a Station
```bash
# Replace "Classic FM" with any station name
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Play "Classic FM"
```

### Check D-Bus Methods
```bash
qdbus org.mooheda.gpd /org/mooheda/gpd | grep mooheda
```

## Visual Indicators in New UI

The updated widget shows clear status:

- **Green border + ✓**: Connected and working
- **Red border + ?**: Daemon not connected
- **Yellow banner**: Connection error with retry button
- **Tooltip**: Shows connection status, station count, error details

## Station Presets

The installer offers these presets:
- 🇬🇧 UK (25 stations)
- 🇺🇸 USA (15+ stations)  
- 🇨🇦 Canada (15 stations)
- 🇩🇪 Germany (18 stations)
- 🇪🇸 Spain (18 stations)
- 🇮🇹 Italy (20 stations)

## Dependencies for Plasma 6.4

### Debian/Ubuntu:
```bash
sudo apt install mpv qdbus-qt6 python3-dbus python3-gi python3-requests python3-pyqt6.qtwebengine
```

### Arch Linux:
```bash
sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt6-webengine
```

### Fedora:
```bash
sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-pyqt6-webengine
```

## What Changed in Each File

### install_fixed.sh Changes:
1. `detect_plasma_version()` - New function with 4 detection methods
2. D-Bus connection test after installation
3. Station count verification
4. Better error messages throughout
5. Service health check before finishing

### plasma6_4_main.qml Changes:
1. `daemonConnected` property to track connection
2. `startupTimer` for retry logic (10 attempts)
3. `errorMessage` property for user feedback
4. Connection status banner in UI
5. Enhanced tooltips with diagnostics
6. "Retry" and "Check Service" buttons
7. Better visual indicators (colors, borders)
8. Improved D-Bus error handling in `onNewData`

## Support

If issues persist after following this guide:

1. Run the diagnostic script and save output:
```bash
./diagnose.sh > diagnosis.txt
```

2. Check daemon logs:
```bash
journalctl --user -u gpd.service --no-pager > daemon-logs.txt
```

3. Check QML logs:
```bash
journalctl --user -u plasma-plasmashell.service --no-pager | grep -i "global player" > qml-logs.txt
```

These logs will help identify the specific issue.

## Known Working Configurations

✅ Plasma 6.4 on Arch Linux
✅ Plasma 6.3 on Ubuntu 24.04
✅ Plasma 6.2 on Fedora 40

If using Plasma 5.x, use the original `plasma5_main_qml` file instead.
