#!/usr/bin/env bash
# X-Seti - GlobalPlayer 3.2.3 - User Choice Plasma Version
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
    
    awk '/cat.*stations_static\.json.*EOF/,/^EOF$/ {
        if ($0 !~ /cat.*EOF/ && $0 != "EOF") print
    }' "$preset_file" > "$output_file"
    
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
    
    available_presets+=("default")
    preset_descriptions+=("🌍 Default - Use existing station configuration")
    
    for i in "${!available_presets[@]}"; do
        echo "$((i+1))) ${preset_descriptions[$i]}"
    done
    echo ""
    
    while true; do
        read -p "Enter choice (1-${#available_presets[@]}): " choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#available_presets[@]}" ]; then
            local selected_index=$((choice-1))
            PRESET="${available_presets[$selected_index]}"
            PRESET_NAME="${preset_descriptions[$selected_index]}"
            echo "[+] Selected: $PRESET_NAME"
            break
        else
            echo "Invalid choice. Please enter a number between 1 and ${#available_presets[@]}."
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

# Detect Plasma version automatically
detect_plasma_version() {
    echo "[+] Auto-detecting Plasma version..."
    
    # Method 1: Check plasmashell version directly
    if command -v plasmashell >/dev/null 2>&1; then
        local version_output=$(plasmashell --version 2>/dev/null)
        if echo "$version_output" | grep -q "plasmashell"; then
            local major_version=$(echo "$version_output" | grep -oP 'plasmashell \K[0-9]+' | head -1)
            local minor_version=$(echo "$version_output" | grep -oP 'plasmashell [0-9]+\.\K[0-9]+' | head -1)
            
            if [ -n "$major_version" ]; then
                echo "    ✓ Detected Plasma $major_version.$minor_version via plasmashell"
                
                # Return specific version for 6.4+
                if [ "$major_version" -ge 6 ] && [ "${minor_version:-0}" -ge 4 ]; then
                    return 64  # Plasma 6.4+
                elif [ "$major_version" -ge 6 ]; then
                    return 60  # Plasma 6.0-6.3
                else
                    return 50  # Plasma 5.x
                fi
            fi
        fi
    fi
    
    # Method 2: Check for version-specific tools
    if command -v kquitapp6 >/dev/null 2>&1; then
        echo "    ✓ Detected Plasma 6.x via kquitapp6"
        return 60  # Default to 6.0 if can't determine minor version
    fi
    
    if command -v kquitapp5 >/dev/null 2>&1; then
        echo "    ✓ Detected Plasma 5.x via kquitapp5"
        return 50
    fi
    
    # Fallback: assume Plasma 6.0
    echo "    ⚠️  Could not determine version, assuming Plasma 6.0"
    return 60
}

# Manual Plasma version selection
select_plasma_version() {
    echo ""
    echo "🖥️  Plasma Version Selection:"
    echo "========================================"
    echo ""
    echo "Choose your Plasma version:"
    echo ""
    echo "1) 🔍 Automatic Detection (Recommended)"
    echo "2) 🔧 Plasma 5.x (Manual)"
    echo "3) ⚙️  Plasma 6.0-6.3 (Original layout, Unicode symbols)"
    echo "4) 🎨 Plasma 6.4+ (Original layout, SVG icons)"
    echo ""
    
    while true; do
        read -p "Enter choice (1-4): " choice
        
        case $choice in
            1)
                detect_plasma_version
                local detected=$?
                
                if [ $detected -eq 64 ]; then
                    PLASMA_VERSION="6.4"
                    echo "[+] Auto-detected: Plasma 6.4+ (will use SVG icons)"
                elif [ $detected -eq 60 ]; then
                    PLASMA_VERSION="6.0"
                    echo "[+] Auto-detected: Plasma 6.0-6.3 (will use Unicode symbols)"
                else
                    PLASMA_VERSION="5"
                    echo "[+] Auto-detected: Plasma 5.x"
                fi
                break
                ;;
            2)
                PLASMA_VERSION="5"
                echo "[+] Selected: Plasma 5.x"
                break
                ;;
            3)
                PLASMA_VERSION="6.0"
                echo "[+] Selected: Plasma 6.0-6.3 (Unicode symbols)"
                break
                ;;
            4)
                PLASMA_VERSION="6.4"
                echo "[+] Selected: Plasma 6.4+ (SVG icons)"
                break
                ;;
            *)
                echo "❌ Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
    
    return 0
}

# Main installation starts here
echo "🎵 Global Player v3.2.3 Installation"
echo "====================================="

# Check if preset directory exists
if [ ! -d "$PRESETS_DIR" ]; then
    echo "❌ Error: Global-Player-presets directory not found!"
    echo "   Expected: $PRESETS_DIR"
    exit 1
fi

# Let user choose Plasma version
select_plasma_version

# Select station preset
select_station_preset

echo ""
echo "[+] Installing dependencies (you may need sudo):"
if [ "$PLASMA_VERSION" = "6.4" ] || [ "$PLASMA_VERSION" = "6.0" ]; then
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus-qt6 python3-dbus python3-gi python3-requests python3-pyqt6.qtwebengine"
    echo "                   sudo apt install python3-dbus python3-gi"
    echo "    Arch:          sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt6-webengine"
    echo "                   sudo pacman -S python-dbus python-gobject"
    echo "    Fedora:        sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-pyqt6-webengine"
    echo "                   sudo dnf install python3-dbus python3-gobject"
