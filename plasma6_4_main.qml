// X-Seti - Jun 2026 - Global Player - Plasma 6.6 Compatible with Enhanced D-Bus
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami 2.20 as Kirigami

PlasmoidItem {
    id: root

    readonly property string appName: "Global Player"
    readonly property string appVers: "3.3.0"

    // D-Bus state
    property var stationsModel: []
    property int stationIndex: 0
    property string selectedStation: ""
    property string nowArtist: ""
    property string nowTitle: ""
    property string nowShow: ""
    property string playState: "Stopped"
    property bool loggingEnabled: false
    property bool pushNotifications: false
    property url artworkUrl: ""
    property bool daemonConnected: false
    property string errorMessage: ""
    property bool mediaMode: false
    property bool isPlaying: playState === "Playing"

    property string nowPlaying: {
        if (nowArtist && nowTitle) return nowArtist + " - " + nowTitle
        if (nowTitle) return nowTitle
        if (!daemonConnected) return "Waiting for daemon..."
        if (stationsModel.length === 0) return "No stations loaded"
        return "Select a station"
    }

    property string displayTitle: {
        if (nowArtist && nowTitle) return nowArtist + " - " + nowTitle
        if (nowTitle) return nowTitle
        if (selectedStation) return selectedStation
        if (!daemonConnected) return "Connecting..."
        return appName
    }

    toolTipSubText: {
        if (!daemonConnected) return "Daemon not connected"
        if (isPlaying && selectedStation) return "Playing: " + selectedStation
        return playState
    }

    property var playedSongs: []

    ListModel { id: playedSongsModel }

    // Startup: retry connection up to 10 times
    Timer {
        id: startupTimer
        interval: 1000
        running: true
        repeat: true
        property int attempts: 0
        onTriggered: {
            attempts++
            if (!daemonConnected) {
                pingDaemon()
                if (attempts >= 10) {
                    errorMessage = "Cannot connect to daemon. Is it running?"
                    running = false
                }
            } else {
                running = false
            }
        }
    }

    // Poll now-playing every 10s
    Timer {
        id: pollTimer
        interval: 10000
        running: daemonConnected && !mediaMode
        repeat: true
        onTriggered: { if (daemonConnected) getNowPlaying() }
    }

    // Expand refresh timer
    Timer {
        id: expandTimer
        interval: 300
        repeat: false
        onTriggered: { refreshStations(); getState() }
    }

    // D-Bus DataSource
    Plasma5Support.DataSource {
        id: execDS
        engine: "executable"

        onNewData: function(sourceName, data) {
            var out = (data["stdout"] || "").trim()
            var err = (data["stderr"] || "").trim()

            if (err && (err.indexOf("not find") !== -1 || err.indexOf("not available") !== -1)) {
                daemonConnected = false
            }

            if (sourceName.indexOf("Ping") !== -1) {
                if (out !== "" || err === "") {
                    daemonConnected = true
                    errorMessage = ""
                    refreshStations()
                    getState()
                } else {
                    daemonConnected = false
                }
            } else if (sourceName.indexOf("GetNowPlaying") !== -1) {
                try {
                    var m = JSON.parse(out)
                    nowArtist = m.artist || ""
                    nowTitle  = m.title  || ""
                    nowShow   = m.show   || ""
                    playState = m.state  || playState
                    artworkUrl = m.artworkPath ? ("file://" + m.artworkPath) : ""
                    if (!mediaMode && (nowArtist || nowTitle))
                        addToHistory(nowTitle, nowArtist)
                } catch(e) { console.log("GetNowPlaying parse error:", e) }

            } else if (sourceName.indexOf("GetState") !== -1) {
                try {
                    var s = JSON.parse(out)
                    playState         = s.state         || playState
                    loggingEnabled    = s.logging        === true
                    pushNotifications = s.notifications  === true
                    daemonConnected   = true
                    errorMessage      = ""
                    var st = s.station || ""
                    var idx = stationsModel.indexOf(st)
                    if (idx >= 0) {
                        stationIndex     = idx
                        selectedStation  = st
                        stationCombo.currentIndex = idx
                    }
                    if (s.volume    !== undefined) volumeSlider.value = s.volume
                    if (s.playDelay !== undefined) delaySlider.value  = s.playDelay
                } catch(e) { console.log("GetState parse error:", e) }

            } else if (sourceName.indexOf("GetStations") !== -1) {
                try {
                    var arr = JSON.parse(out)
                    if (arr && arr.length > 0) {
                        stationsModel = arr
                        daemonConnected = true
                        errorMessage = ""
                        if (stationIndex >= arr.length) stationIndex = 0
                        stationCombo.currentIndex = stationIndex
                    } else {
                        errorMessage = "No stations available."
                    }
                } catch(e) {
                    console.log("GetStations parse error:", e)
                    errorMessage = "Failed to parse station list"
                }
            }
            disconnectSource(sourceName)
        }
    }

    // D-Bus helpers
    function _dbus(method, args) {
        var cmd = "/usr/bin/python3 -c \""
        cmd += "import dbus, sys; "
        cmd += "bus = dbus.SessionBus(); "
        cmd += "obj = bus.get_object('org.mooheda.gpd', '/org/mooheda/gpd'); "
        cmd += "iface = dbus.Interface(obj, 'org.mooheda.gpd1'); "
        if (args && args.length > 0) {
            var esc = []
            for (var i = 0; i < args.length; i++)
                esc.push("'" + ("" + args[i]).replace(/'/g, "\\'") + "'")
            cmd += "print(str(iface." + method + "(" + esc.join(",") + ")))"
        } else {
            cmd += "print(str(iface." + method + "()))"
        }
        cmd += "\""
        execDS.connectSource(cmd)
    }

    // Ping uses a unique source name so onNewData can identify it
    function pingDaemon()      { _dbus("Ping", []) }
    function getNowPlaying()   { if (daemonConnected && !mediaMode) _dbus("GetNowPlaying", []) }
    function getState()        { if (daemonConnected) _dbus("GetState", []) }
    function refreshStations() { if (!mediaMode) _dbus("GetStations", []) }
    function signIn()          { if (!mediaMode) _dbus("SignIn", []) }

    function togglePlay() {
        if (!daemonConnected) { errorMessage = "Daemon not connected"; return }
        if (isPlaying) _dbus("Pause", [])
        else playCurrent()
    }

    function playCurrent() {
        if (!daemonConnected) { errorMessage = "Daemon not connected"; return }
        if (stationsModel.length === 0) {
            refreshStations()
            Qt.callLater(function() {
                if (stationsModel.length > 0) _doPlay()
                else errorMessage = "No stations available"
            })
            return
        }
        _doPlay()
    }

    function _doPlay() {
        if (stationIndex < 0 || stationIndex >= stationsModel.length) stationIndex = 0
        selectedStation = stationsModel[stationIndex]
        stationCombo.currentIndex = stationIndex
        _dbus("Play", [selectedStation])
        getState()
        getNowPlaying()
    }

    function stopPlayback() {
        if (!daemonConnected) return
        _dbus("Pause", [])
    }

    function nextStation() {
        if (!mediaMode && stationsModel.length > 0) {
            stationIndex = (stationIndex + 1) % stationsModel.length
            playCurrent()
        }
    }

    function prevStation() {
        if (!mediaMode && stationsModel.length > 0) {
            stationIndex = (stationIndex - 1 + stationsModel.length) % stationsModel.length
            playCurrent()
        }
    }

    function addToHistory(song, artist) {
        var entry = {
            "time":    new Date().toLocaleTimeString(Qt.locale(), "HH:mm"),
            "song":    song   || "Unknown",
            "artist":  artist || "Unknown",
            "station": selectedStation || ""
        }
        if (playedSongs.length > 0) {
            var last = playedSongs[0]
            if (last.song === entry.song && last.artist === entry.artist) return
        }
        var arr = [entry].concat(playedSongs)
        if (arr.length > 20) arr.length = 20
        playedSongs = arr
        playedSongsModel.clear()
        for (var i = 0; i < arr.length; i++) playedSongsModel.append(arr[i])
    }

    Component.onCompleted: {
        Qt.callLater(function() { addToHistory(appName + " ready", "System") })
    }

    onExpandedChanged: {
        if (expanded && daemonConnected) expandTimer.restart()
    }

    // Compact panel icon
    compactRepresentation: Item {
        Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
        Layout.preferredHeight: PlasmaCore.Units.iconSizes.small

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 3
            color: "transparent"
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

            Kirigami.Icon {
                anchors.centerIn: parent
                source: !daemonConnected ? "network-disconnect" : "radio"
                width: parent.width * 0.6
                height: parent.height * 0.6
                visible: artworkUrl === ""
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 1
                width: 6; height: 6; radius: 3
                color: {
                    if (!daemonConnected) return PlasmaCore.Theme.negativeTextColor
                    return isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.neutralTextColor
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton)        togglePlay()
                else if (mouse.button === Qt.RightButton)  nextStation()
                else if (mouse.button === Qt.MiddleButton) root.expanded = !root.expanded
            }
            onPressAndHold: { root.expanded = !root.expanded }
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) prevStation()
                else nextStation()
                wheel.accepted = true
            }
            PC3.ToolTip {
                text: displayTitle + "\nStatus: " + (daemonConnected ? playState : "Disconnected")
                visible: parent.containsMouse && !root.expanded
                delay: 500
            }
        }
    }

    // Full widget
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 32
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 28
        spacing: PlasmaCore.Units.smallSpacing

        // Error/status banner
        Rectangle {
            visible: !daemonConnected || errorMessage !== ""
            Layout.fillWidth: true
            implicitHeight: PlasmaCore.Units.gridUnit * 2
            color: PlasmaCore.Theme.negativeBackgroundColor
            radius: PlasmaCore.Units.smallSpacing

            RowLayout {
                anchors.fill: parent
                anchors.margins: PlasmaCore.Units.smallSpacing
                spacing: PlasmaCore.Units.smallSpacing

                Kirigami.Icon {
                    source: "dialog-warning"
                    implicitWidth: PlasmaCore.Units.iconSizes.small
                    implicitHeight: PlasmaCore.Units.iconSizes.small
                }
                PC3.Label {
                    Layout.fillWidth: true
                    text: errorMessage !== "" ? errorMessage : "Daemon not connected"
                    color: PlasmaCore.Theme.negativeTextColor
                    elide: Text.ElideRight
                }
                PC3.Button {
                    text: "Retry"
                    onClicked: { pingDaemon() }
                }
            }
        }

        // Artwork + controls
        RowLayout {
            Layout.fillWidth: true
            implicitHeight: PlasmaCore.Units.gridUnit * 8
            spacing: PlasmaCore.Units.largeSpacing

            // Artwork box
            Rectangle {
                implicitWidth:  PlasmaCore.Units.gridUnit * 8
                implicitHeight: PlasmaCore.Units.gridUnit * 8
                Layout.alignment: Qt.AlignVCenter
                radius: PlasmaCore.Units.smallSpacing
                color: "transparent"
                border.color: isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.textColor
                border.width: 2

                Image {
                    anchors.fill: parent
                    anchors.margins: PlasmaCore.Units.smallSpacing
                    source: artworkUrl
                    fillMode: Image.PreserveAspectFit
                    visible: artworkUrl !== ""
                }
                Kirigami.Icon {
                    anchors.centerIn: parent
                    source: "radio"
                    width: parent.width * 0.5
                    height: parent.height * 0.5
                    visible: artworkUrl === ""
                }
            }

            // Station info + transport
            ColumnLayout {
                Layout.fillWidth: true
                spacing: PlasmaCore.Units.smallSpacing

                PC3.ComboBox {
                    id: stationCombo
                    Layout.fillWidth: true
                    model: stationsModel
                    onActivated: function(idx) {
                        stationIndex = idx
                        selectedStation = stationsModel[idx] || ""
                        playCurrent()
                    }
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: nowPlaying
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                // Transport row
                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: PlasmaCore.Units.smallSpacing

                    PC3.Button {
                        icon.name: "media-skip-backward"
                        onClicked: prevStation()
                        enabled: daemonConnected && stationsModel.length > 1
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
                        enabled: daemonConnected && stationsModel.length > 1
                        PC3.ToolTip.text: "Next Station"
                        PC3.ToolTip.visible: hovered
                    }

                    // VU Meter
                    Item {
                        id: vuMeter
                        implicitWidth: PlasmaCore.Units.gridUnit * 3
                        implicitHeight: PlasmaCore.Units.gridUnit * 2
                        Layout.alignment: Qt.AlignVCenter
                        property var barHeights: [0,0,0,0,0,0,0,0]
                        property int barCount: 8

                        Timer {
                            interval: 120
                            running: isPlaying
                            repeat: true
                            onTriggered: {
                                var h = []
                                for (var i = 0; i < vuMeter.barCount; i++) {
                                    var prev = vuMeter.barHeights[i]
                                    var target = 0.15 + Math.random() * 0.85
                                    h.push(target > prev ? target : prev * 0.6)
                                }
                                vuMeter.barHeights = h
                            }
                            onRunningChanged: {
                                if (!running) {
                                    var h = []
                                    for (var i = 0; i < vuMeter.barCount; i++) h.push(0)
                                    vuMeter.barHeights = h
                                }
                            }
                        }

                        Row {
                            anchors.fill: parent
                            spacing: 1
                            Repeater {
                                model: vuMeter.barCount
                                delegate: Item {
                                    width: (vuMeter.width - (vuMeter.barCount - 1)) / vuMeter.barCount
                                    height: vuMeter.height
                                    Rectangle {
                                        width: parent.width
                                        height: Math.max(2, parent.height * vuMeter.barHeights[index])
                                        anchors.bottom: parent.bottom
                                        radius: 1
                                        color: {
                                            var v = vuMeter.barHeights[index]
                                            if (v > 0.85) return "#ff3b30"
                                            if (v > 0.60) return "#ff9f0a"
                                            return PlasmaCore.Theme.positiveTextColor
                                        }
                                        Behavior on height {
                                            NumberAnimation { duration: 80; easing.type: Easing.OutQuad }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Volume
                    Kirigami.Icon {
                        source: "player-volume"
                        implicitWidth: PlasmaCore.Units.iconSizes.small
                        implicitHeight: PlasmaCore.Units.iconSizes.small
                    }
                    PC3.Slider {
                        id: volumeSlider
                        from: 0; to: 100; value: 80; stepSize: 5
                        implicitWidth: 90
                        onMoved: { if (daemonConnected) _dbus("SetVolume", [value]) }
                        PC3.ToolTip.text: "Volume: " + value + "%"
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
                onToggled: _dbus("SetLogging", [checked ? "true" : "false"])
            }
            PC3.CheckBox {
                text: "Notifications"
                checked: pushNotifications
                enabled: daemonConnected
                onToggled: _dbus("SetNotifications", [checked ? "true" : "false"])
            }

            Kirigami.Icon {
                source: "chronometer"
                implicitWidth: PlasmaCore.Units.iconSizes.small
                implicitHeight: PlasmaCore.Units.iconSizes.small
            }
            PC3.Slider {
                id: delaySlider
                from: 0; to: 420; value: 0; stepSize: 10
                implicitWidth: 100
                onMoved: { if (daemonConnected) _dbus("SetPlayDelay", [value]) }
                PC3.ToolTip.text: "Play Delay: " + value + "ms"
                PC3.ToolTip.visible: hovered
            }
            PC3.Label {
                text: delaySlider.value + "ms"
                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
            }

            Item { Layout.fillWidth: true }

            PC3.Button {
                icon.name: "view-refresh"
                text: "Refresh"
                enabled: daemonConnected
                onClicked: { refreshStations(); getState() }
                PC3.ToolTip.text: "Reload station list"
                PC3.ToolTip.visible: hovered
            }
            PC3.Button {
                text: "Sign In"
                enabled: daemonConnected
                onClicked: signIn()
            }
        }

        // History header
        RowLayout {
            Layout.fillWidth: true
            PC3.Label {
                text: "Recently Played"
                font.bold: true
                Layout.fillWidth: true
            }
            PC3.Label {
                text: appName + " v" + appVers
                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                opacity: 0.6
            }
        }

        // History list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: playedSongsModel
            delegate: Item {
                width: ListView.view ? ListView.view.width : 0
                height: PlasmaCore.Units.gridUnit * 2

                PC3.Label {
                    id: timeLabel
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.time || ""
                    opacity: 0.6
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    width: PlasmaCore.Units.gridUnit * 3
                }
                PC3.Label {
                    id: stationLabel
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.station || ""
                    color: PlasmaCore.Theme.positiveTextColor
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    width: PlasmaCore.Units.gridUnit * 6
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                }
                PC3.Label {
                    anchors.left: timeLabel.right
                    anchors.right: stationLabel.left
                    anchors.leftMargin: PlasmaCore.Units.smallSpacing
                    anchors.rightMargin: PlasmaCore.Units.smallSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: (model.artist || "") + " - " + (model.song || "")
                    elide: Text.ElideRight
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                }
            }
        }
    }
}
