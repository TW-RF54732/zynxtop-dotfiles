pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../components"

Column {
    id: root
    required property var theme
    spacing: 18
    MonoText { theme: root.theme; text: "TRAY"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: SystemTray.items
            delegate: Rectangle {
                id: button
                required property SystemTrayItem modelData
                width: 38; height: 38; radius: 5
                color: mouse.containsMouse ? root.theme.colors.frame : "transparent"
                IconImage { anchors.centerIn: parent; implicitSize: 22; source: button.modelData.icon }
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
    MonoText { theme: root.theme; text: "沒有系統匣項目"; visible: SystemTray.items.values.length === 0; tone: root.theme.colors.textMuted; font.pixelSize: 12 }
}
