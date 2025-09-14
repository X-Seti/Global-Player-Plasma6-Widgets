<<<<<<< HEAD
// X-Seti - Sept14 2025 - GlobalPlayer - Plasma 6 Only with Notifications & Dynamic Icon
=======
// X-Seti - Aug12 2025 - GlobalPlayer - Plasma 6 Compatible 3.2.1
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
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
<<<<<<< HEAD

    // Track change detection for notifications
    property string lastTrackId: ""
    property bool notificationsEnabled: true
=======
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364

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

<<<<<<< HEAD
    toolTipSubText: {
        if (playState === "Playing" && selectedStation) {
            return "Playing on " + selectedStation
        } else {
            return playState
        }
    }
=======
    property bool isPlaying: playState === "Playing"
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364

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

<<<<<<< HEAD
    // Notification component
    Notification {
        id: trackNotification
        componentName: "globalplayer"
        eventId: "trackChanged"
        title: "Global Player"
        iconName: "audio-headphones"
        flags: Notification.CloseOnTimeout

        property bool ready: false
        Component.onCompleted: ready = true
    }

    P5Support.DataSource {
=======
    Plasma5Support.DataSource {
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
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
<<<<<<< HEAD
                    var newArtist = m.artist || ""
                    var newTitle = m.title || ""
                    var newShow = m.show || ""
                    var newState = m.state || playState
                    var newArtworkPath = m.artworkPath || ""

                    // Check if track changed for notification
                    var newTrackId = newArtist + "|" + newTitle
                    var trackChanged = (newTrackId !== lastTrackId) && newTrackId !== "|" && newState === "Playing"

                    // Update properties
                    nowArtist = newArtist
                    nowTitle = newTitle
                    nowShow = newShow
                    playState = newState

                    if (newArtworkPath) {
                        artworkUrl = "file://" + newArtworkPath
                    } else {
                        artworkUrl = ""
                    }

                    // Show notification for track changes
                    if (trackChanged && notificationsEnabled && trackNotification.ready) {
                        showTrackNotification(newArtist, newTitle, selectedStation)
                        lastTrackId = newTrackId
                    } else if (!trackChanged && newTrackId !== "|") {
                        lastTrackId = newTrackId
                    }

=======
                    nowArtist = m.artist || ""
                    nowTitle = m.title || ""
                    nowShow = m.show || ""
                    playState = m.state || playState
                    if (m.artworkPath) {
                        artworkUrl = "file://" + m.artworkPath
                    }
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
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

<<<<<<< HEAD
    function showTrackNotification(artist, title, station) {
        if (!trackNotification.ready) return

        var notificationText = ""
        if (artist && title) {
            notificationText = artist + " — " + title
        } else if (title) {
            notificationText = title
=======
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
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
        } else {
            playCurrent()
        }
<<<<<<< HEAD

        trackNotification.text = notificationText
        if (station) {
            trackNotification.text += "\nOn " + station
        }

        // Use artwork as notification icon if available
        if (artworkUrl.toString() !== "") {
            trackNotification.iconName = artworkUrl.toString()
        } else {
            trackNotification.iconName = "audio-headphones"
        }

        trackNotification.sendEvent()
=======
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
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
<<<<<<< HEAD
                text: "Global Player v3.2"
                font.bold: true
                Layout.fillWidth: true
            }
            PC3.Button {
                text: "Sign In"
                onClicked: signIn()
=======
                anchors.centerIn: parent
                text: "♪"
                opacity: 0.4
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 4
                visible: artworkUrl === ""
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
            }
        }

        // Title/Station name
        PC3.Label {
            Layout.fillWidth: true
<<<<<<< HEAD
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                radius: Kirigami.Units.smallSpacing
                border.color: Kirigami.Theme.textColor
                border.width: 1
                color: "transparent"

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    fillMode: Image.PreserveAspectFit
                    source: artworkUrl
                    visible: artworkUrl.toString() !== ""

                    // Add subtle animation when artwork changes
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }
                }

                PC3.Label {
                    anchors.centerIn: parent
                    text: artworkUrl.toString() === "" ? "♪" : ""
                    opacity: 0.6
                    font.pointSize: Math.max(16, Kirigami.Theme.defaultFont.pointSize * 1.5)
                }

                // Playing indicator
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 2
                    width: 8
                    height: 8
                    radius: 4
                    color: playState === "Playing" ? Kirigami.Theme.positiveTextColor : "transparent"
                    visible: playState === "Playing"

                    SequentialAnimation on opacity {
                        running: playState === "Playing"
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 800 }
                        NumberAnimation { to: 1.0; duration: 800 }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PC3.Label {
                    Layout.fillWidth: true
                    text: {
                        if (nowArtist && nowTitle) {
                            return nowArtist + " — " + nowTitle
                        } else if (nowTitle) {
                            return nowTitle
                        } else {
                            return "No track info"
                        }
                    }
                    wrapMode: Text.WordWrap
                    font.weight: Font.Medium
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: nowShow ? ("Show: " + nowShow) : ""
                    wrapMode: Text.WordWrap
                    opacity: 0.8
                    visible: nowShow !== ""
                }
            }
