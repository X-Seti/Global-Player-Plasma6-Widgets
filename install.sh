#!/usr/bin/env bash
# X-Seti - Sept 15 2025 - GlobalPlayer 3.2.2 - v5/v6 folder structure support
set -euo pipefail

PLASMOID_ID="org.mooheda.globalplayer"
PLASMOID_SRC="$(dirname "$0")/${PLASMOID_ID}"
PLASMOID_DST="${HOME}/.local/share/plasma/plasmoids/${PLASMOID_ID}"

DAEMON_SRC="$(dirname "$0")/globalplayer-daemon"
DAEMON_DST="${HOME}/globalplayer-daemon"

# Detect Plasma version
PLASMA_VERSION=""
if command -v kquitapp6 >/dev/null 2>&1; then
    PLASMA_VERSION="6"
elif command -v kquitapp5 >/dev/null 2>&1; then
    PLASMA_VERSION="5"
else
    echo "Warning: Could not detect Plasma version. Checking for plasmashell..."
    if command -v plasmashell >/dev/null 2>&1; then
        PLASMA_VERSION="5"  # Default to 5 if uncertain
    else
        echo "Error: No Plasma installation detected!"
        exit 1
    fi
fi

echo "[+] Detected Plasma ${PLASMA_VERSION}"

echo "[+] Installing dependencies (you may need sudo):"
if [ "$PLASMA_VERSION" = "6" ]; then
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt6.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt6-tools python-dbus python-gobject python-requests python-pyqt6-webengine"
    echo "    Fedora:        sudo dnf install mpv qt6-qttools python3-dbus python3-gobject python3-requests python3-pyqt6-webengine"
else
    echo "    Debian/Ubuntu: sudo apt install mpv qdbus python3-dbus python3-gi python3-requests python3-pyqt5.qtwebengine"
    echo "    Arch:          sudo pacman -S mpv qt5-tools python-dbus python-gobject python-requests python-pyqt5-webengine"  
    echo "    Fedora:        sudo dnf install mpv qt5-qttools python3-dbus python3-gobject python3-requests python3-pyqt5-webengine"
fi

echo "[+] Installing plasmoid to ${PLASMOID_DST}"
mkdir -p "${PLASMOID_DST}"

# Create base plasmoid structure if needed
mkdir -p "${PLASMOID_DST}/contents/ui"

# Copy version-specific files based on v5/v6 folder structure
V5_DIR="$(dirname "$0")/${PLASMOID_ID}/v5"
V6_DIR="$(dirname "$0")/${PLASMOID_ID}/v6"

if [ "$PLASMA_VERSION" = "6" ]; then
    echo "[+] Using Plasma 6 files from v6/ folder"
    
    # Copy v6 metadata
    if [ -f "${V6_DIR}/metadata.json" ]; then
        echo "    → Copying v6/metadata.json"
        cp "${V6_DIR}/metadata.json" "${PLASMOID_DST}/metadata.json"
    elif [ -f "${V6_DIR}/metadata.desktop" ]; then
        echo "    → Copying v6/metadata.desktop"
        cp "${V6_DIR}/metadata.desktop" "${PLASMOID_DST}/metadata.desktop"
    fi
    
    # Copy v6 QML file
    if [ -f "${V6_DIR}/main.qml" ]; then
        echo "    → Copying v6/main.qml"
        cp "${V6_DIR}/main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    elif [ -f "${V6_DIR}/contents/ui/main.qml" ]; then
        echo "    → Copying v6/contents/ui/main.qml"
        cp "${V6_DIR}/contents/ui/main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    else
        echo "    → Using fallback Plasma 6 QML"
        # Use existing QML files as fallback
        if [ -f "$(dirname "$0")/main-plasma6.qml" ]; then
            cp "$(dirname "$0")/main-plasma6.qml" "${PLASMOID_DST}/contents/ui/main.qml"
        elif [ -f "$(dirname "$0")/main.qml" ]; then
            cp "$(dirname "$0")/main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
        fi
    fi
    
else
    echo "[+] Using Plasma 5 files from v5/ folder"
    
    # Copy v5 metadata
    if [ -f "${V5_DIR}/metadata.desktop" ]; then
        echo "    → Copying v5/metadata.desktop"
        cp "${V5_DIR}/metadata.desktop" "${PLASMOID_DST}/metadata.desktop"
    else
        echo "    → Creating Plasma 5 metadata.desktop"
        cat > "${PLASMOID_DST}/metadata.desktop" << 'EOF'
[Desktop Entry]
Name=Global Player
Comment=Listen to Global Player radio stations (Heart, Capital, Classic FM, etc.)
Icon=audio-headphones
Type=Service
ServiceTypes=Plasma/Applet

