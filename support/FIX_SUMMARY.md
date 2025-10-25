# Global Player v3.2.2 - Plasma 6.4 Compatibility Update - X-Swti

## Summary of Issues and Fixes

### Issue #1: Plasma Version Detection Failed 
**Problem:** Install script checked for `kquitapp5` before `kquitapp6`, causing it to default to Plasma 5 on Plasma 6.4 systems.

**Solution:** Implemented multi-method detection:
1. Check `plasmashell --version` directly
2. Look for `kquitapp6` (Plasma 6)
3. Look for `kquitapp5` (Plasma 5)
4. Check for Plasma 6 metadata.json files
5. Default to Plasma 6 if uncertain

### Issue #2: Radio Stations Not Loading 
**Problems:**
- D-Bus connection failing silently
- No feedback when daemon isn't running
- No error messages in UI
- Stations loaded but not displayed

**Solution:** Multiple improvements:
1. Connection retry logic (10 attempts with 1s interval)
2. Visual connection status indicator (green/red border)
3. Error banner with "Retry" and "Che# Global Player Plasma 6 Widget - X-Seti - Sept 14 2025ck Service" buttons
4. Enhanced tooltips showing connection status
5. Station count display
6. Better D-Bus error handling and logging

### Issue #3: QML Import Compatibility 
**Problem:** Some imports may not be optimal for Plasma 6.4

**Solution:** Updated imports to use current Plasma 6 standards

## Files Updated

### 1. install.sh → install_fixed.sh
**Key Changes:**
```bash
# OLD - Failed on Plasma 6.4
if command -v kquitapp5 >/dev/null 2>&1; then
    PLASMA_VERSION="5"
elif command -v kquitapp6 >/dev/null 2>&1; then
    PLASMA_VERSION="6"
fi

# NEW - Works reliably
detect_plasma_version() {
    # Method 1: Direct version check
    if command -v plasmashell >/dev/null 2>&1; then
        PLASMA_VERSION_STRING=$(plasmashell --version 2>/dev/null | grep -oP 'plasmashell \K[0-9]+' | head -1)
        if [ "$PLASMA_VERSION_STRING" -ge 6 ]; then
            return 6
        fi
    fi
    # ... additional fallback methods
}
```

**New Features:**
- D-Bus connection test after installation
- Station count verification
- Service health check
- Better error messages

### 2. plasma6_main_qml → plasma6_4_main.qml
**Key Changes:**

```qml
// NEW - Connection tracking
property bool daemonConnected: false
property string errorMessage: ""

// NEW - Startup retry timer
Timer {
    id: startupTimer
    interval: 1000
    running: true
    repeat: true
    property int attempts: 0
    
    onTriggered: {
        attempts++
        if (!daemonConnected && attempts < 10) {
            testDaemonConnection()
        }
    }
}

// NEW - Connection status UI
Rectangle {
    visible: !daemonConnected || errorMessage !== ""
    color: PlasmaCore.Theme.negativeBackgroundColor
    
    RowLayout {
        PC3.Label {
            text: errorMessage || "Daemon not connected"
        }
        PC3.Button {
            text: "Retry"
            onClicked: testDaemonConnection()
        }
    }
}
```

**New Features:**
- Connection status property
- 10-retry startup logic
- Error message display
- Visual indicators (border colors)
- Retry/Check Service buttons
- Enhanced tooltips

### 3. diagnose.sh (NEW)
**Purpose:** Comprehensive system check for troubleshooting

**Features:**
- Detects Plasma version
- Checks daemon service status
- Verifies all required files
- Tests D-Bus connection
- Lists available stations
- Shows daemon logs
- Checks Python dependencies
- Provides fix recommendations

### 4. quick_fix.sh (NEW)
**Purpose:** One-command fix application

**Features:**
- Backs up existing files
- Applies all fixes
- Reinstalls widget
- Runs diagnostic
- Shows results

## Installation Methods

### Method 1: Fresh Install (Recommended)
```bash
# Download/clone the updated Global Player
cd Global-Player-directory

# Make scripts executable
chmod +x install_fixed.sh diagnose.sh

# Run installation
./install_fixed.sh

# Verify
./diagnose.sh
```

### Method 2: Quick Fix (Existing Installation)
```bash
# In your existing Global Player directory
chmod +x quick_fix.sh
./quick_fix.sh
```

### Method 3: Manual Update
```bash
# 1. Replace files
cp install_fixed.sh install.sh
cp plasma6_4_main.qml plasma6_main_qml

# 2. Reinstall
./install.sh

# 3. Verify
./diagnose.sh
```

## Visual Improvements

### Panel Icon (Compact Mode)
- **Before:** Just a music note icon
- **After:** 
  - Green border = Connected & playing
  - Gray border = Connected & paused  
  - Red border = Not connected
  - Shows "?" when disconnected

