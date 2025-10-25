#!/usr/bin/env bash
# X-Seti - GlobalPlayer 3.2.2 - Fixed for Plasma 6.4
set -euo pipefail

PLASMOID_ID="org.mooheda.globalplayer"
PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"
DAEMON_SRC="$(dirname "$0")/globalplayer-daemon"
DAEMON_DST="${HOME}/globalplayer-daemon"
PRESETS_DIR="$(dirname "$0")/Global-Player-presets"

# Function to extract JSON from preset shell scripts
extract_stations_from_preset() {
    local preset_file="$1"
    local output_file="$2"
    
    if [ ! -f "$preset_file" ]; then
        echo "❌ Preset file not found: $preset_file"
        return 1
    fi
    
    echo "[+] Extracting stations from $(basename "$preset_file")..."
    
    # Extract the JSON content between 'EOF' markers in the shell script
    awk '/cat.*stations_static\.json.*EOF/,/^EOF$/ {
        if ($0 !~ /cat.*EOF/ && $0 != "EOF") print
    }' "$preset_file" > "$output_file"
    
    # Verify the extracted JSON is valid
    if python3 -m json.tool "$output_file" >/dev/null 2>&1; then
        local station_count=$(python3 -c "import json; data=json.load(open('$output_file')); print(len(data))" 2>/dev/null || echo "0")
        echo "    ✓ Extracted $station_count stations"
        return 0
    else
        echo "    ❌ Invalid JSON extracted"
        return 1
    fi
}

# Station preset selection menu
select_station_preset() {
    echo ""
    echo "🎵 Select Your Regional Station Package:"
    echo "========================================"
    echo ""
    
    # Check what presets are actually available
    local available_presets=()
    local preset_descriptions=()
    
    if [ -f "${PRESETS_DIR}/create_uk_package.sh" ]; then
        available_presets+=("uk")
        preset_descriptions+=("🇬🇧 UK - Heart, Capital, Classic FM, LBC, Smooth, Radio X, Gold")
    fi
    
    if [ -f "${PRESETS_DIR}/create_usa_package.sh" ]; then
        available_presets+=("usa")
        preset_descriptions+=("🇺🇸 USA - iHeartRadio, NPR, KEXP, various regional stations")
    fi
    
    if [ -f "${PRESETS_DIR}/create_canada_package.sh" ]; then
        available_presets+=("canada") 
        preset_descriptions+=("🇨🇦 Canada - Jack FM, Virgin Radio, CBC, CFOX, regional stations")
    fi
    
    if [ -f "${PRESETS_DIR}/create_germany_package.sh" ]; then
        available_presets+=("germany")
        preset_descriptions+=("🇩🇪 Germany - 1LIVE, Bayern 3, SWR3, Deutschlandfunk, regional")
    fi
    
    if [ -f "${PRESETS_DIR}/create_spain_package.sh" ]; then
        available_presets+=("spain")
        preset_descriptions+=("🇪🇸 Spain - Cadena SER, Los 40, Europa FM, COPE, RNE")
    fi
    
    if [ -f "${PRESETS_DIR}/create_italy_package.sh" ]; then
        available_presets+=("italy")
        preset_descriptions+=("🇮🇹 Italy - RTL 102.5, Radio Deejay, RDS, Rai Radio, regional")
    fi
    
    # Always offer default
    available_presets+=("default")
    preset_descriptions+=("🌍 Default - Use existing station configuration")
    
    # Display available options
    for i in "${!available_presets[@]}"; do
        echo "$((i+1))) ${preset_descriptions[$i]}"
    done
    echo ""
    
    # Get user selection
    while true; do
        read -p "Enter choice (1-${#available_presets[@]}): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_presets[@]}" ]; then
            local selected_index=$((choice-1))
            PRESET="${available_presets[$selected_index]}"
            PRESET_NAME="${preset_descriptions[$selected_index]}"
            echo "[+] Selected: $PRESET_NAME"
            break
        else
            echo "❌ Invalid choice. Please enter a number between 1 and ${#available_presets[@]}."
        fi
    done
    
    return 0
}

