// X-Seti - Aug12 2025 - Global Player Deutschland - Plasma 6
import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.plasma5support 2.0 as P5Support
import org.kde.kirigami 2.20 as Kirigami
import org.kde.notification 1.0

PlasmoidItem {
    id: root

    property var stationsModel: []
    property int stationIndex: 0
    property string selectedStation: stationsModel.length > 0 ? stationsModel[stationIndex] : ""
    property string nowArtist: ""
    property string nowTitle: ""
    property string nowShow: ""
    property string playState: "Stopped"
    property bool loggingEnabled: false
    property url artworkUrl: ""
    property string lastTrackId: ""
    property bool notificationsEnabled: true

    Plasmoid.icon: {
        if (artworkUrl.toString() !== "" && playState === "Playing") {
            return artworkUrl.toString()
        } else {
            return "audio-headphones"
        }
    }

    toolTipMainText: {
        if (playState === "Playing" && (nowArtist || nowTitle)) {
            return nowArtist && nowTitle ? (nowArtist + " — " + nowTitle) : (nowTitle || nowArtist)
        } else {
            return "Global Player Deutschland"
        }
    }
    
    toolTipSubText: {
        if (playState === "Playing" && selectedStation) {
            return "Läuft auf " + selectedStation
        } else {
            return playState === "Playing" ? "Läuft" : playState === "Paused" ? "Pausiert" : "Gestoppt"
        }
    }

    Timer {
        id: pollTimer
        interval: 10000
        running: true
        repeat: true
        onTriggered: getNowPlaying()
    }

    Notification {
        id: trackNotification
        componentName: "globalplayer-germany"
        eventId: "trackChanged"
        title: "Global Player Deutschland"
        iconName: "audio-headphones"
        flags: Notification.CloseOnTimeout
        property bool ready: false
        Component.onCompleted: ready = true
    }

    P5Support.DataSource {
        id: execDS
        engine: "executable"
        onNewData: function(sourceName, data) {
            var out = (data["stdout"] || "").trim()
            if (sourceName.indexOf("GetNowPlaying") !== -1) {
                try {
                    var m = JSON.parse(out)
                    var newArtist = m.artist || ""
                    var newTitle = m.title || ""
                    var newShow = m.show || ""
                    var newState = m.state || playState
                    var newArtworkPath = m.artworkPath || ""
                    
                    var newTrackId = newArtist + "|" + newTitle
                    var trackChanged = (newTrackId !== lastTrackId) && newTrackId !== "|" && newState === "Playing"
                    
                    nowArtist = newArtist
                    nowTitle = newTitle
                    nowShow = newShow
                    playState = newState
                    
                    if (newArtworkPath) {
                        artworkUrl = "file://" + newArtworkPath
                    } else {
                        artworkUrl = ""
                    }
                    
                    if (trackChanged && notificationsEnabled && trackNotification.ready) {
                        showTrackNotification(newArtist, newTitle, selectedStation)
                        lastTrackId = newTrackId
                    } else if (!trackChanged && newTrackId !== "|") {
                        lastTrackId = newTrackId
                    }
                    
                } catch (e) {
                    console.log("Error parsing GetNowPlaying:", e)
                }
            } else if (sourceName.indexOf("GetState") !== -1) {
                try {
                    var s = JSON.parse(out)
                    playState = s.state || playState
                    loggingEnabled = s.logging === true
                    var st = s.station || ""
                    if (st.length > 0 && stationsModel.indexOf(st) >= 0) {
                        stationIndex = stationsModel.indexOf(st)
                    }
                } catch (e) {}
            } else if (sourceName.indexOf("GetStations") !== -1) {
                try {
                    var arr = JSON.parse(out)
                    if (Array.isArray(arr)) {
                        stationsModel = arr
                        if (arr.length > 0 && stationIndex >= arr.length) {
                            stationIndex = 0
                        }
                    }
                } catch (e) {}
            }
            disconnectSource(sourceName)
        }
    }

    function qdbusCall(method, args) {
        var cmd = "qdbus org.mooheda.gpd.germany /org/mooheda/gpd org.mooheda.gpd1." + method
        if (args && args.length > 0) {
            for (var i = 0; i < args.length; ++i) {
                var a = ("" + args[i]).replace(/\"/g, "\\\"")
                cmd += " \"" + a + "\""
            }
        }
        execDS.connectSource(cmd)
    }

    function showTrackNotification(artist, title, station) {
        if (!trackNotification.ready) return
        
        var notificationText = ""
        if (artist && title) {
            notificationText = artist + " — " + title
        } else if (title) {
            notificationText = title
        } else {
            return
        }
        
        trackNotification.text = notificationText
        if (station) {
            trackNotification.text += "\nAuf " + station
        }
        
        if (artworkUrl.toString() !== "") {
            trackNotification.iconName = artworkUrl.toString()
        } else {
            trackNotification.iconName = "audio-headphones"
        }
        
        trackNotification.sendEvent()
    }

    function getNowPlaying() { qdbusCall("GetNowPlaying", []) }
    function getState()      { qdbusCall("GetState", []) }
    function refreshStations(){ qdbusCall("GetStations", []) }
    function signIn()        { qdbusCall("SignIn", []) }

    function playCurrent() {
        if (stationsModel.length === 0) return
        selectedStation = stationsModel[stationIndex]
        qdbusCall("Play", [selectedStation])
        pollTimer.start()
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

    fullRepresentation: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            PC3.Label {
                text: "🇩🇪 Global Player Deutschland v3.2"
                font.bold: true
                Layout.fillWidth: true
            }
            PC3.Button { 
                text: "Anmelden"
                onClicked: signIn() 
            }
        }

        RowLayout {
            Layout.fillWidth: true
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
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }
                }
                
                PC3.Label {
                    anchors.centerIn: parent
                    text: artworkUrl.toString() === "" ? "🇩🇪" : ""
                    opacity: 0.6
                    font.pointSize: Math.max(16, Kirigami.Theme.defaultFont.pointSize * 1.5)
                }
                
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 2
                    width: 8
                    height: 8
                    radius: 4
                    color: playState === "Playing" ? "#ffcc00" : "transparent"
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
                            return "Keine Track-Info"
                        }
                    }
                    wrapMode: Text.WordWrap
                    font.weight: Font.Medium
                }
                
                PC3.Label {
                    Layout.fillWidth: true
                    text: nowShow ? ("Sendung: " + nowShow) : ""
                    wrapMode: Text.WordWrap
                    opacity: 0.8
                    visible: nowShow !== ""
                }
            }
        }

        PC3.ComboBox {
            id: stationPicker
            Layout.fillWidth: true
            model: stationsModel
            currentIndex: Math.max(0, Math.min(stationIndex, stationsModel.length - 1))
            
            onActivated: function(index) {
                if (index >= 0 && index < stationsModel.length) {
                    stationIndex = index
                    playCurrent()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PC3.Button { 
                text: "◀"
                enabled: stationsModel.length > 1
                onClicked: prevStation() 
            }
            PC3.Button { 
                text: "Spielen"
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
                text: {
                    if (playState === "Playing") return "Läuft"
                    if (playState === "Paused") return "Pausiert" 
                    return "Gestoppt"
                }
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                opacity: 0.7
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            
            PC3.CheckBox {
                id: logToggle
                text: "Log zu ~/globalplayer/gp-germany.logs"
                checked: loggingEnabled
                onToggled: qdbusCall("SetLogging", [checked ? "true" : "false"])
            }
            
            PC3.CheckBox {
                id: notifyToggle
                text: "Benachrichtigungen"
                checked: notificationsEnabled
                onToggled: notificationsEnabled = checked
            }
            
            PC3.Button { 
                text: "↻"
                onClicked: refreshStations()
                PC3.ToolTip.text: "Senderliste aktualisieren"
            }
        }
    }

    compactRepresentation: Item {
        MouseArea {
            id: compactMouseArea
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
            
            onWheel: function(wheel) {
                if (wheel.angleDelta.y > 0) {
                    prevStation()
                } else {
                    nextStation()
                }
                wheel.accepted = true
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

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
                        text: artworkUrl.toString() === "" ? "🇩🇪" : ""
                        opacity: 0.6
                    }
                    
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 1
                        width: 4
                        height: 4
                        radius: 2
                        color: playState === "Playing" ? "#ffcc00" : "transparent"
                        visible: playState === "Playing"
                        
                        SequentialAnimation on opacity {
                            running: playState === "Playing"
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 800 }
                            NumberAnimation { to: 1.0; duration: 800 }
                        }
                    }
                }

                PC3.Label {
                    Layout.fillWidth: true
                    text: {
                        if (stationsModel.length > 0 && stationIndex >= 0 && stationIndex < stationsModel.length) {
                            return stationsModel[stationIndex]
                        } else {
                            return "Global Player Deutschland"
                        }
                    }
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        PC3.Menu {
            id: stationMenu
            
            Repeater {
                model: stationsModel
                delegate: PC3.MenuItem {
                    required property int index
                    required property string modelData
                    
                    text: modelData
                    checkable: true
                    checked: index === stationIndex
                    onTriggered: { 
                        stationIndex = index
                        playCurrent() 
                    }
                }
            }
            
            PC3.MenuSeparator {
                visible: stationsModel.length > 0
            }
            
            PC3.MenuItem { 
                text: "Spielen"
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
                text: notificationsEnabled ? "Benachrichtigungen aus" : "Benachrichtigungen an"
                onTriggered: notificationsEnabled = !notificationsEnabled
            }
            PC3.MenuItem { 
                text: loggingEnabled ? "Logging aus" : "Logging an"
                onTriggered: qdbusCall("SetLogging", [(!loggingEnabled).toString()]) 
            }
            PC3.MenuItem { 
                text: "Senderliste aktualisieren"
                onTriggered: refreshStations() 
            }
            PC3.MenuItem { 
                text: "Anmelden"
                onTriggered: signIn() 
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: stationMenu.open()
        }
    }
}
