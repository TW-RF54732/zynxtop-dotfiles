import Quickshell
import Quickshell.Services.Pipewire

Scope {
    id: root
    readonly property var outputs: Pipewire.nodes.values.filter(node => node.audio !== null && node.isSink && !node.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.audio !== null
    readonly property bool muted: available && sink.audio.muted
    readonly property real volume: available ? sink.audio.volume : 0

    PwObjectTracker { objects: root.sink !== null ? [root.sink] : [] }

    function selectOutput(node) {
        if (outputs.includes(node)) Pipewire.preferredDefaultAudioSink = node
    }
    function setMuted(value) {
        if (available) sink.audio.muted = value
    }
    function setVolume(value) {
        if (available) sink.audio.volume = Math.max(0, Math.min(1, value))
    }
    function adjustVolume(delta) { setVolume(volume + delta) }
}