# Install selected station preset
install_station_preset() {
    local preset_type="$1"
    local stations_output_file="$2"
    
    if [ "$preset_type" = "default" ]; then
        echo "[+] Using default station configuration..."
        if [ -f "${DAEMON_SRC}/stations_static.json" ]; then
            cp "${DAEMON_SRC}/stations_static.json" "$stations_output_file"
            echo "    ✓ Default stations copied"
            return 0
        else
            echo "    ❌ Default stations_static.json not found"
            return 1
        fi
    fi
    
    # Map preset type to actual file
    local preset_file=""
    case "$preset_type" in
        "uk")      preset_file="${PRESETS_DIR}/create_uk_package.sh" ;;
        "usa")     preset_file="${PRESETS_DIR}/create_usa_package.sh" ;;
        "canada")  preset_file="${PRESETS_DIR}/create_canada_package.sh" ;;
        "germany") preset_file="${PRESETS_DIR}/create_germany_package.sh" ;;
        "spain")   preset_file="${PRESETS_DIR}/create_spain_package.sh" ;;
        "italy")   preset_file="${PRESETS_DIR}/create_italy_package.sh" ;;
        *)
            echo "❌ Unknown preset type: $preset_type"
            return 1
            ;;
    esac
    
    if extract_stations_from_preset "$preset_file" "$stations_output_file"; then
        echo "    ✓ Station preset '$preset_type' installed successfully"
        return 0
    else
        echo "    ❌ Failed to install preset '$preset_type'"
        return 1
    fi
}

# Detect Plasma version - IMPROVED FOR PLASMA 6.4
detect_plasma_version() {
    echo "[+] Detecting Plasma version..."
    
    # Method 1: Check plasmashell version directly
    if command -v plasmashell >/dev/null 2>&1; then
        PLASMA_VERSION_STRING=$(plasmashell --version 2>/dev/null | grep -oP 'plasmashell \K[0-9]+' | head -1)
        if [ -n "$PLASMA_VERSION_STRING" ]; then
            if [ "$PLASMA_VERSION_STRING" -ge 6 ]; then
                echo "    ✓ Detected Plasma $PLASMA_VERSION_STRING via plasmashell"
                return 6
            else
                echo "    ✓ Detected Plasma $PLASMA_VERSION_STRING via plasmashell"
                return 5
            fi
        fi
    fi
    
    # Method 2: Check for Plasma 6 specific tools
    if command -v kquitapp6 >/dev/null 2>&1; then
        echo "    ✓ Detected Plasma 6 via kquitapp6"
        return 6
    fi
    
    # Method 3: Check for Plasma 5 tools
    if command -v kquitapp5 >/dev/null 2>&1; then
        echo "    ✓ Detected Plasma 5 via kquitapp5"
        return 5
    fi
    
    # Method 4: Check plasmoid installation paths
    if [ -d "${HOME}/.local/share/plasma/plasmoids" ]; then
        # Check for any Plasma 6 widgets
        if find "${HOME}/.local/share/plasma/plasmoids" -name "metadata.json" | grep -q .; then
            echo "    ✓ Detected Plasma 6 via metadata.json files"
            return 6
        fi
    fi
    
    # Fallback: assume Plasma 6 if we can't determine
    echo "    ⚠️  Could not determine Plasma version, assuming Plasma 6"
    return 6
}

# Main installation starts here
echo "🎵 Global Player v3.2.2 Installation - Plasma 6.4 Compatible"
echo "============================================================"

# Check if preset directory exists
if [ ! -d "$PRESETS_DIR" ]; then
    echo "❌ Error: Global-Player-presets directory not found!"
    echo "   Expected: $PRESETS_DIR"
    echo "   Please ensure the Global-Player-presets directory exists."
    exit 1
fi

# Detect Plasma version with improved detection
detect_plasma_version
PLASMA_VERSION=$?

echo "[+] Installing for Plasma ${PLASMA_VERSION}"

# Select station preset
select_station_preset

echo "[+] Installing dependencies (you may need sudo):"
if [ "$PLASMA_VERSION" = "6" ]; then
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus-qt6 python3-dbus python3-gi python3-requests python3-pyqt6.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt6-webengine"
    echo "    Fedora:        sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-pyqt6-webengine"
else
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt5-tools python-dbus python-gobject python-requests python-pyqt5-webengine"  
    echo "    Fedora:        sudo dnf install mpv qt5-qttools python3-dbus python3-gobject python3-requests python3-pyqt5-webengine"
fi

echo "[+] Installing plasmoid to ${PLASMOID_DST}"
mkdir -p "${PLASMOID_DST}/contents/ui"

# Install daemon files first
echo "[+] Installing daemon files..."
if [ -d "${DAEMON_SRC}" ]; then
    mkdir -p "${DAEMON_DST}"
    rsync -a "${DAEMON_SRC}/" "${DAEMON_DST}/"
    echo "    ✓ Base daemon files copied"
else
    echo "❌ Error: Daemon source directory ${DAEMON_SRC} not found!"
    exit 1
fi

# Install selected station preset
TEMP_STATIONS="/tmp/stations_selected.json"
if install_station_preset "$PRESET" "$TEMP_STATIONS"; then
    cp "$TEMP_STATIONS" "${DAEMON_DST}/stations_static.json"
    rm -f "$TEMP_STATIONS"
    echo "    ✓ Station preset installed to daemon"
else
    echo "    ⚠️  Failed to install preset, using default stations"
fi