X-KDE-PluginInfo-Author=X-Seti (Mooheda)
X-KDE-PluginInfo-Email=
X-KDE-PluginInfo-Name=org.mooheda.globalplayer
X-KDE-PluginInfo-Version=3.2.2
X-KDE-PluginInfo-Category=Multimedia
X-KDE-PluginInfo-Depends=
X-KDE-PluginInfo-License=GPL
X-KDE-PluginInfo-EnabledByDefault=true

X-Plasma-API=declarativeappletscript
X-Plasma-MainScript=ui/main.qml
X-KDE-ServiceTypes=Plasma/Applet
X-Plasma-DefaultSize=200,200
EOF
    fi
    
    # Copy v5 QML file
    if [ -f "${V5_DIR}/main.qml" ]; then
        echo "    → Copying v5/main.qml"
        cp "${V5_DIR}/main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    elif [ -f "${V5_DIR}/contents/ui/main.qml" ]; then
        echo "    → Copying v5/contents/ui/main.qml"
        cp "${V5_DIR}/contents/ui/main.qml" "${PLASMOID_DST}/contents/ui/main.qml"
    else
        echo "    → Creating Plasma 5 compatible main.qml"
        # Create the complete Plasma 5 QML file
        cat > "${PLASMOID_DST}/contents/ui/main.qml" << 'EOF'
