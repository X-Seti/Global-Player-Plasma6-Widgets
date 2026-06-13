// X-Seti - Jun 2026 - Global Player - Plasma 6.6 Development File
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
    property bool mediaMode: false
    property bool isPlaying: playState === "Playing"
    property var playedSongs: []

    property string nowPlaying: {
        if (nowArtist && nowTitle) return nowArtist + " - " + nowTitle
        if (nowTitle) return nowTitle
        if (!daemonConnected) return "Waiting for daemon..."
        if (stationsModel.length === 0) return "No stations loaded"
        return "Select a station"
    }

    property string displayTitle: {
        if (nowArtist && nowTitle) return nowArtist + " - " + nowTitle
        if (selectedStation) return selectedStation
        return "Global Player"
    }

    toolTipSubText: daemonConnected ? (isPlaying ? "Playing: " + selectedStation : playState) : "Daemon not connected"

    ListModel { id: playedSongsModel }

    Timer {
        id: startupTimer
        interval: 1000; running: true; repeat: true
        property int attempts: 0
        onTriggered: {
            attempts++
            if (!daemonConnected) {
                testDaemonConnection()
                if (attempts >= 10) { errorMessage = "Cannot connect to daemon."; running = false }
            } else { running = false }
        }
    }

    Timer {
        id: pollTimer
        interval: 10000
        running: daemonConnected && !mediaMode
        repeat: true
        onTriggered: { if (daemonConnected) getNowPlaying() }
    }

    Timer {
        id: expandTimer
        interval: 300; repeat: false
        onTriggered: { refreshStations(); getState() }
    }

    Plasma5Support.DataSource {
        id: execDS
        engine: "executable"
        onNewData: function(sourceName, data) {
            var out = (data["stdout"] || "").trim()
            var err = (data["stderr"] || "").trim()
            if (err && (err.indexOf("not find") !== -1 || err.indexOf("not available") !== -1))
                daemonConnected = false
            if (sourceName.indexOf("GetNowPlaying") !== -1) {
                try {
                    var m = JSON.parse(out)
                    nowArtist = m.artist || ""; nowTitle = m.title || ""
                    nowShow = m.show || ""; playState = m.state || playState
                    artworkUrl = m.artworkPath ? ("file://" + m.artworkPath) : ""
                    if (!mediaMode && (nowArtist || nowTitle)) addToHistory(nowTitle, nowArtist)
                } catch(e) {}
            } else if (sourceName.indexOf("GetState") !== -1) {
                try {
                    var s = JSON.parse(out)
                    playState = s.state || playState
                    loggingEnabled = s.logging === true
                    pushNotifications = s.notifications === true
                    daemonConnected = true; errorMessage = ""
                    var st = s.station || ""
                    var idx = stationsModel.indexOf(st)
                    if (idx >= 0) { stationIndex = idx; stationCombo.currentIndex = idx }
                    if (s.volume !== undefined) volumeSlider.value = s.volume
                    if (stationsModel.length === 0) refreshStations()
                } catch(e) {}
            } else if (sourceName.indexOf("GetStations") !== -1) {
                try {
                    var arr = JSON.parse(out)
                    if (arr && arr.length > 0) {
                        stationsModel = arr; daemonConnected = true; errorMessage = ""
                        if (stationIndex >= arr.length) stationIndex = 0
                        stationCombo.currentIndex = stationIndex
                    } else { errorMessage = "No stations available." }
                } catch(e) { errorMessage = "Failed to parse station list" }
            }
            disconnectSource(sourceName)
        }
    }

    function qdbusCall(method, args) {
        var cmd = "/usr/bin/python3 -c \""
        cmd += "import dbus; bus = dbus.SessionBus(); "
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

    function testDaemonConnection() { qdbusCall("GetState", []) }
    function getNowPlaying() { if (daemonConnected && !mediaMode) qdbusCall("GetNowPlaying", []) }
    function getState() { if (daemonConnected) qdbusCall("GetState", []) }
    function refreshStations() { if (!mediaMode) qdbusCall("GetStations", []) }
    function signIn() { qdbusCall("SignIn", []) }

    function togglePlay() {
        if (!daemonConnected) return
        if (isPlaying) qdbusCall("Pause", [])
        else playCurrent()
    }

    function playCurrent() {
        if (!daemonConnected) return
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
        qdbusCall("Play", [selectedStation])
        getState(); getNowPlaying()
    }

    function stopPlayback() { if (daemonConnected) qdbusCall("Pause", []) }

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

    function addToHistory(song, artist) {
        var entry = {
            "time": new Date().toLocaleTimeString(Qt.locale(), "HH:mm"),
            "song": song || "Unknown", "artist": artist || "Unknown",
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
        Qt.callLater(function() { addToHistory("Global Player ready", "System") })
    }

    onExpandedChanged: { if (expanded && daemonConnected) expandTimer.restart() }

    // Compact panel icon
    compactRepresentation: Item {
        Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
        Layout.preferredHeight: PlasmaCore.Units.iconSizes.small

        Rectangle {
            anchors.fill: parent; anchors.margins: 1
            radius: 3; color: "transparent"
            border.width: 2
            border.color: !daemonConnected ? PlasmaCore.Theme.negativeTextColor
                        : isPlaying ? PlasmaCore.Theme.positiveTextColor
                        : PlasmaCore.Theme.textColor

            Image {
                anchors.fill: parent; anchors.margins: 3
                fillMode: Image.PreserveAspectFit
                source: artworkUrl; visible: artworkUrl !== ""
            }
            Kirigami.Icon {
                anchors.centerIn: parent; source: "radio"
                width: parent.width * 0.6; height: parent.height * 0.6
                visible: artworkUrl === ""
            }
            Rectangle {
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.margins: 1; width: 6; height: 6; radius: 3
                color: !daemonConnected ? PlasmaCore.Theme.negativeTextColor
                     : isPlaying ? PlasmaCore.Theme.positiveTextColor
                     : PlasmaCore.Theme.neutralTextColor
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) togglePlay()
                else if (mouse.button === Qt.RightButton) nextStation()
                else root.expanded = !root.expanded
            }
            onPressAndHold: { root.expanded = !root.expanded }
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) prevStation(); else nextStation()
                wheel.accepted = true
            }
            PC3.ToolTip {
                text: displayTitle + "\n" + (daemonConnected ? playState : "Disconnected")
                visible: parent.containsMouse && !root.expanded
                delay: 500
            }
        }
    }

    // Full widget
    fullRepresentation: Item {
        id: fullRep
        implicitWidth:  PlasmaCore.Units.gridUnit * 35
        implicitHeight: PlasmaCore.Units.gridUnit * 28

        // Error banner - always in layout, height 0 when not needed
        Rectangle {
            id: errorBanner
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: (!daemonConnected || errorMessage !== "") ? PlasmaCore.Units.gridUnit * 2 : 0
            clip: true
            color: PlasmaCore.Theme.negativeBackgroundColor
            RowLayout {
                anchors.fill: parent; anchors.margins: 4; spacing: 4
                PC3.Label { text: "!"; font.bold: true; color: PlasmaCore.Theme.negativeTextColor }
                PC3.Label {
                    Layout.fillWidth: true; elide: Text.ElideRight
                    text: errorMessage !== "" ? errorMessage : "Daemon not connected"
                    color: PlasmaCore.Theme.negativeTextColor
                }
                PC3.Button {
                    text: "Retry"; visible: !daemonConnected
                    onClicked: { testDaemonConnection(); refreshStations() }
                }
            }
        }

        // Artwork box - fixed size, top-left below banner
        Rectangle {
            id: artworkBox
            anchors { top: errorBanner.bottom; left: parent.left }
            anchors.topMargin: 4; anchors.leftMargin: 4
            width:  PlasmaCore.Units.gridUnit * 8
            height: PlasmaCore.Units.gridUnit * 8
            radius: 4
            color: PlasmaCore.Theme.backgroundColor
            border.color: isPlaying ? PlasmaCore.Theme.positiveTextColor : PlasmaCore.Theme.highlightColor
            border.width: 2

            Image {
                anchors.fill: parent; anchors.margins: 4
                source: artworkUrl; fillMode: Image.PreserveAspectFit
                visible: artworkUrl !== ""
            }
            Kirigami.Icon {
                anchors.centerIn: parent; source: "radio"
                width: parent.width * 0.5; height: parent.height * 0.5
                visible: artworkUrl === ""
            }
        }

        // Controls - top-right of artwork, same top anchor
        ColumnLayout {
            id: controlsCol
            anchors {
                top: errorBanner.bottom; topMargin: 4
                left: artworkBox.right; leftMargin: 8
                right: parent.right; rightMargin: 4
            }
            spacing: 4

            PC3.ComboBox {
                id: stationCombo
                Layout.fillWidth: true
                model: stationsModel
                currentIndex: stationIndex
                onActivated: { stationIndex = index; playCurrent() }
            }

            PC3.Label {
                Layout.fillWidth: true
                text: selectedStation || "No Station Selected"
                font.bold: true; horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }

            PC3.Label {
                Layout.fillWidth: true
                text: nowPlaying
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true; Layout.alignment: Qt.AlignHCenter
                spacing: 4
                PC3.Button { text: "⏮"; onClicked: prevStation(); enabled: daemonConnected && stationsModel.length > 1 }
                PC3.Button { text: isPlaying ? "⏸" : "▶"; onClicked: togglePlay(); enabled: daemonConnected; highlighted: isPlaying }
                PC3.Button { text: "⏹"; onClicked: stopPlayback(); enabled: daemonConnected && isPlaying }
                PC3.Button { text: "⏭"; onClicked: nextStation(); enabled: daemonConnected && stationsModel.length > 1 }
                Kirigami.Icon { source: "player-volume"; width: 16; height: 16; Layout.alignment: Qt.AlignVCenter }
                PC3.Slider {
                    id: volumeSlider
                    from: 0; to: 100; value: 80; stepSize: 5
                    Layout.preferredWidth: PlasmaCore.Units.gridUnit * 6
                    onValueChanged: if (daemonConnected) qdbusCall("SetVolume", [value])
                }
            }

            PC3.Label {
                Layout.fillWidth: true
                visible: stationsModel.length > 0
                text: "Station " + (stationIndex + 1) + " of " + stationsModel.length
                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                opacity: 0.7; horizontalAlignment: Text.AlignHCenter
            }
        }

        // VU meter - full width below artwork box
        Item {
            id: vuMeter
            anchors {
                top: artworkBox.bottom; topMargin: 4
                left: parent.left; right: parent.right
                leftMargin: 4; rightMargin: 4
            }
            height: PlasmaCore.Units.gridUnit * 2

            property var barHeights: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
            property int barCount: 16

            Timer {
                interval: 100; running: isPlaying; repeat: true
                onTriggered: {
                    var h = []
                    for (var i = 0; i < vuMeter.barCount; i++) {
                        var prev = vuMeter.barHeights[i]
                        var t = 0.1 + Math.random() * 0.9
                        h.push(t > prev ? t : prev * 0.65)
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
                anchors.fill: parent; spacing: 2
                Repeater {
                    model: vuMeter.barCount
                    delegate: Item {
                        width: (vuMeter.width - (vuMeter.barCount - 1) * 2) / vuMeter.barCount
                        height: vuMeter.height
                        Rectangle {
                            width: parent.width
                            height: Math.max(2, parent.height * vuMeter.barHeights[index])
                            anchors.bottom: parent.bottom; radius: 1
                            color: {
                                var v = vuMeter.barHeights[index]
                                if (v > 0.85) return "#ff3b30"
                                if (v > 0.60) return "#ff9f0a"
                                return PlasmaCore.Theme.positiveTextColor
                            }
                            Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }
                        }
                    }
                }
            }
        }

        // Options row - below VU meter
        RowLayout {
            id: optionsRow
            anchors {
                top: vuMeter.bottom; topMargin: 4
                left: parent.left; right: parent.right
                leftMargin: 4; rightMargin: 4
            }
            spacing: 4

            PC3.CheckBox {
                text: "Logging"; checked: loggingEnabled; enabled: daemonConnected
                onToggled: qdbusCall("SetLogging", [checked ? "true" : "false"])
            }
            PC3.CheckBox {
                text: "Notifications"; checked: pushNotifications; enabled: daemonConnected
                onToggled: qdbusCall("SetNotifications", [checked ? "true" : "false"])
            }
            Item { Layout.fillWidth: true }
            PC3.Button {
                text: "Refresh"; enabled: daemonConnected
                onClicked: { refreshStations(); getState() }
            }
            PC3.Button { text: "Sign In"; enabled: daemonConnected; onClicked: signIn() }
        }

        // History header - below options
        RowLayout {
            id: historyHeader
            anchors {
                top: optionsRow.bottom; topMargin: 4
                left: parent.left; right: parent.right
                leftMargin: 4; rightMargin: 4
            }
            PC3.Label { text: "Recently Played"; font.bold: true; Layout.fillWidth: true }
            PC3.Label { text: "Global Player v3.3"; font.pointSize: PlasmaCore.Theme.smallestFont.pointSize; opacity: 0.6 }
        }

        // Song list - fills remaining space
        ListView {
            anchors {
                top: historyHeader.bottom; topMargin: 4
                left: parent.left; right: parent.right; bottom: parent.bottom
                leftMargin: 4; rightMargin: 4
            }
            clip: true
            model: playedSongsModel
            delegate: Item {
                width: ListView.view ? ListView.view.width : 0
                height: PlasmaCore.Units.gridUnit * 2

                PC3.Label {
                    id: timeLabel
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                    text: model.time || ""; opacity: 0.6
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    width: PlasmaCore.Units.gridUnit * 4
                }
                PC3.Label {
                    id: stationLabel
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    text: model.station || ""; color: PlasmaCore.Theme.positiveTextColor
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    width: PlasmaCore.Units.gridUnit * 6; elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                }
                PC3.Label {
                    anchors.left: timeLabel.right; anchors.right: stationLabel.left
                    anchors.leftMargin: 4; anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: (model.artist || "") + " - " + (model.song || "")
                    elide: Text.ElideRight
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                }
            }
        }
    }
}
