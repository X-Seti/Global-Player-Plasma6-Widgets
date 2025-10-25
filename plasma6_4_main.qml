// X-Seti - Oct 2025 - Global Player - Plasma 6.4 Compatible with Enhanced D-Bus
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

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
        } else if (stationsModel.length === 0) {
            return "No Stations"
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
        } else if (stationsModel.length === 0) {
            return "No stations loaded"
        } else {
            return "Select a station"
        }
    }

    // Song history
    property var playedSongs: []
    
    // Tooltip for panel mode
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

    // Startup connection timer - try multiple times
    Timer {
        id: startupTimer
        interval: 1000
        running: true
        repeat: true
        property int attempts: 0
        
        onTriggered: {
            attempts++
            console.log("Connection attempt", attempts, "/10")
            
            if (!daemonConnected) {
                testDaemonConnection()
                
                if (attempts >= 10) {
                    console.log("Failed to connect to daemon after 10 attempts")
                    errorMessage = "Cannot connect to daemon. Is it running?"
                    running = false
                }
            } else {
                console.log("Daemon connected successfully")
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

            if (sourceName.indexOf("TestConnection") !== -1) {
                if (out || err.indexOf("method") === -1) {
                    daemonConnected = true
                    console.log("Daemon connection verified")
                    // Immediately fetch initial data
                    refreshStations()
                    getState()
                } else {
                    daemonConnected = false
                }
            } else if (sourceName.indexOf("GetNowPlaying") !== -1) {
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

                    // Add to history when in radio mode
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
                    } else {
                        console.log("No stations returned from daemon")
                        errorMessage = "No stations available. Check daemon logs."
                    }
                } catch (e) {
                    console.log("Error parsing GetStations:", e)
                    errorMessage = "Failed to parse station list"
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
        console.log("D-Bus call:", cmd)
        execDS.connectSource(cmd)
    }

    function testDaemonConnection() {
        // Try to call a simple method to test connection
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
        if (!daemonConnected) {
            errorMessage = "Daemon not connected"
            return
        }
        
        if (mediaMode) {
            playState = "Playing"
        } else {
            if (stationsModel.length === 0) {
                errorMessage = "No stations available"
                return
            }
            if (stationIndex < 0 || stationIndex >= stationsModel.length) {
                stationIndex = 0
            }
            selectedStation = stationsModel[stationIndex]
            console.log("Playing station:", selectedStation)
            qdbusCall("Play", [selectedStation])
            if (!pollTimer.running) {
                pollTimer.start()
            }
            getState()
            getNowPlaying()
        }
    }

    function stopPlayback() {
        if (!daemonConnected) {
            return
        }
        
        if (mediaMode) {
            playState = "Stopped"
        } else {
            qdbusCall("Pause", [])
        }
    }

    function nextStation() {
        if (mediaMode) {
            return
        } else {
            if (stationsModel.length === 0) return
            stationIndex = (stationIndex + 1) % stationsModel.length
            playCurrent()
        }
    }

    function prevStation() {
        if (mediaMode) {
            return
        } else {
            if (stationsModel.length === 0) return
            stationIndex = (stationIndex - 1 + stationsModel.length) % stationsModel.length
            playCurrent()
        }
    }

    function switchMode() {
        mediaMode = !mediaMode
        console.log("Switched to", mediaMode ? "Media Player" : "Radio", "mode")
        
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

    // Component initialization
    Component.onCompleted: {
        console.log("Global Player Plasma 6.4 initializing...")
        addToHistory("Starting Global Player", "System")
        // Connection will be attempted by startupTimer
    }

    // Compact panel representation
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

            Image {
                anchors.fill: parent
                anchors.margins: 3
                fillMode: Image.PreserveAspectFit
                source: artworkUrl
                visible: artworkUrl !== ""
            }

            PC3.Label {
                anchors.centerIn: parent
                text: {
                    if (!daemonConnected) return "?"
                    return mediaMode ? "♫" : "♪"
                }
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 0.8
                color: PlasmaCore.Theme.textColor
                visible: artworkUrl === ""
            }

            // Status indicator
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

    // Full widget representation
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 35
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 25

        // Connection status banner
        Rectangle {
            visible: !daemonConnected || errorMessage !== ""
            Layout.fillWidth: true
            height: PlasmaCore.Units.gridUnit * 2
            color: PlasmaCore.Theme.negativeBackgroundColor
            radius: PlasmaCore.Units.smallSpacing

            RowLayout {
                anchors.centerIn: parent
                spacing: PlasmaCore.Units.smallSpacing

                PC3.Label {
                    text: "⚠️"
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                }

                PC3.Label {
                    text: errorMessage !== "" ? errorMessage : "Daemon not connected - check service status"
                    color: PlasmaCore.Theme.negativeTextColor
                }

                PC3.Button {
                    text: "Retry"
                    visible: !daemonConnected
                    onClicked: {
                        console.log("Manual reconnection attempt")
                        testDaemonConnection()
                        refreshStations()
                    }
                }

                PC3.Button {
                    text: "Check Service"
                    onClicked: {
                        execDS.connectSource("konsole -e systemctl --user status gpd.service")
                    }
                }
            }
        }

        // Top section - Cover art and controls
        RowLayout {
            Layout.fillWidth: true
            spacing: PlasmaCore.Units.largeSpacing

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

                PC3.Label {
                    anchors.centerIn: parent
                    text: mediaMode ? "♫" : "♪"
                    font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 3
                    color: PlasmaCore.Theme.textColor
                    visible: artworkUrl === ""
                }
            }

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

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: PlasmaCore.Units.smallSpacing

                    PC3.Button {
                        text: "⏮"
                        onClicked: prevStation()
                        enabled: daemonConnected && !mediaMode && stationsModel.length > 1
                        PC3.ToolTip.text: "Previous Station"
                        PC3.ToolTip.visible: hovered
                    }

                    PC3.Button {
                        text: isPlaying ? "⏸" : "▶️"
                        font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                        onClicked: togglePlay()
                        enabled: daemonConnected
                        highlighted: isPlaying
                        PC3.ToolTip.text: isPlaying ? "Pause" : "Play"
                        PC3.ToolTip.visible: hovered
                    }

                    PC3.Button {
                        text: "⏹"
                        onClicked: stopPlayback()
                        enabled: daemonConnected && isPlaying
                        PC3.ToolTip.text: "Stop"
                        PC3.ToolTip.visible: hovered
                    }

                    PC3.Button {
                        text: "⏭"
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

        // Options row
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
                text: "↻ Refresh"
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

        // Song history
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
