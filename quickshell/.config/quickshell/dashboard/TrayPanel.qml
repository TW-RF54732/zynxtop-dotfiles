pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../components"

// Tray icons as plain content; DashboardFlyout provides the frame.
Item {
    id: root

    required property var theme
    readonly property int cell: theme.dashboard.trayIconSize + 10
    implicitWidth: 4 * cell + 3 * grid.spacing
    implicitHeight: Math.max(cell, grid.implicitHeight)

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
                active: mouse.containsMouse
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
        }
        }
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