// X-Seti - Sept 15 2025 - GlobalPlayer - Plasma 5 Compatible 3.2.2
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: root

    Plasmoid.toolTipMainText: ""
    Plasmoid.toolTipSubText: ""
    Plasmoid.status: isPlaying ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    
    property var stationsModel: []
    property int stationIndex: 0
    property string selectedStation: {
        if (stationsModel.length === 0) return ""
        if (stationIndex < 0 || stationIndex >= stationsModel.length) return ""
        return stationsModel[stationIndex]
    }
    property string nowArtist: ""
    property string nowTitle: ""
    property string nowShow: ""
    property string playState: "Stopped"
    property bool loggingEnabled: false
    property bool pushNotifications: false
    property url artworkUrl: ""
    property string lastNotifiedTrack: ""

    property string displayTitle: {
        if (nowArtist && nowTitle) {
            return nowArtist + " — " + nowTitle
        } else if (nowTitle) {
            return nowTitle
        } else if (selectedStation) {
            return selectedStation
        } else {
            return "Global Player"
        }
    }

    property bool isPlaying: playState === "Playing"

    Plasmoid.switchWidth: PlasmaCore.Units.gridUnit * 20
    Plasmoid.switchHeight: PlasmaCore.Units.gridUnit * 25

    function sendTrackNotification() {
        var trackInfo = displayTitle
        if (trackInfo && trackInfo !== "Global Player" && trackInfo !== lastNotifiedTrack) {
            lastNotifiedTrack = trackInfo
            execDS.connectSource("kdialog --title 'Global Player' --passivepopup '" + trackInfo + "' 3")
        }
    }

    function qdbusCall(method, args) {
        var cmd = "qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd." + method
        if (args && args.length > 0) {
            cmd += " " + args.join(" ")
        }
        execDS.connectSource(cmd)
    }

    function refreshStations() {
        execDS.connectSource("qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd.GetStations")
    }

    function playCurrent() {
        if (selectedStation) {
            qdbusCall("PlayStation", ['"' + selectedStation + '"'])
        }
    }

    function togglePlayPause() {
        if (isPlaying) {
            qdbusCall("Stop", [])
        } else {
            playCurrent()
        }
    }

    function nextStation() {
        if (stationsModel.length > 1) {
            stationIndex = (stationIndex + 1) % stationsModel.length
            playCurrent()
        }
    }

    function prevStation() {
        if (stationsModel.length > 1) {
            stationIndex = (stationIndex - 1 + stationsModel.length) % stationsModel.length
            playCurrent()
        }
    }

    function signIn() {
        qdbusCall("SignIn", [])
    }

    function getNowPlaying() {
        execDS.connectSource("qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd.GetNowPlaying")
    }

    Component.onCompleted: {
        refreshStations()
        getNowPlaying()
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: getNowPlaying()
    }

    PlasmaExtras.DataSource {
        id: execDS
        engine: "executable"

        onNewData: function(sourceName, data) {
            var out = (data["stdout"] || "").trim()
            var err = (data["stderr"] || "").trim()

            if (err) {
                console.log("Command error:", err)
            }

            if (sourceName.indexOf("GetNowPlaying") !== -1) {
                try {
                    var m = JSON.parse(out)
                    var newArtist = m.artist || ""
                    var newTitle = m.title || ""
                    var newShow = m.show || ""
                    var newState = m.state || playState
                    var newArtworkPath = m.artworkPath || ""

                    var newTrackId = newArtist + "|" + newTitle
                    var trackChanged = (newTrackId !== lastNotifiedTrack) && newTrackId !== "|" && newState === "Playing"

                    nowArtist = newArtist
                    nowTitle = newTitle
                    nowShow = newShow
                    playState = newState

                    if (newArtworkPath) {
                        artworkUrl = "file://" + newArtworkPath
                    } else {
                        artworkUrl = ""
                    }

                    if (trackChanged && pushNotifications) {
                        sendTrackNotification()
                    }

                    lastNotifiedTrack = newTrackId
                } catch (e) {
                    console.log("JSON parse error:", e)
                }
            } else if (sourceName.indexOf("GetStations") !== -1) {
                try {
                    var stations = JSON.parse(out)
                    stationsModel = stations || []
                    
                    if (selectedStation) {
                        var idx = stationsModel.indexOf(selectedStation)
                        if (idx !== -1) {
                            stationIndex = idx
                        }
                    }
                } catch (e) {
                    console.log("Stations JSON parse error:", e)
                }
            }

            disconnectSource(sourceName)
        }
    }

    compactRepresentation: Item {
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 2
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 2

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: PlasmaCore.Units.smallSpacing
            border.color: PlasmaCore.Theme.textColor
            border.width: 1
            color: "transparent"

            Image {
                anchors.fill: parent
                anchors.margins: 2
                fillMode: Image.PreserveAspectFit
                source: artworkUrl
                visible: artworkUrl !== ""
            }

            PC3.Label {
                anchors.centerIn: parent
                text: "♪"
                opacity: 0.4
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 2
                visible: artworkUrl === ""
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: PlasmaCore.Units.smallSpacing
                height: PlasmaCore.Units.smallSpacing
                radius: width / 2
                color: isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.neutralTextColor
                opacity: 0.8
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    plasmoid.expanded = !plasmoid.expanded
                } else if (mouse.button === Qt.RightButton) {
                    contextMenu.open()
                }
            }

            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) {
                    prevStation()
                } else {
                    nextStation()
                }
                wheel.accepted = true
            }
        }

        PC3.Menu {
            id: contextMenu

            PC3.MenuItem {
                text: isPlaying ? "◼ Stop" : "▶ Play"
                onClicked: togglePlayPause()
            }

            PC3.MenuSeparator {}

            PC3.MenuItem {
                text: "◀ Previous"
                onClicked: prevStation()
                enabled: stationsModel.length > 1
            }

            PC3.MenuItem {
                text: "Next ▶"
                onClicked: nextStation()
                enabled: stationsModel.length > 1
            }

            PC3.MenuSeparator {}

            Repeater {
                model: Math.min(stationsModel.length, 8)
                delegate: PC3.MenuItem {
                    text: stationsModel[index]
                    checkable: true
                    checked: index === stationIndex
                    onClicked: {
                        stationIndex = index
                        playCurrent()
                    }
                }
            }

            PC3.MenuSeparator {}

            PC3.MenuItem {
                text: "↻ Refresh"
                onClicked: refreshStations()
            }

            PC3.MenuItem {
                text: "Sign In"
                onClicked: signIn()
            }
        }
    }

    Plasmoid.fullRepresentation: Item {
        id: fullRoot
        
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 20
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 25

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: PlasmaCore.Units.largeSpacing
            spacing: PlasmaCore.Units.largeSpacing

            RowLayout {
                Layout.fillWidth: true
                
                PC3.Label {
                    text: "Global Player"
                    font.bold: true
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                    Layout.fillWidth: true
                }
                
                PC3.Button {
                    text: "Sign In"
                    onClicked: signIn()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: PlasmaCore.Units.largeSpacing

                Rectangle {
                    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 5
                    Layout.preferredHeight: PlasmaCore.Units.gridUnit * 5
                    radius: PlasmaCore.Units.smallSpacing
                    border.color: PlasmaCore.Theme.textColor
                    border.width: 1
                    color: PlasmaCore.Theme.backgroundColor

                    Image {
                        anchors.fill: parent
                        anchors.margins: 4
                        fillMode: Image.PreserveAspectFit
                        source: artworkUrl
                        visible: artworkUrl !== ""
                    }

                    PC3.Label {
                        anchors.centerIn: parent
                        text: "♪"
                        opacity: 0.4
                        font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 3
                        visible: artworkUrl === ""
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: PlasmaCore.Units.smallSpacing

                    PC3.Label {
                        Layout.fillWidth: true
                        text: displayTitle
                        wrapMode: Text.WordWrap
                        font.weight: Font.Medium
                        font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.1
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: nowShow ? ("Show: " + nowShow) : ""
                        wrapMode: Text.WordWrap
                        opacity: 0.8
                        visible: nowShow !== ""
                    }

                    PC3.Label {
                        Layout.fillWidth: true
                        text: "Status: " + playState
                        opacity: 0.7
                        font.pointSize: PlasmaCore.Theme.smallFont.pointSize
                    }
                }
            }

            PC3.ComboBox {
                id: stationPicker
                Layout.fillWidth: true
                model: stationsModel
                currentIndex: stationIndex
                onActivated: {
                    stationIndex = currentIndex
                    playCurrent()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                spacing: PlasmaCore.Units.largeSpacing

                PC3.Button {
                    text: "◀"
                    onClicked: prevStation()
                    enabled: stationsModel.length > 1
                }

                PC3.Button {
                    text: isPlaying ? "◼" : "▶"
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.5
                    onClicked: togglePlayPause()
                    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 3
                }

                PC3.Button {
                    text: "▶"
                    onClicked: nextStation()
                    enabled: stationsModel.length > 1
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: PlasmaCore.Units.smallSpacing

                PC3.CheckBox {
                    text: "Enable logging to ~/globalplayer/gp.logs"
                    checked: loggingEnabled
                    onToggled: qdbusCall("SetLogging", [checked ? "true" : "false"])
                }

                PC3.CheckBox {
                    text: "Push notifications for track changes"
                    checked: pushNotifications
                    onToggled: {
                        pushNotifications = checked
                        qdbusCall("SetNotifications", [checked ? "true" : "false"])
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                PC3.Button {
                    text: "↻"
                    onClicked: refreshStations()
                    PC3.ToolTip.text: "Refresh station list"
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
EOF
    fi
fi

# Copy any additional files from version-specific folders
if [ "$PLASMA_VERSION" = "6" ] && [ -d "${V6_DIR}" ]; then
    echo "[+] Copying additional v6 files..."
    # Copy any other files in v6 directory (like icons, etc.)
    find "${V6_DIR}" -type f ! -name "*.qml" ! -name "metadata.*" -exec cp {} "${PLASMOID_DST}/" \; 2>/dev/null || true
elif [ "$PLASMA_VERSION" = "5" ] && [ -d "${V5_DIR}" ]; then
    echo "[+] Copying additional v5 files..."
    # Copy any other files in v5 directory
    find "${V5_DIR}" -type f ! -name "*.qml" ! -name "metadata.*" -exec cp {} "${PLASMOID_DST}/" \; 2>/dev/null || true
fi

echo "[+] Installing daemon to ${DAEMON_DST}"
mkdir -p "${DAEMON_DST}"
if [ -d "${DAEMON_SRC}" ]; then
    rsync -a --delete "${DAEMON_SRC}/" "${DAEMON_DST}/"
else
    echo "Warning: Daemon source directory ${DAEMON_SRC} not found!"
    echo "You may need to install the daemon separately."
fi

echo "[+] Installing systemd --user service"
mkdir -p "${HOME}/.config/systemd/user"
if [ -f "$(dirname "$0")/gpd.service" ]; then
    cp "$(dirname "$0")/gpd.service" "${HOME}/.config/systemd/user/gpd.service"
    systemctl --user daemon-reload || true
    systemctl --user enable --now gpd.service || true
else
    echo "Warning: gpd.service file not found!"
fi

echo "[+] Restarting Plasma"
if systemctl --user is-active plasma-plasmashell.service >/dev/null 2>&1; then
    systemctl --user restart plasma-plasmashell.service
elif command -v kquitapp6 >/dev/null 2>&1; then
    kquitapp6 plasmashell || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
else
    pkill plasmashell 2>/dev/null || true
    sleep 2
    nohup plasmashell > /dev/null 2>&1 &
fi

echo ""
echo "✅ Global Player v3.2.2 installed successfully for Plasma ${PLASMA_VERSION}!"
echo ""
echo "📁 Used files from: ${PLASMOID_ID}/v${PLASMA_VERSION}/"
echo ""
echo "📋 Next steps:"
echo "   1. Add widget: Right-click panel → Add Widget → Search 'Global Player'"
echo "   2. Optional: Click 'Sign In' for premium features"
echo ""
echo "🔧 Troubleshooting:"
echo "   • Service status: systemctl --user status gpd.service"
echo "   • View logs: journalctl --user -u gpd.service -f"
echo "   • Restart Plasma: systemctl --user restart plasma-plasmashell.service"