=======
            Layout.alignment: Qt.AlignHCenter
            text: displayTitle
            wrapMode: Text.WordWrap
            font.weight: Font.Medium
            font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
            horizontalAlignment: Text.AlignHCenter
            maximumLineCount: 2
            elide: Text.ElideRight
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
        }

        // Station selector dropdown
        PC3.ComboBox {
            id: stationPicker
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: PlasmaCore.Units.gridUnit * 16
            model: stationsModel
<<<<<<< HEAD
            currentIndex: Math.max(0, Math.min(stationIndex, stationsModel.length - 1))

            onActivated: function(index) {
                if (index >= 0 && index < stationsModel.length) {
                    stationIndex = index
                    playCurrent()
                }
=======
            currentIndex: stationIndex
            onActivated: {
                stationIndex = currentIndex
                playCurrent()
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
            }
        }

        // Play/Stop controls
        RowLayout {
<<<<<<< HEAD
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PC3.Button {
                text: "◀"
                enabled: stationsModel.length > 1
                onClicked: prevStation()
            }
            PC3.Button {
                text: "Play"
                enabled: stationsModel.length > 0
                onClicked: playCurrent()
            }
            PC3.Button {
                text: "Pause"
                enabled: playState === "Playing"
                onClicked: qdbusCall("Pause", [])
            }
            PC3.Button {
                text: "▶"
                enabled: stationsModel.length > 1
                onClicked: nextStation()
            }

            PC3.Label {
                text: playState
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                opacity: 0.7
=======
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
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
            }
        }

        // Settings checkboxes
        ColumnLayout {
            Layout.fillWidth: true
<<<<<<< HEAD
            spacing: Kirigami.Units.smallSpacing
=======
            spacing: PlasmaCore.Units.smallSpacing
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364

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
<<<<<<< HEAD
=======
        }

        // Status and additional controls
        RowLayout {
            Layout.fillWidth: true

            PC3.Label {
                text: playState
                opacity: 0.7
                Layout.fillWidth: true
            }
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364

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
<<<<<<< HEAD
            onClicked: root.expanded = !root.expanded

            // Mouse wheel support
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) {
                    prevStation()
                } else {
                    nextStation()
                }
                wheel.accepted = true
            }

            RowLayout {
=======
            anchors.margins: 2
            radius: PlasmaCore.Units.smallSpacing
            border.color: PlasmaCore.Theme.textColor
            border.width: 1
            color: "transparent"

            Image {
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
                anchors.fill: parent
                anchors.margins: 2
                fillMode: Image.PreserveAspectFit
                source: artworkUrl
                visible: artworkUrl !== ""
            }

<<<<<<< HEAD
                Rectangle {
                    Layout.preferredWidth: parent.height - Kirigami.Units.smallSpacing * 2
                    Layout.preferredHeight: parent.height - Kirigami.Units.smallSpacing * 2
                    Layout.alignment: Qt.AlignCenter
                    radius: Kirigami.Units.smallSpacing
                    border.color: Kirigami.Theme.textColor
                    border.width: 1
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        fillMode: Image.PreserveAspectFit
                        source: artworkUrl
                        visible: artworkUrl.toString() !== ""

                        Behavior on opacity {
                            NumberAnimation { duration: 300 }
                        }
                    }

                    PC3.Label {
                        anchors.centerIn: parent
                        text: artworkUrl.toString() === "" ? "♪" : ""
                        opacity: 0.6
                    }

                    // Playing indicator for compact mode
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        width: 4
                        height: 4
                        radius: 2
                        color: playState === "Playing" ? Kirigami.Theme.positiveTextColor : "transparent"
                        visible: playState === "Playing"

                        SequentialAnimation on opacity {
                            running: playState === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }
                }
=======
            PC3.Label {
                anchors.centerIn: parent
                text: "♪"
                opacity: 0.6
                font.pointSize: PlasmaCore.Theme.defaultFont.pointSize * 1.2
                visible: artworkUrl === ""
            }
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364

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
<<<<<<< HEAD
            id: stationMenu
=======
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
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364

            Repeater {
                model: Math.min(stationsModel.length, 8) // Limit menu items
                delegate: PC3.MenuItem {
<<<<<<< HEAD
                    required property int index
                    required property string modelData

                    text: modelData
=======
                    text: stationsModel[index]
>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
                    checkable: true
                    checked: index === stationIndex
                    onTriggered: {
                        stationIndex = index
                        playCurrent()
                    }
                }
            }

<<<<<<< HEAD
            PC3.MenuSeparator {
                visible: stationsModel.length > 0
            }

            PC3.MenuItem {
                text: "Play"
                enabled: stationsModel.length > 0
                onTriggered: playCurrent()
            }
            PC3.MenuItem {
                text: "Pause"
                enabled: playState === "Playing"
                onTriggered: qdbusCall("Pause", [])
            }
            PC3.MenuSeparator {}
            PC3.MenuItem {
                text: notificationsEnabled ? "Disable Notifications" : "Enable Notifications"
                onTriggered: notificationsEnabled = !notificationsEnabled
            }
            PC3.MenuItem {
                text: loggingEnabled ? "Disable Logging" : "Enable Logging"
                onTriggered: qdbusCall("SetLogging", [(!loggingEnabled).toString()])
            }
            PC3.MenuItem {
                text: "Refresh Stations"
                onTriggered: refreshStations()
            }
=======
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

>>>>>>> 69e8bc1a01550fd48bf30830dda70408b8177364
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
