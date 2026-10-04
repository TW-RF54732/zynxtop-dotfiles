pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "launcher"
import "services"

PanelWindow {
    id: launcher

    required property var theme
    required property ApplicationsService applications
    property bool shown: false

    LauncherController {
        id: controller
        applications: launcher.applications
        onCloseRequested: launcher.hide()
    }

    visible: false
    focusable: true
    exclusiveZone: 0
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    WlrLayershell.namespace: "quickshell-launcher"

    function show() {
        closeTimer.stop()
        visible = true
        controller.reset()
        searchBox.text = ""
        searchBox.focusInput()
        Qt.callLater(() => shown = true)
    }

    function hide() {
        shown = false
        closeTimer.restart()
    }

    function toggle() {
        if (visible && shown) hide()
        else show()
    }

    Timer {
        id: closeTimer
        interval: launcher.theme.motion.fastDuration
        onTriggered: {
            launcher.visible = false
            controller.reset()
            searchBox.text = ""
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
        function show(): void { launcher.show() }
        function hide(): void { launcher.hide() }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.hide()
    }

    GlassFrame {
        id: surface
        theme: launcher.theme
        anchors.top: parent.top
        anchors.topMargin: parent.height * launcher.theme.launcher.verticalPosition - searchBox.height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property real expandedWidth: Math.min(launcher.theme.launcher.maxWidth,
                                                        parent.width - launcher.theme.launcher.screenMargin)
        width: launcher.shown ? expandedWidth : 0
        height: searchBox.height
            + (controller.expanded && !controller.commandMode ? resultList.height : 0)
            + (controller.expanded ? footer.height : 0)
        opacity: launcher.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: launcher.theme.motion.fastDuration; easing.type: Easing.OutCubic }
        }

        Behavior on width {
            NumberAnimation { duration: launcher.theme.motion.fastDuration; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: launcher.theme.motion.fastDuration; easing.type: Easing.OutCubic }
        }

        MouseArea { anchors.fill: parent; onClicked: event => event.accepted = true }

        SearchField {
            id: searchBox
            theme: launcher.theme
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            commandMode: controller.commandMode
            onTextChanged: controller.query = text
            onCloseRequested: launcher.hide()
            onActivationRequested: controller.activate()
            onSelectionMoved: delta => resultList.moveSelection(delta)
            onShowAllRequested: {
                controller.showAllApplications()
                resultList.positionViewAtBeginning()
            }
        }

        ResultsList {
            id: resultList
            z: 2
            theme: launcher.theme
            anchors.top: searchBox.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            visible: controller.expanded && !controller.commandMode
            results: controller.results
            selectedIndex: controller.selectedIndex
            onSelectionRequested: index => controller.selectedIndex = index
            onActivationRequested: controller.activate()
        }

        Rectangle {
            id: footer
            visible: controller.expanded
            anchors.top: controller.commandMode ? searchBox.bottom : resultList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: launcher.theme.launcher.footerHeight
            color: "transparent"
            radius: launcher.theme.geometry.cornerRadius

        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => searchBox.focusInput())
    }
}
