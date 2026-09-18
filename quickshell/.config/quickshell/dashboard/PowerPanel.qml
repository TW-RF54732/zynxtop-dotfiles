pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../services"

ColumnLayout {
    id: root
    required property var theme
    required property SystemStatusService systemStatus
    property string pendingAction: ""
    onVisibleChanged: if (!visible) pendingAction = ""
    spacing: 8
    MonoText { theme: root.theme; text: "POWER"; font.pixelSize: 12; tone: root.theme.colors.textSecondary }
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: [{key: "lock", icon: "lock", label: "Lock"}, {key: "suspend", icon: "moon", label: "Sleep"},
                {key: "hibernate", icon: "hibernate", label: "Hibernate"}, {key: "reboot", icon: "reboot", label: "Reboot"}, {key: "poweroff", icon: "power", label: "Power off"}]
            delegate: IconButton {
                id: powerButton
                required property var modelData
                theme: root.theme; name: modelData.icon
                implicitWidth: 30; implicitHeight: 30; iconSize: 18
                hoverEnabled: true
                opacity: interactive ? 1 : 0.35
                Accessible.name: modelData.label
                Accessible.role: Accessible.Button
                ToolTip {
                    id: hint
                    parent: powerButton
                    visible: powerButton.hovered
                    text: powerButton.modelData.label
                    delay: 350
                    timeout: 3000
                    x: (powerButton.width - width) / 2
                    y: -height - 6
                    padding: 8
                    verticalPadding: 5
                    contentItem: MonoText {
                        theme: root.theme
                        text: hint.text
                        font.pixelSize: 12
                        tone: root.theme.colors.textSecondary
                    }
                    background: Rectangle {
                        color: root.theme.colors.surface
                        radius: root.theme.geometry.cornerRadius
                        border.width: 1
                        border.color: root.theme.colors.separator
                    }
                    enter: Transition {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 }
                    }
                    exit: Transition {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 }
                    }
                }
                interactive: !root.systemStatus.busy && !!root.systemStatus.status.capabilities && !!root.systemStatus.status.capabilities[modelData.key]
                onClicked: {
                    if (modelData.key === "reboot" || modelData.key === "poweroff") root.pendingAction = modelData.key
                    else root.systemStatus.act(modelData.key)
                }
            }
        }
    }
    ColumnLayout {
        visible: root.pendingAction !== ""
        MonoText { theme: root.theme; text: root.pendingAction === "reboot" ? "REBOOT?" : "POWER OFF?"; font.pixelSize: 12 }
        RowLayout {
            TextButton { theme: root.theme; text: "CONFIRM"; implicitHeight: 30; onClicked: { root.systemStatus.act(root.pendingAction); root.pendingAction = "" } }
            TextButton { theme: root.theme; text: "CANCEL"; implicitHeight: 30; onClicked: root.pendingAction = "" }
        }
    }
    MonoText {
        theme: root.theme; text: root.systemStatus.actionError
        visible: text !== ""; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12
    }
}
