import QtQuick
import "../components"

// Floating card beside the Dashboard. The host shrinks the Dashboard by `space`
// and places this card in the freed strip, so it reads as split off from it.
GlassFrame {
    id: root

    property string kind: ""
    property var powerItems: []
    property real maximumHeight: 300
    // Content stays on the last requested kind while the card fades out.
    property string content: ""
    readonly property bool open: kind !== ""
    readonly property int pad: theme.dashboard.flyoutPadding
    readonly property int gap: theme.dashboard.gap
    property real reveal: open ? 1 : 0
    readonly property real space: (width + gap) * reveal
    signal powerTriggered(var entry)

    onKindChanged: if (kind !== "") content = kind

    radius: theme.topBar.radius
    color: theme.colors.topBarSurface
    border.width: theme.topBar.dividerWidth
    border.color: theme.colors.separator
    antialiasing: true
    visible: reveal > 0
    opacity: reveal
    // Both contents share one width so switching only changes the height.
    width: theme.powerMenu.width + pad * 2
    height: Math.min(maximumHeight,
        (content === "power" ? powerList.height : tray.implicitHeight) + pad * 2)

    Behavior on reveal { NumberAnimation { duration: root.theme.dashboard.flyoutDuration; easing.type: Easing.OutCubic } }
    Behavior on width { enabled: root.open; NumberAnimation { duration: root.theme.dashboard.flyoutDuration; easing.type: Easing.OutCubic } }
    Behavior on height { enabled: root.open; NumberAnimation { duration: root.theme.dashboard.flyoutDuration; easing.type: Easing.OutCubic } }

    TrayPanel {
        id: tray
        theme: root.theme
        x: root.pad; y: root.pad
        width: root.theme.powerMenu.width
        opacity: root.content === "tray" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: root.theme.motion.fastDuration } }
    }
    Column {
        id: powerList
        x: root.pad; y: root.pad
        width: root.theme.powerMenu.width
        opacity: root.content === "power" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: root.theme.motion.fastDuration } }
        Repeater {
            model: root.powerItems
            delegate: MenuRow {
                required property var modelData
                theme: root.theme
                entry: modelData
                width: powerList.width
                height: root.theme.geometry.controlSize
                hoverEnabled: true
                selected: hovered
                active: hovered && interactive
                onClicked: root.powerTriggered(modelData)
            }
        }
    }
}