# Install appropriate QML and metadata based on Plasma version
if [ "$PLASMA_VERSION" = "6" ]; then
    echo "[+] Installing Plasma 6 files..."
    
    if [ -f "$(dirname "$0")/plasma6_main_qml" ]; then
        cp "$(dirname "$0")/plasma6_main_qml" "${PLASMOID_DST}/contents/ui/main.qml"
        echo "    ✓ Plasma 6 QML installed"
    else
        echo "❌ Error: plasma6_main_qml not found!"
        exit 1
    fi
    
    if [ -f "$(dirname "$0")/org.mooheda.globalplayer/v6/metadata.json" ]; then
        cp "$(dirname "$0")/org.mooheda.globalplayer/v6/metadata.json" "${PLASMOID_DST}/metadata.json"
        echo "    ✓ Plasma 6 metadata.json installed"
    fi
    
    if [ -f "$(dirname "$0")/org.mooheda.globalplayer/v6/metadata.desktop" ]; then
        cp "$(dirname "$0")/org.mooheda.globalplayer/v6/metadata.desktop" "${PLASMOID_DST}/metadata.desktop"
        echo "    ✓ Plasma 6 metadata.desktop installed"
    fi

elif [ "$PLASMA_VERSION" = "5" ]; then
    echo "[+] Installing Plasma 5 files..."
    
    if [ -f "$(dirname "$0")/plasma5_main_qml" ]; then
        cp "$(dirname "$0")/plasma5_main_qml" "${PLASMOID_DST}/contents/ui/main.qml"
        echo "    ✓ Plasma 5 QML installed"
    else
        echo "❌ Error: plasma5_main_qml not found!"
        exit 1
    fi
    
    if [ -f "$(dirname "$0")/org.mooheda.globalplayer/v5/metadata.desktop" ]; then
        cp "$(dirname "$0")/org.mooheda.globalplayer/v5/metadata.desktop" "${PLASMOID_DST}/metadata.desktop"
        echo "    ✓ Plasma 5 metadata.desktop installed"
    fi
fi

echo "[+] Installing systemd --user service"
mkdir -p "${HOME}/.config/systemd/user"
if [ -f "$(dirname "$0")/gpd.service" ]; then
    cp "$(dirname "$0")/gpd.service" "${HOME}/.config/systemd/user/gpd.service"
    systemctl --user daemon-reload || true
    
    # Stop any existing service
    systemctl --user stop gpd.service 2>/dev/null || true
    
    # Enable and start
    systemctl --user enable gpd.service || true
    systemctl --user start gpd.service || true
    
    echo "    ✓ Service installed and started"
    
    # Wait and check service status
    sleep 2
    if systemctl --user is-active gpd.service >/dev/null 2>&1; then
        echo "    ✓ Service is running"
    else
        echo "    ⚠️  Service may have failed to start. Check: systemctl --user status gpd.service"
    fi
fi

# Test D-Bus connection
echo "[+] Testing D-Bus connection..."
sleep 2
if qdbus org.mooheda.gpd /org/mooheda/gpd >/dev/null 2>&1; then
    echo "    ✓ D-Bus connection successful"
    
    # Try to get stations
    STATIONS_JSON=$(qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations 2>/dev/null || echo "[]")
    STATION_COUNT=$(echo "$STATIONS_JSON" | python3 -c "import sys, json; print(len(json.loads(sys.stdin.read())))" 2>/dev/null || echo "0")
    echo "    ✓ Found $STATION_COUNT stations via D-Bus"
else
    echo "    ⚠️  D-Bus connection failed. Daemon may need more time to start."
    echo "    Check daemon status: systemctl --user status gpd.service"
    echo "    Check daemon logs: journalctl --user -u gpd.service -n 50"
fi

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
echo "💡 Wait 10-15 seconds for Plasma to fully load"

echo ""
echo "✅ Global Player v3.2.2 installation complete!"
echo ""
echo "📋 Installation Summary:"
echo "   • Target: Plasma ${PLASMA_VERSION}"  
echo "   • Stations: $PRESET_NAME"
echo "   • Widget: ${PLASMOID_DST}"
echo "   • Daemon: ${DAEMON_DST}"
echo ""
echo "🎯 Next Steps:"
echo "   1. Wait 10-15 seconds for Plasma to reload"
echo "   2. Right-click panel → Add Widgets → Search 'Global Player'"
echo "   3. Add widget to panel or desktop"
echo ""
echo "🎵 Your selected station preset is now active!"
echo ""
echo "🔧 Troubleshooting:"
echo "   • Check service: systemctl --user status gpd.service"
echo "   • View logs: journalctl --user -u gpd.service -f"
echo "   • Check stations: cat ${DAEMON_DST}/stations_static.json"
echo "   • Test D-Bus: qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations"
