pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../components"
import "../services"

// Tray icons as plain content; DashboardFlyout provides the frame.
// Left click opens the app; the hover badge ends its process.
Item {
    id: root

    required property var theme
    property TrayProcessService processes: null
    readonly property int cell: theme.dashboard.trayIconSize + 10
    readonly property string error: processes ? processes.lastError : ""
    implicitWidth: 4 * cell + 3 * grid.spacing
    implicitHeight: Math.max(cell, grid.implicitHeight) + (error ? errorText.height + 6 : 0)

    Flow {
        id: grid
        width: parent.width
        spacing: 4
        Repeater {
            model: SystemTray.items

            delegate: InteractiveSurface {
                id: button
                required property SystemTrayItem modelData

                theme: root.theme
                hoverEnabled: true
                active: hover.hovered
                width: root.theme.dashboard.trayIconSize + 10
                height: width

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: root.theme.dashboard.trayIconSize
                    source: button.modelData.icon
                }
                QsMenuAnchor {
                    id: menu
                    menu: button.modelData.menu
                    anchor.item: button
                    anchor.rect.y: button.height
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.MiddleButton) button.modelData.secondaryActivate()
                        else if (event.button === Qt.RightButton || button.modelData.onlyMenu) {
                            if (button.modelData.hasMenu) menu.open()
                        } else button.modelData.activate()
                    }
                    onWheel: event => button.modelData.scroll(event.angleDelta.y, false)
                }
                HoverHandler { id: hover }
                Rectangle {
                    id: quitBadge
                    readonly property int size: 12
                    x: button.width - size
                    y: 0
                    width: size
                    height: size
                    radius: root.theme.geometry.cornerRadius
                    color: root.theme.colors.topBarSurface
                    border.width: root.theme.topBar.dividerWidth
                    border.color: root.theme.colors.separator
                    visible: root.processes !== null && hover.hovered && !!button.modelData?.id
                    Accessible.role: Accessible.Button
                    Accessible.name: "Quit " + (button.modelData?.title || button.modelData?.id || "")
                    MonoIcon {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        theme: root.theme
                        name: "close"
                        lineWidth: 1.4
                        color: quitMouse.containsMouse ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                    }
                    MouseArea {
                        id: quitMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.processes.terminate(button.modelData)
                    }
                }
            }
        }
    }
    MonoText {
        id: errorText
        anchors.top: grid.bottom
        anchors.topMargin: 6
        theme: root.theme
        text: root.error
        visible: root.error !== ""
        tone: root.theme.colors.textMuted
        font.pixelSize: 11
    }
    MonoText {
        anchors.verticalCenter: parent.verticalCenter
        theme: root.theme
        text: "EMPTY"
        visible: SystemTray.items.values.length === 0
        tone: root.theme.colors.textMuted
        font.pixelSize: 12
    }
}
