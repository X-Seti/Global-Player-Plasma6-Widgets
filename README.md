# Global Player Plasma 6.4 Widget - X-Seti - Oct 24 2025

## Files Included

### Core Files (Required)
2. **plasma6_4_main.qml** - Fixed QML with connection retry logic 
3. **diagnose.sh** - Diagnostic tool for troubleshooting

### Utility Files
4. **quick_fix.sh** - One-command fix application script

### Documentation
5. **PLASMA_6.4_FIX_GUIDE.md** - Complete installation and troubleshooting guide
6. **COMPLETE_FIX_SUMMARY.md** - Technical details of all changes

## Quick Start

### For Fresh Installation:
```bash
# 2. Make scripts executable
chmod +x install_fixed.sh diagnose.sh

# 3. Run the installer
./install_fixed.sh

# 4. Verify installation
./diagnose.sh
```

### For Existing Installation:
```bash
# 1. Backup your current install.sh and plasma6_main_qml
cp install.sh install.sh.backup
cp plasma6_main_qml plasma6_main_qml.backup

# 2. Replace with fixed versions
cp install_fixed.sh install.sh
cp plasma6_4_main.qml plasma6_main_qml

# 3. Reinstall
./install.sh

# 4. Verify
./diagnose.sh
```

### Using Quick Fix (Automatic):
```bash
# Place quick_fix.sh in your Global Player directory
chmod +x quick_fix.sh
./quick_fix.sh
```

## 🔧 What's Fixed

### Issue #1: Plasma Version Detection 
- **Before:** Failed to detect Plasma 6.4
- **After:** Multi-method detection (plasmashell version, kquitapp6, metadata.json)

### Issue #2: Radio Stations Not Loading 
- **Before:** Silent failures, no error messages
- **After:** 
  - Connection retry logic (10 attempts)
  - Visual status indicators
  - Error messages in UI
  - "Retry" and "Check Service" buttons

### Issue #3: No User Feedback 
- **Before:** Widget showed nothing when daemon offline
- **After:**
  - Red border when disconnected
  - Yellow banner with error details
  - Tooltips show connection status
  - Station count display

## File Descriptions

### install_fixed.sh (14KB)
Replace your existing `install.sh` with this file.

**Improvements:**
- Better Plasma 6.4 detection
- D-Bus connection test after install
- Station count verification
- Service health checks
- Better error messages

### plasma6_4_main.qml (25KB)
Replace your existing `plasma6_main_qml` with this file.

**Improvements:**
- Connection retry logic (10 attempts on startup)
- Visual connection status (green/red borders)
- Error banner with Retry button
- Enhanced tooltips with diagnostics
- Better D-Bus error handling
- Station counter display

### diagnose.sh (6.5KB)
New diagnostic tool - add to your Global Player directory.

**Features:**
- Checks Plasma version
- Verifies daemon service
- Tests D-Bus connection
- Lists loaded stations
- Shows daemon logs
- Checks dependencies
- Provides fix recommendations

### quick_fix.sh (2.3KB)
Optional - automates the fix process.

**What it does:**
1. Backs up existing files
2. Applies all fixes
3. Reinstalls widget
4. Runs diagnostic
5. Shows results

## Verification Steps

After installation, verify everything works:

```bash
# 1. Check daemon is running
systemctl --user status gpd.service
# Expected: Active (running)

# 2. Test D-Bus
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations
# Expected: JSON array of stations

# 3. Run diagnostic
./diagnose.sh
# Expected: All ✓ checkmarks

# 4. Add widget to panel
# Right-click panel → Add Widgets → Search "Global Player"
```

## Troubleshooting

### Widget shows "?" in panel
**Cause:** Daemon not connected

**Fix:**
```bash
systemctl --user restart gpd.service
./diagnose.sh
```

### "No stations available"
**Cause:** stations_static.json missing or empty

**Fix:**
```bash
./install.sh  # Reinstall with station preset
cat ~/globalplayer-daemon/stations_static.json  # Verify stations exist
```

### Widget doesn't appear in "Add Widgets"
**Cause:** Plasma cache

**Fix:**
```bash
rm -rf ~/.cache/plasma*
systemctl --user restart plasma-plasmashell.service
```

## Documentation Files

### PLASMA_6.4_FIX_GUIDE.md
Complete installation and troubleshooting guide with:
- Step-by-step installation
- All troubleshooting scenarios
- Quick fix commands
- Visual indicator explanations
- Dependency requirements

### COMPLETE_FIX_SUMMARY.md
Technical documentation with:
- Before/after code comparisons
- All changes explained
- Technical implementation details
- Performance impact
- Migration path
- File checksums

## System Requirements

### For Plasma 6.4:
- KDE Plasma 6.0 or higher (6.4 tested)
- mpv
- qdbus-qt6 (or qdbus)
- Python 3 with: dbus, gi, requests
- PyQt6 WebEngine (for sign-in feature)

### Installation (Arch Linux):
```bash
sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt6-webengine
```

### Installation (Ubuntu/Debian):
```bash
sudo apt install mpv qdbus-qt6 python3-dbus python3-gi python3-requests python3-pyqt6.qtwebengine
```

### Installation (Fedora):
```bash
sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-pyqt6-webengine
```

## Station Presets Available

The installer offers these regional presets:
- 🇬🇧 UK - 25 stations (Heart, Capital, Classic FM, LBC, etc.)
- 🇺🇸 USA - 15+ stations (iHeartRadio, NPR, KEXP, etc.)
- 🇨🇦 Canada - 15 stations (Jack FM, Virgin Radio, CBC, etc.)
- 🇩🇪 Germany - 18 stations (1LIVE, Bayern 3, SWR3, etc.)
- 🇪🇸 Spain - 18 stations (Cadena SER, Los 40, Europa FM, etc.)
- 🇮🇹 Italy - 20 stations (RTL 102.5, Radio Deejay, RDS, etc.)

## Testing Checklist

After installation, test these features:

- [ ] Widget appears in "Add Widgets" menu
- [ ] Widget shows in panel with music note icon
- [ ] Border is green (connected) not red (disconnected)
- [ ] Clicking icon toggles play/pause
- [ ] Right-clicking switches stations
- [ ] Scrolling on icon changes stations
- [ ] Opening full view shows station list
- [ ] Station counter shows (e.g., "3 of 25")
- [ ] No error banners visible
- [ ] Tooltip shows connection status

If any fail, run `./diagnose.sh` for detailed diagnostics.

## 📞 Support

If issues persist:

1. Run diagnostic and save output:
   ```bash
   ./diagnose.sh > diagnosis.txt
   ```

2. Check daemon logs:
   ```bash
   journalctl --user -u gpd.service --no-pager > daemon-logs.txt
   ```

3. Share these files when asking for help

## License

GPL v3 (same as original Global Player)

## Credits

- **Original Author:** X-Seti (Mooheda)
- **Plasma 6.4 Fixes:** Community contribution
- **Version:** 3.2.2 (Plasma 6.4 compatible)

---

**Last Updated:** October 25, 2025
**Compatible With:** KDE Plasma 6.0 - 6.4+
