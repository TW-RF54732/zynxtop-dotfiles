pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "services"
import "services/powerEntries.js" as PowerEntries

Scope {
    id: root

    required property var theme
    required property var compositor
    property bool shown: false
    // Reboot and power off ask for confirmation inside the popup.
    property string pendingAction: ""

    readonly property var targetScreen: {
        const active = compositor.activeWindow
        if (active && active.monitor) {
            for (const screen of Quickshell.screens)
                if (screen.name === active.monitor.name) return screen
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }
    readonly property var capabilities: systemStatus.status.capabilities || ({})
    readonly property var entries: PowerEntries.build(capabilities, systemStatus.busy)

    function show() {
        pendingAction = ""
        shown = true
        window.visible = true
        Qt.callLater(() => menu.forceActiveFocus())
    }
    function showConfirm(action) {
        show()
        pendingAction = action
    }
    function hide() {
        shown = false
        pendingAction = ""
        window.visible = false
    }
    function toggle() {
        if (shown) hide()
        else show()
    }
    function run(action) {
        systemStatus.act(action)
        hide()
    }

    // Capabilities are only needed while the menu is open.
    SystemStatusService { id: systemStatus; enabled: root.shown }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { root.toggle() }
        function show(): void { root.show() }
        function hide(): void { root.hide() }
    }

    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: false
        focusable: true
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        anchors { top: true; right: true; bottom: true; left: true }
        WlrLayershell.namespace: "quickshell-powermenu"

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        Item {
            id: placement
            x: (window.width - width) / 2
            y: (window.height - height) / 2
            width: root.theme.powerMenu.width
            height: root.pendingAction === "" ? menu.implicitHeight : confirm.implicitHeight

            MenuPanel {
                id: menu
                theme: root.theme
                width: parent.width
                height: implicitHeight
                shown: root.shown && root.pendingAction === ""
                direction: "down"
                items: root.entries
                onTriggered: (index, entry) => {
                    if (entry.confirm) root.pendingAction = entry.key
                    else root.run(entry.key)
                }
                onDismissRequested: root.hide()
            }

            PanelTransition {
                id: confirm
                theme: root.theme
                width: parent.width
                implicitHeight: 112
                shown: root.shown && root.pendingAction !== ""
                direction: "down"
                focus: shown
                onShownChanged: if (shown) Qt.callLater(() => confirm.forceActiveFocus())
                Keys.onEscapePressed: root.pendingAction = ""
                Keys.onReturnPressed: root.run(root.pendingAction)
                Keys.onEnterPressed: root.run(root.pendingAction)

                GlassFrame {
                    theme: root.theme
                    width: confirm.width
                    height: confirm.height
                    MonoText {
                        theme: root.theme
                        anchors {
                            top: parent.top
                            topMargin: root.theme.geometry.outerPadding / 2
                            horizontalCenter: parent.horizontalCenter
                        }
                        text: root.pendingAction === "reboot" ? "Reboot now?" : "Power off now?"
                        tone: root.theme.colors.textPrimary
                    }
                    Row {
                        anchors {
                            bottom: parent.bottom
                            bottomMargin: root.theme.geometry.outerPadding / 2
                            horizontalCenter: parent.horizontalCenter
                        }
                        spacing: 8
                        TextButton {
                            theme: root.theme
                            text: "Cancel"
                            hoverEnabled: true
                            onClicked: root.pendingAction = ""
                        }
                        TextButton {
                            theme: root.theme
                            text: "Confirm"
                            textColor: root.theme.colors.textPrimary
                            hoverEnabled: true
                            active: true
                            onClicked: root.run(root.pendingAction)
                        }
                    }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            onActivated: {
                if (root.pendingAction !== "") root.pendingAction = ""
                else root.hide()
            }
        }
    }
}
