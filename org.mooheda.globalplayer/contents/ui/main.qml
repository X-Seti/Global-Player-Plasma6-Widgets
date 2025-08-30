// X-Seti - Aug12 2025 - GlobalPlayer - Plasma 6 Compatible 3.2.1
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as Plasma5Support

PlasmoidItem {
    id: root

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

    // Computed properties for display
    property string displayTitle: {
        if (nowArtist && nowTitle) {
            return nowArtist + " – " + nowTitle
        } else if (nowTitle) {
            return nowTitle
        } else if (selectedStation) {
            return selectedStation
        } else {
            return "Global Player"
        }
    }

    property bool isPlaying: playState === "Playing"

    // Poll metadata every 10s
    Timer {
        id: pollTimer
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            getNowPlaying()
        }
    }

    Plasma5Support.DataSource {
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
                    nowArtist = m.artist || ""
                    nowTitle = m.title || ""
                    nowShow = m.show || ""
                    playState = m.state || playState
                    if (m.artworkPath) {
                        artworkUrl = "file://" + m.artworkPath
                    }
                } catch (e) {
                    console.log("Error parsing GetNowPlaying:", e)
                }
            } else if (sourceName.indexOf("GetState") !== -1) {
                try {
                    var s = JSON.parse(out)
                    playState = s.state || playState
                    loggingEnabled = s.logging === true
                    pushNotifications = s.notifications === true
                    var st = s.station || ""
                    if (st.length > 0 && stationsModel.indexOf(st) >= 0) {
                        stationIndex = stationsModel.indexOf(st)
                    }
                } catch (e) {
                    console.log("Error parsing GetState:", e)
                }
            } else if (sourceName.indexOf("GetStations") !== -1) {
                try {
                    var arr = JSON.parse(out)
                    stationsModel = arr
                    if (arr.length > 0 && stationIndex >= arr.length) {
                        stationIndex = 0
                    }
                } catch (e) {
                    console.log("Error parsing GetStations:", e)
                }
            }
            disconnectSource(sourceName)
        }
    }

    function qdbusCall(method, args) {
        var cmd = "qdbus org.mooheda.gpd /org/mooheda/gpd org.mooheda.gpd1." + method
        if (args && args.length > 0) {
            for (var i = 0; i < args.length; ++i) {
                var a = ("" + args[i]).replace(/\"/g, "\\\"")
                cmd += " \"" + a + "\""
            }
        }
        execDS.connectSource(cmd)
    }

    function getNowPlaying() {
        qdbusCall("GetNowPlaying", [])
    }

    function getState() {
        qdbusCall("GetState", [])
    }

    function refreshStations() {
        qdbusCall("GetStations", [])
    }

    function signIn() {
        qdbusCall("SignIn", [])
    }

    function togglePlayPause() {
        if (isPlaying) {
            qdbusCall("Pause", [])
        } else {
            playCurrent()
        }
    }

    function playCurrent() {
        if (stationsModel.length === 0) return
        if (stationIndex < 0 || stationIndex >= stationsModel.length) {
            stationIndex = 0
        }
        selectedStation = stationsModel[stationIndex]
        qdbusCall("Play", [selectedStation])
        if (!pollTimer.running) {
            pollTimer.start()
        }
        getState()
        getNowPlaying()
    }

    function nextStation() {
        if (stationsModel.length === 0) return
        stationIndex = (stationIndex + 1) % stationsModel.length
        playCurrent()
    }

    function prevStation() {
        if (stationsModel.length === 0) return
        stationIndex = (stationIndex - 1 + stationsModel.length) % stationsModel.length
        playCurrent()
    }

    Component.onCompleted: {
        refreshStations()
        getState()
        pollTimer.start()
    }

    // Full widget representation - simplified popup
    fullRepresentation: ColumnLayout {
        anchors.fill: parent
        anchors.margins: PlasmaCore.Units.largeSpacing
        spacing: PlasmaCore.Units.largeSpacing

        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 40
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 30

        // Large artwork display
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: PlasmaCore.Units.gridUnit * 8
            height: PlasmaCore.Units.gridUnit * 8
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
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 4
                visible: artworkUrl === ""
            }
        }

        // Title/Station name
        PC3.Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            text: displayTitle
            wrapMode: Text.WordWrap
            font.weight: Font.Medium
            font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        // Station selector dropdown
        PC3.ComboBox {
            id: stationPicker
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: PlasmaCore.Units.gridUnit * 16
            model: stationsModel
            currentIndex: stationIndex
            onActivated: {
                stationIndex = currentIndex
                playCurrent()
            }
        }

        // Play/Stop controls
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: PlasmaCore.Units.largeSpacing

            PC3.Button {
                text: "<"
                onClicked: prevStation()
                enabled: stationsModel.length > 1
            }

            PC3.Button {
                text: isPlaying ? "◼" : "⫸"
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.5
                onClicked: togglePlayPause()
            }

            PC3.Button {
                text: ">"
                onClicked: nextStation()
                enabled: stationsModel.length > 1
            }
        }

        // Settings checkboxes
        ColumnLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.smallSpacing

            PC3.CheckBox {
                text: "Enable logging"
                checked: loggingEnabled
                onToggled: qdbusCall("SetLogging", [checked ? "true" : "false"])
            }

            PC3.CheckBox {
                text: "Push notifications"
                checked: pushNotifications
                onToggled: qdbusCall("SetNotifications", [checked ? "true" : "false"])
            }
        }

        // Status and additional controls
        RowLayout {
            Layout.fillWidth: true

            PC3.Label {
                text: playState
                opacity: 0.7
                Layout.fillWidth: true
            }

            PC3.Button {
                text: "↻"
                onClicked: refreshStations()
                PC3.ToolTip.text: "Refresh stations"
            }

            PC3.Button {
                text: "Sign In"
                onClicked: signIn()
            }
        }
    }

    // Compact panel representation - artwork only
    compactRepresentation: Item {
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 2
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 2

        // Main artwork display
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
                opacity: 0.6
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                visible: artworkUrl === ""
            }

            // Play/pause indicator overlay
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 1
                width: 8
                height: 8
                radius: 4
                color: isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.neutralTextColor
                opacity: 0.8
            }
        }

        // Click handler to open popup
        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
            hoverEnabled: true

            // Tooltip on hover
            PC3.ToolTip {
                text: {
                    var tooltip = displayTitle
                    if (nowShow && nowShow !== "") {
                        tooltip += "\nShow: " + nowShow
                    }
                    tooltip += "\nStatus: " + playState
                    return tooltip
                }
                visible: parent.containsMouse && !root.expanded
                delay: 500
            }
        }

        // Context menu for right-click
        PC3.Menu {
            id: contextMenu

            PC3.MenuItem {
                text: isPlaying ? "◼ Stop" : "⫸ Play"
                onTriggered: togglePlayPause()
            }

            PC3.MenuSeparator {}

            PC3.MenuItem {
                text: "< Previous Station"
                onTriggered: prevStation()
                enabled: stationsModel.length > 1
            }

            PC3.MenuItem {
                text: "Next Station >"
                onTriggered: nextStation()
                enabled: stationsModel.length > 1
            }

            PC3.MenuSeparator {}

            Repeater {
                model: Math.min(stationsModel.length, 8) // Limit menu items
                delegate: PC3.MenuItem {
                    text: stationsModel[index]
                    checkable: true
                    checked: index === stationIndex
                    onTriggered: {
                        stationIndex = index
                        playCurrent()
                    }
                }
            }

            PC3.MenuSeparator {}

            PC3.MenuItem {
                text: loggingEnabled ? "✓ Logging" : "Logging"
                checkable: true
                checked: loggingEnabled
                onTriggered: qdbusCall("SetLogging", [(!loggingEnabled).toString()])
            }

            PC3.MenuItem {
                text: pushNotifications ? "✓ Notifications" : "Notifications"
                checkable: true
                checked: pushNotifications
                onTriggered: qdbusCall("SetNotifications", [(!pushNotifications).toString()])
            }

            PC3.MenuSeparator {}

            PC3.MenuItem {
                text: "↻ Refresh"
                onTriggered: refreshStations()
            }

            PC3.MenuItem {
                text: "Sign In"
                onTriggered: signIn()
            }
        }

        // Right-click context menu
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: contextMenu.open()
        }
    }
}
