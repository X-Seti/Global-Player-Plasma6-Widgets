#!/usr/bin/env bash
# Global Player Diagnostic Script for Plasma 6.4
# Helps identify why stations aren't loading

echo "🔍 Global Player Diagnostic Report"
echo "===================================="
echo ""

# Check Plasma version
echo "📊 System Information:"
echo "---------------------"
if command -v plasmashell >/dev/null 2>&1; then
    PLASMA_VERSION=$(plasmashell --version 2>/dev/null)
    echo "Plasma: $PLASMA_VERSION"
else
    echo "❌ plasmashell not found"
fi

if command -v qdbus >/dev/null 2>&1; then
    echo "✓ qdbus command available"
else
    echo "❌ qdbus command not found - install qdbus-qt6"
fi

echo ""

# Check daemon service
echo "🔧 Daemon Service Status:"
echo "------------------------"
if systemctl --user is-active gpd.service >/dev/null 2>&1; then
    echo "✓ Service is running"
else
    echo "❌ Service is NOT running"
    echo ""
    echo "Service status:"
    systemctl --user status gpd.service --no-pager -l
fi

echo ""

# Check daemon files
echo "📁 Daemon Files:"
echo "---------------"
if [ -d "${HOME}/globalplayer-daemon" ]; then
    echo "✓ Daemon directory exists"
    
    if [ -f "${HOME}/globalplayer-daemon/gpd.py" ]; then
        echo "✓ gpd.py found"
    else
        echo "❌ gpd.py missing"
    fi
    
    if [ -f "${HOME}/globalplayer-daemon/playback_mpv.py" ]; then
        echo "✓ playback_mpv.py found"
    else
        echo "❌ playback_mpv.py missing"
    fi
    
    if [ -f "${HOME}/globalplayer-daemon/stations_static.json" ]; then
        echo "✓ stations_static.json found"
        STATION_COUNT=$(python3 -c "import json; print(len(json.load(open('${HOME}/globalplayer-daemon/stations_static.json'))))" 2>/dev/null || echo "0")
        echo "  → Contains $STATION_COUNT stations"
        
        echo ""
        echo "First 3 stations:"
        python3 -c "import json; data=json.load(open('${HOME}/globalplayer-daemon/stations_static.json')); [print(f\"  • {s['name']}\") for s in data[:3]]" 2>/dev/null
    else
        echo "❌ stations_static.json missing"
    fi
else
    echo "❌ Daemon directory not found at ${HOME}/globalplayer-daemon"
fi

echo ""

# Check D-Bus connection
echo "🔌 D-Bus Connection:"
echo "-------------------"
if qdbus org.mooheda.gpd >/dev/null 2>&1; then
    echo "✓ D-Bus service 'org.mooheda.gpd' is available"
    
    echo ""
    echo "Available D-Bus methods:"
    qdbus org.mooheda.gpd /org/mooheda/gpd 2>/dev/null | grep -E "(Play|GetStations|GetState|GetNowPlaying)" || echo "  No methods found"
    
    echo ""
    echo "Testing GetState:"
    STATE_RESULT=$(qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetState 2>&1)
    if echo "$STATE_RESULT" | python3 -m json.tool >/dev/null 2>&1; then
        echo "✓ GetState works"
        echo "$STATE_RESULT" | python3 -m json.tool | head -10
    else
        echo "❌ GetState failed: $STATE_RESULT"
    fi
    
    echo ""
    echo "Testing GetStations:"
    STATIONS_RESULT=$(qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations 2>&1)
    if echo "$STATIONS_RESULT" | python3 -m json.tool >/dev/null 2>&1; then
        STATION_COUNT=$(echo "$STATIONS_RESULT" | python3 -c "import sys, json; print(len(json.loads(sys.stdin.read())))")
        echo "✓ GetStations works - returned $STATION_COUNT stations"
        echo "First 5 stations:"
        echo "$STATIONS_RESULT" | python3 -c "import sys, json; [print(f'  • {s}') for s in json.loads(sys.stdin.read())[:5]]"
    else
        echo "❌ GetStations failed: $STATIONS_RESULT"
    fi
    
else
    echo "❌ D-Bus service 'org.mooheda.gpd' NOT available"
    echo ""
    echo "Possible issues:"
    echo "  1. Daemon is not running (check above)"
    echo "  2. D-Bus session bus not accessible"
    echo "  3. Daemon crashed on startup"
fi

echo ""

# Check daemon logs
echo "📝 Recent Daemon Logs:"
echo "---------------------"
if journalctl --user -u gpd.service --no-pager -n 20 2>/dev/null | grep -q .; then
    journalctl --user -u gpd.service --no-pager -n 20
else
    echo "No logs available (service may never have started)"
fi

echo ""

# Check Python dependencies
echo "🐍 Python Dependencies:"
echo "----------------------"
for module in dbus gi requests PyQt6.QtWebEngineWidgets; do
    if python3 -c "import $module" 2>/dev/null; then
        echo "✓ $module installed"
    else
        echo "❌ $module NOT installed"
    fi
done

echo ""

# Check mpv
echo "🎵 Media Player:"
echo "---------------"
if command -v mpv >/dev/null 2>&1; then
    MPV_VERSION=$(mpv --version | head -1)
    echo "✓ mpv: $MPV_VERSION"
else
    echo "❌ mpv not installed"
fi

echo ""

# Check widget installation
echo "📦 Widget Installation:"
echo "----------------------"
WIDGET_PATH="${HOME}/.local/share/plasma/plasmoids/org.mooheda.globalplayer"
if [ -d "$WIDGET_PATH" ]; then
    echo "✓ Widget directory exists"
    
    if [ -f "$WIDGET_PATH/contents/ui/main.qml" ]; then
        echo "✓ main.qml found"
        QML_SIZE=$(wc -l < "$WIDGET_PATH/contents/ui/main.qml")
        echo "  → QML file: $QML_SIZE lines"
    else
        echo "❌ main.qml missing"
    fi
    
    if [ -f "$WIDGET_PATH/metadata.json" ]; then
        echo "✓ metadata.json found (Plasma 6)"
    elif [ -f "$WIDGET_PATH/metadata.desktop" ]; then
        echo "⚠️  metadata.desktop found (Plasma 5 format)"
        echo "   → You may need Plasma 6 version"
    else
        echo "❌ No metadata file found"
    fi
else
    echo "❌ Widget not installed at $WIDGET_PATH"
fi

echo ""

# Recommendations
echo "💡 Recommendations:"
echo "------------------"

if ! systemctl --user is-active gpd.service >/dev/null 2>&1; then
    echo "1. Start the daemon:"
    echo "   systemctl --user start gpd.service"
    echo ""
fi

if ! qdbus org.mooheda.gpd >/dev/null 2>&1; then
    echo "2. Check why daemon isn't registering with D-Bus:"
    echo "   journalctl --user -u gpd.service -f"
    echo ""
fi

if [ ! -f "${HOME}/globalplayer-daemon/stations_static.json" ]; then
    echo "3. Stations file missing - reinstall with correct preset"
    echo ""
fi

echo "4. To manually test station playback:"
echo "   qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.Play \"Classic FM\""
echo ""

echo "5. View real-time logs:"
echo "   journalctl --user -u gpd.service -f"
echo ""

echo "6. Restart everything:"
echo "   systemctl --user restart gpd.service"
echo "   systemctl --user restart plasma-plasmashell.service"
echo ""

echo "===================================="
echo "Diagnostic complete!"
