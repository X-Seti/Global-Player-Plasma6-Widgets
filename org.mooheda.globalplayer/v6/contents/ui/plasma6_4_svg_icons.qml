// X-Seti - Oct 2025 - Global Player - Plasma 6.4 with SVG Icons
// Maintains original Plasma 6 layout but uses SVG icons instead of Unicode symbols
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    // D-Bus integrated state
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
    property bool daemonConnected: false
    property string errorMessage: ""

    // UI state
    property bool mediaMode: false
    property bool isPlaying: playState === "Playing"
    
    // Computed properties for display
    property string displayTitle: {
        if (nowArtist && nowTitle) {
            return nowArtist + " — " + nowTitle
        } else if (nowTitle) {
            return nowTitle
        } else if (selectedStation) {
            return selectedStation
        } else if (!daemonConnected) {
            return "Connecting..."
        } else {
            return "Global Player"
        }
    }

    property string nowPlaying: {
        if (nowArtist && nowTitle) {
            return nowArtist + " - " + nowTitle
        } else if (nowTitle) {
            return nowTitle
        } else if (!daemonConnected) {
            return "Waiting for daemon..."
        } else {
            return "Select a station"
        }
    }

    // Song history
    property var playedSongs: []
    
    // Tooltip
    toolTipSubText: {
        if (!daemonConnected) {
            return "Daemon not connected"
        } else if (playState === "Playing" && selectedStation) {
            return "Playing: " + selectedStation
        } else {
            return playState
        }
    }

    // Song history model
    ListModel {
        id: playedSongsModel
    }

    // Startup connection timer
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
            } else if (daemonConnected || attempts >= 10) {
                running = false
            }
        }
    }

    // Poll metadata timer
    Timer {
        id: pollTimer
        interval: 10000
        running: daemonConnected && !mediaMode
        repeat: true
        onTriggered: {
            if (daemonConnected) {
                getNowPlaying()
            }
        }
    }

    // D-Bus Data Source
    Plasma5Support.DataSource {
        id: execDS
        engine: "executable"

        onNewData: function(sourceName, data) {
            var out = (data["stdout"] || "").trim()
            var err = (data["stderr"] || "").trim()

            if (err) {
                console.log("Command error:", err)
                if (err.indexOf("not find") !== -1 || err.indexOf("not available") !== -1) {
                    daemonConnected = false
                }
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
                    } else {
                        artworkUrl = ""
                    }

                    if (!mediaMode && (nowArtist || nowTitle)) {
                        addToHistory(nowTitle, nowArtist)
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
                    daemonConnected = true
                } catch (e) {
                    console.log("Error parsing GetState:", e)
                }
            } else if (sourceName.indexOf("GetStations") !== -1) {
                try {
                    var arr = JSON.parse(out)
                    if (arr && arr.length > 0) {
                        stationsModel = arr
                        console.log("Loaded", arr.length, "stations")
                        if (arr.length > 0 && stationIndex >= arr.length) {
                            stationIndex = 0
                        }
                        daemonConnected = true
                        errorMessage = ""
                    }
                } catch (e) {
                    console.log("Error parsing GetStations:", e)
                }
            }
            disconnectSource(sourceName)
        }
    }

    // D-Bus helper functions
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

    function testDaemonConnection() {
        qdbusCall("GetState", [])
    }

    function getNowPlaying() {
        if (!mediaMode && daemonConnected) {
            qdbusCall("GetNowPlaying", [])
        }
    }

    function getState() {
        if (daemonConnected) {
            qdbusCall("GetState", [])
        }
    }

    function refreshStations() {
        if (!mediaMode) {
            qdbusCall("GetStations", [])
        }
    }

    function signIn() {
        if (!mediaMode) {
            qdbusCall("SignIn", [])
        }
    }

    // Control functions
    function togglePlay() {
        if (!daemonConnected) {
            errorMessage = "Daemon not connected"
            return
        }
        
        if (mediaMode) {
            isPlaying = !isPlaying
        } else {
            if (isPlaying) {
                qdbusCall("Pause", [])
            } else {
                playCurrent()
            }
        }
    }

    function playCurrent() {
        if (!daemonConnected) return
        
        if (mediaMode) {
            playState = "Playing"
        } else {
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
    }

    function stopPlayback() {
        if (!daemonConnected) return
        
        if (mediaMode) {
            playState = "Stopped"
        } else {
            qdbusCall("Pause", [])
        }
    }

    function nextStation() {
        if (mediaMode) return
        if (stationsModel.length === 0) return
        stationIndex = (stationIndex + 1) % stationsModel.length
        playCurrent()
    }

    function prevStation() {
        if (mediaMode) return
        if (stationsModel.length === 0) return
        stationIndex = (stationIndex - 1 + stationsModel.length) % stationsModel.length
        playCurrent()
    }

    function switchMode() {
        mediaMode = !mediaMode
        
        if (mediaMode) {
            if (playState === "Playing") {
                qdbusCall("Pause", [])
            }
        } else {
            refreshStations()
            getState()
        }
    }

    // History management
    function addToHistory(song, artist) {
        var newSong = {
            "time": new Date().toLocaleTimeString(),
            "song": song || "Unknown Song",
            "artist": artist || "Unknown Artist", 
            "station": mediaMode ? "Local Media" : selectedStation
        }
        
        if (playedSongs.length > 0) {
            var last = playedSongs[0]
            if (last.song === newSong.song && last.artist === newSong.artist) {
                return
            }
        }
        
        playedSongs.unshift(newSong)
        if (playedSongs.length > 10) {
            playedSongs.pop()
        }
        playedSongsModel.clear()
        for (var i = 0; i < playedSongs.length; i++) {
            playedSongsModel.append(playedSongs[i])
        }
    }

    Component.onCompleted: {
        console.log("Global Player Plasma 6.4 (SVG icons) initializing...")
        addToHistory("Welcome to Global Player", "System")
    }

    // Compact panel representation - ORIGINAL PLASMA 6 LAYOUT with SVG ICONS
    compactRepresentation: Item {
        Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
        Layout.preferredHeight: PlasmaCore.Units.iconSizes.small

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 3
            color: PlasmaCore.Theme.backgroundColor
            border.color: {
                if (!daemonConnected) return PlasmaCore.Theme.negativeTextColor
                return isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.textColor
            }
            border.width: 2

            // Album artwork (same as original)
            Image {
                anchors.fill: parent
                anchors.margins: 3
                fillMode: Image.PreserveAspectFit
                source: artworkUrl
                visible: artworkUrl !== ""
            }

            // SVG ICON (Plasma 6.4) - replaces Unicode music note
            Kirigami.Icon {
                anchors.centerIn: parent
                width: parent.width * 0.6
                height: parent.height * 0.6
                source: {
                    if (!daemonConnected) return "emblem-warning"
                    return mediaMode ? "audio-x-generic" : "radio"
                }
                visible: artworkUrl === ""
            }

            // Playing indicator (same as original)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 1
                width: 6
                height: 6
                radius: 3
                color: {
                    if (!daemonConnected) return PlasmaCore.Theme.negativeTextColor
                    return isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.neutralTextColor
                }
                opacity: 0.9
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    togglePlay()
                } else if (mouse.button === Qt.RightButton) {
                    nextStation()
                } else if (mouse.button === Qt.MiddleButton) {
                    root.expanded = !root.expanded
                }
            }
            
            onPressAndHold: {
                root.expanded = !root.expanded
            }
            
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) {
                    prevStation()
                } else {
                    nextStation()
                }
                wheel.accepted = true
            }

            PC3.ToolTip {
                text: {
                    var tooltip = displayTitle
                    if (errorMessage !== "") {
                        tooltip += "\n⚠️ " + errorMessage
                    }
                    if (nowShow && nowShow !== "") {
                        tooltip += "\nShow: " + nowShow
                    }
                    tooltip += "\nStatus: " + (daemonConnected ? playState : "Disconnected")
                    if (daemonConnected && stationsModel.length > 0) {
                        tooltip += "\nStations: " + stationsModel.length
                    }
                    return tooltip
                }
                visible: parent.containsMouse && !root.expanded
                delay: 500
            }
        }
    }

    // Full widget representation - ORIGINAL PLASMA 6 LAYOUT with SVG ICONS
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 35
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 25

        // Connection status banner (same as original)
        Rectangle {
            visible: !daemonConnected || errorMessage !== ""
            Layout.fillWidth: true
            height: PlasmaCore.Units.gridUnit * 2
            color: PlasmaCore.Theme.negativeBackgroundColor
            radius: PlasmaCore.Units.smallSpacing

            RowLayout {
                anchors.centerIn: parent
                spacing: PlasmaCore.Units.smallSpacing

                Kirigami.Icon {
                    source: "emblem-warning"
                    Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                    Layout.preferredHeight: PlasmaCore.Units.iconSizes.small
                }

                PC3.Label {
                    text: errorMessage !== "" ? errorMessage : "Daemon not connected"
                    color: PlasmaCore.Theme.negativeTextColor
                }

                PC3.Button {
                    text: "Retry"
                    visible: !daemonConnected
                    onClicked: {
                        testDaemonConnection()
                        refreshStations()
                    }
                }
            }
        }

        // Top section - ORIGINAL LAYOUT
        RowLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.largeSpacing

            // Cover art (same as original)
            Rectangle {
                Layout.preferredWidth: PlasmaCore.Units.gridUnit * 8
                Layout.preferredHeight: PlasmaCore.Units.gridUnit * 8
                radius: PlasmaCore.Units.smallSpacing
                color: PlasmaCore.Theme.backgroundColor
                border.color: isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.textColor
                border.width: 2

                Image {
                    anchors.fill: parent
                    anchors.margins: PlasmaCore.Units.smallSpacing
                    source: artworkUrl
                    fillMode: Image.PreserveAspectFit
                    visible: artworkUrl !== ""
                }

                // SVG ICON (Plasma 6.4) - replaces Unicode symbol
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: parent.width * 0.5
                    height: parent.height * 0.5
                    source: mediaMode ? "audio-x-generic" : "radio"
                    visible: artworkUrl === ""
                }
            }

            // Station info and controls - ORIGINAL LAYOUT
            ColumnLayout {
                Layout.fillWidth: true
                spacing: PlasmaCore.Units.smallSpacing

                PC3.Label {
                    text: mediaMode ? "Media Player" : (selectedStation || "No Station Selected")
                    font.bold: true
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.3
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: nowPlaying
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.1
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                // Playback controls - SVG ICONS (Plasma 6.4)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: PlasmaCore.Units.smallSpacing

                    PC3.Button {
                        icon.name: "media-skip-backward"
                        onClicked: prevStation()
                        enabled: daemonConnected && !mediaMode && stationsModel.length > 1
                        PC3.ToolTip.text: "Previous Station"
                        PC3.ToolTip.visible: hovered
                    }

                    PC3.Button {
                        icon.name: isPlaying ? "media-playback-pause" : "media-playback-start"
                        onClicked: togglePlay()
                        enabled: daemonConnected
                        highlighted: isPlaying
                        PC3.ToolTip.text: isPlaying ? "Pause" : "Play"
                        PC3.ToolTip.visible: hovered
                    }

                    PC3.Button {
                        icon.name: "media-playback-stop"
                        onClicked: stopPlayback()
                        enabled: daemonConnected && isPlaying
                        PC3.ToolTip.text: "Stop"
                        PC3.ToolTip.visible: hovered
                    }

                    PC3.Button {
                        icon.name: "media-skip-forward"
                        onClicked: nextStation()
                        enabled: daemonConnected && !mediaMode && stationsModel.length > 1
                        PC3.ToolTip.text: "Next Station"
                        PC3.ToolTip.visible: hovered
                    }
                }

                PC3.Label {
                    visible: stationsModel.length > 0
                    text: "Station " + (stationIndex + 1) + " of " + stationsModel.length
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    opacity: 0.7
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Options row - ORIGINAL LAYOUT with SVG ICONS
        RowLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.smallSpacing

            PC3.CheckBox {
                text: "Logging"
                checked: loggingEnabled
                enabled: daemonConnected
                onToggled: qdbusCall("SetLogging", [checked ? "true" : "false"])
            }

            PC3.CheckBox {
                text: "Notifications"
                checked: pushNotifications
                enabled: daemonConnected
                onToggled: qdbusCall("SetNotifications", [checked ? "true" : "false"])
            }

            Item { Layout.fillWidth: true }

            PC3.Button {
                icon.name: "view-refresh"
                text: "Refresh"
                onClicked: {
                    refreshStations()
                    getState()
                }
                enabled: daemonConnected && !mediaMode
                PC3.ToolTip.text: "Reload station list"
                PC3.ToolTip.visible: hovered
            }

            PC3.Button {
                text: "Sign In"
                onClicked: signIn()
                enabled: daemonConnected && !mediaMode
                visible: !mediaMode
            }
        }

        // Song history - ORIGINAL LAYOUT
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: PlasmaCore.Theme.backgroundColor
            radius: PlasmaCore.Units.smallSpacing
            border.color: PlasmaCore.Theme.textColor
            border.width: 1
            opacity: 0.8

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: PlasmaCore.Units.smallSpacing
                spacing: PlasmaCore.Units.smallSpacing

                PC3.Label {
                    text: mediaMode ? "Media Player" : "Recently Played"
                    font.bold: true
                }

                ScrollView {
                    visible: !mediaMode
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ListView {
                        model: playedSongsModel
                        delegate: RowLayout {
                            width: ListView.view ? ListView.view.width : 0
                            spacing: PlasmaCore.Units.smallSpacing

                            PC3.Label {
                                text: model.time || ""
                                opacity: 0.7
                                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                                Layout.preferredWidth: PlasmaCore.Units.gridUnit * 3
                            }

                            PC3.Label {
                                text: (model.artist || "") + " - " + (model.song || "")
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                            }

                            PC3.Label {
                                text: model.station || ""
                                color: PlasmaCore.Theme.positiveTextColor
                                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                                Layout.preferredWidth: PlasmaCore.Units.gridUnit * 5
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                PC3.Label {
                    visible: mediaMode
                    text: "Media mode - not yet implemented"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    opacity: 0.5
                }
            }
        }
    }
}