else
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt5-tools python-dbus python-gobject python-requests python-pyqt5-webengine"  
    echo "    Fedora:        sudo dnf install mpv qt5-qttools python3-dbus python3-gobject python3-requests python3-pyqt5-webengine"
fi

echo ""
echo "[+] Installing plasmoid to ${PLASMOID_DST}"
mkdir -p "${PLASMOID_DST}/contents/ui"

# Install daemon files
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
fi

# Install appropriate QML and metadata based on Plasma version
echo "[+] Installing Plasma ${PLASMA_VERSION} files..."

if [ "$PLASMA_VERSION" = "6.4" ]; then
    # Plasma 6.4+ with SVG icons
    
    if [ -f "$(dirname "$0")/plasma6_4_main.qml" ]; then
        cp -f "$(dirname "$0")/plasma6_4_main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
        echo "    ✓ Plasma 6.4 QML (SVG icons) installed"
    else
        echo "❌ Error: plasma6_4_main.qml not found!"
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
    
elif [ "$PLASMA_VERSION" = "6.0" ]; then
    # Plasma 6.0-6.3 with Unicode symbols (original)
    
    if [ -f "$(dirname "$0")/plasma6_main_qml" ]; then
        cp -f "$(dirname "$0")/plasma6_main_qml" "${PLASMOID_DST}/contents/ui/main.qml"
        echo "    ✓ Plasma 6.0 QML (Unicode symbols) installed"
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
    # Plasma 5.x
    
    if [ -f "$(dirname "$0")/plasma5_main_qml" ]; then
        cp -f "$(dirname "$0")/plasma5_main_qml" "${PLASMOID_DST}/contents/ui/main.qml"
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
    
    systemctl --user stop gpd.service 2>/dev/null || true
    systemctl --user enable gpd.service || true
    systemctl --user start gpd.service || true
    
    echo "    ✓ Service installed and started"
    
    sleep 2
    if systemctl --user is-active gpd.service >/dev/null 2>&1; then
        echo "    ✓ Service is running"
    else
        echo "    ⚠️  Service may have failed to start"
    fi
fi

# Test D-Bus connection
echo "[+] Testing D-Bus connection..."
sleep 2

# Try qdbus first, fall back to Python if not available
if command -v qdbus >/dev/null 2>&1 && qdbus org.mooheda.gpd /org/mooheda/gpd >/dev/null 2>&1; then
    echo "    ✓ D-Bus connection successful (via qdbus)"
    STATIONS_JSON=$(qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1.GetStations 2>/dev/null || echo "[]")
    STATION_COUNT=$(echo "$STATIONS_JSON" | python3 -c "import sys, json; print(len(json.loads(sys.stdin.read())))" 2>/dev/null || echo "0")
    echo "    ✓ Found $STATION_COUNT stations via D-Bus"
else
    # Fallback to Python D-Bus
    DBUS_TEST=$(python3 << 'PYEOF' 2>/dev/null
import dbus
import json
try:
    bus = dbus.SessionBus()
    obj = bus.get_object('org.mooheda.gpd', '/org/mooheda/gpd')
    iface = dbus.Interface(obj, 'org.mooheda.gpd1')
    stations_str = iface.GetStations()
    stations = json.loads(str(stations_str))
    print(f"SUCCESS:{len(stations)}")
except Exception as e:
    print(f"FAILED:{e}")
PYEOF
)
    
    if echo "$DBUS_TEST" | grep -q "SUCCESS:"; then
        STATION_COUNT=$(echo "$DBUS_TEST" | grep -oP 'SUCCESS:\K\d+')
        echo "    ✓ D-Bus connection successful (via Python)"
        echo "    ✓ Found $STATION_COUNT stations via D-Bus"
    else
        echo "    ⚠️  D-Bus connection failed"
        echo "    Note: qdbus not available, using Python D-Bus"
    fi
fi

# Clear caches
echo "[+] Clearing caches..."
rm -rf ~/.cache/plasma* ~/.cache/plasmashell ~/.cache/krunner 2>/dev/null || true
echo "    ✓ Cleared Plasma caches"

# Restart Plasma
echo "[+] Restarting Plasma..."
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
    systemctl --user restart plasma-plasmashell.service
elif command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
elif command -v kquitapp5 >/dev/null 2>&1; then
    kquitapp5 plasmashell || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
else
    pkill plasmashell 2>/dev/null || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
fi

echo "✅ Plasma restarted!"

echo ""
echo "✅ Global Player v3.2.3 installation complete!"
echo ""
echo "📋 Installation Summary:"
echo "   • Plasma Version: ${PLASMA_VERSION}"
if [ "$PLASMA_VERSION" = "6.4" ]; then
    echo "   • UI Style: Original layout with SVG icons"
elif [ "$PLASMA_VERSION" = "6.0" ]; then
    echo "   • UI Style: Original layout with Unicode symbols"
fi
echo "   • Stations: $PRESET_NAME"
echo "   • Widget: ${PLASMOID_DST}"
echo "   • Daemon: ${DAEMON_DST}"
echo ""
echo "🎯 Next Steps:"
echo "   1. Wait 10-15 seconds for Plasma to reload"
echo "   2. Right-click panel → Add Widgets → 'Global Player'"
echo ""
