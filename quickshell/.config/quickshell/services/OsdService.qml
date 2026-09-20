import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    required property AudioService audio
    required property NetworkService network
    property int defaultTransientTimeout: 1800
    property int volumeTimeout: 1400

    property bool ready: false
    property var externalStatuses: []
    property string transientKind: ""
    property string transientIcon: ""
    property string transientText: ""
    property real transientProgress: -1
    property string transientValue: ""

    readonly property bool transientVisible: transientKind.length > 0
    readonly property var statuses: {
        const result = []
        if (network.offline)
            result.push({id: "network", icon: "offline", text: "無網路連線", compact: false})
        if (audio.available && audio.muted)
            result.push({id: "muted", icon: "muted", text: "", compact: true})
        return result.concat(externalStatuses)
    }

    function showVolume() {
        if (!ready || !audio.available)
            return
        transientKind = "volume"
        transientIcon = audio.muted ? "muted" : "volume"
        transientText = ""
        transientProgress = audio.volume
        transientValue = Math.round(audio.volume * 100) + "%"
        transientTimer.interval = volumeTimeout
        transientTimer.restart()
    }

    function setStatus(id, icon, text) {
        if (!id)
            return
        const next = externalStatuses.filter(entry => entry.id !== id)
        next.push({id: id, icon: icon || "star", text: text || "", compact: !text})
        externalStatuses = next
    }

    function removeStatus(id) {
        externalStatuses = externalStatuses.filter(entry => entry.id !== id)
    }

    function showMessage(icon, text, timeout) {
        transientKind = "message"
        transientIcon = icon || "star"
        transientText = text || ""
        transientProgress = -1
        transientValue = ""
        transientTimer.interval = Math.max(250, timeout || defaultTransientTimeout)
        transientTimer.restart()
    }

    Component.onCompleted: Qt.callLater(() => ready = true)

    Connections {
        target: root.audio
        function onVolumeChanged() { root.showVolume() }
    }

    Timer {
        id: transientTimer
        onTriggered: root.transientKind = ""
    }

    IpcHandler {
        target: "osd"
        function set(id: string, icon: string, text: string): void {
            root.setStatus(id, icon, text)
        }
        function remove(id: string): void { root.removeStatus(id) }
        function show(icon: string, text: string): void {
            root.showMessage(icon, text, root.defaultTransientTimeout)
        }
        function showFor(icon: string, text: string, timeout: int): void {
            root.showMessage(icon, text, timeout)
        }
        function clear(): void { root.externalStatuses = [] }
    }
}