### Full Widget (Expanded Mode)
- **Before:** No indication when daemon offline
- **After:**
  - Connection status banner (red/yellow when issues)
  - "Retry" button for reconnection
  - "Check Service" button opens logs
  - Station counter (e.g., "Station 3 of 25")
  - Enhanced tooltips with details

## Testing Your Installation

### 1. Check Daemon Status
```bash
systemctl --user status gpd.service
```
**Expected:** Active (running)

### 2. Test D-Bus Connection
```bash
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations
```
**Expected:** JSON array of stations

### 3. Check Station Count
```bash
python3 -c "import json; print(len(json.load(open('~/globalplayer-daemon/stations_static.json'))))"
```
**Expected:** Number > 0

### 4. Run Diagnostic
```bash
./diagnose.sh
```
**Expected:** All ✓ checkmarks

### 5. Test Playback
```bash
qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Play "Classic FM"
```
**Expected:** Music starts playing

## Common Issues and Solutions

### "Daemon not connected" in widget
**Cause:** Service not running or D-Bus registration failed
**Fix:**
```bash
systemctl --user restart gpd.service
sleep 2
qdbus org.mooheda.gpd /org/mooheda/gpd
```

### "No stations available"
**Cause:** stations_static.json missing or empty
**Fix:**
```bash
# Reinstall with station preset
./install.sh
# Or manually check
cat ~/globalplayer-daemon/stations_static.json
```

### Widget not appearing in "Add Widgets"
**Cause:** Plasma cache or incorrect metadata
**Fix:**
```bash
rm -rf ~/.cache/plasma* ~/.cache/plasmashell
systemctl --user restart plasma-plasmashell.service
```

### Stations show but won't play
**Cause:** mpv not installed or network issue
**Fix:**
```bash
# Install mpv
sudo pacman -S mpv  # Arch
sudo apt install mpv  # Debian/Ubuntu

# Test URL directly
mpv https://media-ssl.musicradio.com/ClassicFM
```

## What Changed - Technical Details

### D-Bus Error Handling
**Before:**
```qml
onNewData: function(sourceName, data) {
    var out = data["stdout"]
    var arr = JSON.parse(out)  // Could fail silently
    stationsModel = arr
}
```

**After:**
```qml
onNewData: function(sourceName, data) {
    var out = (data["stdout"] || "").trim()
    var err = (data["stderr"] || "").trim()
    
    if (err && err.indexOf("not available") !== -1) {
        daemonConnected = false
        errorMessage = "Daemon not available"
    }
    
    try {
        var arr = JSON.parse(out)
        if (arr && arr.length > 0) {
            stationsModel = arr
            daemonConnected = true
            console.log("Loaded", arr.length, "stations")
        }
    } catch (e) {
        console.log("Parse error:", e)
        errorMessage = "Failed to parse stations"
    }
}
```

### Connection Testing
**New function:**
```qml
function testDaemonConnection() {
    qdbusCall("GetState", [])
}

// Called by startup timer
Timer {
    interval: 1000
    repeat: true
    property int attempts: 0
    
    onTriggered: {
        if (!daemonConnected && attempts < 10) {
            testDaemonConnection()
            attempts++
        }
    }
}
```

## Performance Impact

✅ **Minimal** - Connection retries only happen on startup
✅ **Better responsiveness** - User sees connection status immediately
✅ **Same polling** - 10s metadata updates unchanged
✅ **No extra load** - Connection checks use existing D-Bus calls

## Backwards Compatibility

✅ **Plasma 6.0-6.4** - Fully compatible
✅ **Plasma 5.x** - Use original `plasma5_main_qml` file
✅ **Station files** - Unchanged format
✅ **Daemon** - No changes required
✅ **D-Bus** - Same interface

## Migration Path

For existing users:

1. **Backup** (optional but recommended)
2. **Stop** daemon: `systemctl --user stop gpd.service`
3. **Update** files (see Installation Methods above)
4. **Reinstall**: `./install.sh`
5. **Verify**: `./diagnose.sh`
6. **Restart** Plasma

Total time: ~5 minutes

## File Checksums (for verification)

After applying fixes, verify you have the correct files:

```bash
# Check line counts
wc -l install.sh         # Should be ~400+ lines
wc -l plasma6_main_qml   # Should be ~600+ lines
wc -l diagnose.sh        # Should be ~200+ lines

# Check for key features
grep -q "detect_plasma_version" install.sh && echo "✓ Has new detection"
grep -q "daemonConnected" plasma6_main_qml && echo "✓ Has connection tracking"
grep -q "startupTimer" plasma6_main_qml && echo "✓ Has retry logic"
```

## Support Resources

- **Installation Guide:** PLASMA_6.4_FIX_GUIDE.md
- **Diagnostic Tool:** diagnose.sh
- **Quick Fix:** quick_fix.sh
- **Logs:** `journalctl --user -u gpd.service -f`

## Credits

- Original Author: X-Seti (Mooheda)
- Plasma 6.4 Fixes: [Your contribution]
- Testing: Community

## License

GPL v3 (unchanged from original)
