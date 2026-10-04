pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "components"
import "services"

Scope {
    id: root

    required property var theme
    required property ClipboardService clipboard
    required property var compositor
    property bool shown: false
    property int selectedIndex: 0
    property var caret: ({ valid: false })
    property string targetAddress: ""
    property string targetClass: ""
    property string pasteModifiers: "CTRL"

    readonly property var targetScreen: {
        const screens = Quickshell.screens
        if (caret.valid) {
            for (const screen of screens) {
                if (caret.x >= screen.x && caret.x < screen.x + screen.width
                    && caret.top >= screen.y && caret.top < screen.y + screen.height) return screen
            }
        }
        const active = compositor.activeWindow
        if (active && active.monitor) {
            for (const screen of screens) if (screen.name === active.monitor.name) return screen
        }
        return screens.length > 0 ? screens[0] : null
    }

    function show() {
        selectedIndex = 0
        clipboard.refresh()
        if (!activeWindowQuery.running) activeWindowQuery.running = true
        if (!caretQuery.running) caretQuery.running = true
    }

    function finishShow() {
        shown = true
        window.visible = true
        Qt.callLater(() => keyHandler.forceActiveFocus())
    }

    function hide() {
        shown = false
        window.visible = false
    }

    function toggle() {
        if (shown) hide()
        else show()
    }

    function moveSelection(delta) {
        const count = clipboard.entries.length
        if (count === 0) return
        selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + delta))
        list.ensureVisible(selectedIndex)
    }

    function activate() {
        if (selectedIndex < 0 || selectedIndex >= clipboard.entries.length) return
        const entry = clipboard.entries[selectedIndex]
        const terminal = /^(kitty|foot|alacritty|wezterm|org\.wezfurlong\.wezterm|com\.mitchellh\.ghostty)$/i
            .test(targetClass)
        pasteModifiers = !entry.binary && terminal ? "CTRL_SHIFT" : "CTRL"
        clipboard.copy(entry)
    }

    Connections {
        target: root.clipboard
        function onRefreshed() {
            root.selectedIndex = Math.min(root.selectedIndex,
                Math.max(0, root.clipboard.entries.length - 1))
        }
        function onCopied() {
            root.hide()
            pasteTimer.restart()
        }
    }

    Timer {
        id: pasteTimer
        interval: 80
        onTriggered: {
            const selector = /^0x[0-9a-fA-F]+$/.test(root.targetAddress)
                ? ", window = \"address:" + root.targetAddress + "\"" : ""
            Quickshell.execDetached(["hyprctl", "dispatch",
                "hl.dsp.send_shortcut({ mods = \"" + root.pasteModifiers
                    + "\", key = \"V\"" + selector + " })"])
        }
    }

    Process {
        id: activeWindowQuery
        command: ["hyprctl", "-j", "activewindow"]
        stdout: StdioCollector { id: activeWindowOutput }
        onExited: exitCode => {
            try {
                const value = JSON.parse(activeWindowOutput.text)
                root.targetAddress = exitCode === 0 ? String(value.address || "") : ""
                root.targetClass = exitCode === 0 ? String(value.class || value.initialClass || "") : ""
            } catch (exception) {
                root.targetAddress = ""
                root.targetClass = ""
            }
        }
    }

    Process {
        id: caretQuery
        command: ["hyprctl", "-j", "quickshell-caret"]
        stdout: StdioCollector { id: caretOutput }
        onExited: exitCode => {
            try {
                const value = JSON.parse(caretOutput.text)
                root.caret = exitCode === 0 && value.valid === true ? value : ({ valid: false })
            } catch (exception) {
                root.caret = ({ valid: false })
            }
            root.finishShow()
        }
    }

    IpcHandler {
        target: "clipboard"
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
        WlrLayershell.namespace: "quickshell-clipboard"

        onVisibleChanged: {
            if (visible) Qt.callLater(() => keyHandler.forceActiveFocus())
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            onActivated: root.hide()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.hide()
        }

        PopupPlacement {
            id: placement
            availableWidth: window.screen ? window.screen.width : 0
            availableHeight: window.screen ? window.screen.height : 0
            popupWidth: frame.width
            popupHeight: frame.height
            cursorValid: root.caret.valid === true
            cursorX: (root.caret.x || 0) - (window.screen ? window.screen.x : 0)
            cursorBottom: (root.caret.y || 0) - (window.screen ? window.screen.y : 0)
            cursorTop: (root.caret.top || 0) - (window.screen ? window.screen.y : 0)
            margin: root.theme.clipboard.screenMargin
            gap: root.theme.clipboard.cursorGap
        }

        GlassFrame {
            id: frame
            theme: root.theme
            x: placement.x
            y: placement.y
            width: Math.min(root.theme.clipboard.width,
                window.screen ? window.screen.width - root.theme.clipboard.screenMargin * 2
                              : root.theme.clipboard.width)
            height: implicitHeight
            implicitHeight: header.height + list.implicitHeight

            MouseArea {
                anchors.fill: parent
                onClicked: event => event.accepted = true
            }

            Item {
                id: keyHandler
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.hide()
                Keys.onUpPressed: root.moveSelection(-1)
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onReturnPressed: root.activate()
                Keys.onEnterPressed: root.activate()
            }

            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: root.theme.clipboard.headerHeight

                MonoText {
                    theme: root.theme
                    anchors.left: parent.left
                    anchors.leftMargin: root.theme.geometry.outerPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CLIPBOARD"
                    tone: root.theme.colors.prompt
                    font.bold: true
                }
                MonoText {
                    theme: root.theme
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.geometry.outerPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.clipboard.entries.length.toString()
                    tone: root.theme.colors.textMuted
                    font.pixelSize: root.theme.typography.detailSize
                }
                Separator {
                    theme: root.theme
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                }
            }

            SelectableList {
                id: list
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                theme: root.theme
                model: root.clipboard.entries
                currentIndex: root.selectedIndex
                rowHeight: root.theme.clipboard.rowHeight
                maximumVisibleRows: root.theme.clipboard.maxVisibleRows
                emptyHeight: root.theme.clipboard.emptyHeight
                insetSelection: true
                hoverSelection: true
                onSelectionRequested: index => root.selectedIndex = index
                onActivationRequested: root.activate()

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: root.theme.clipboard.rowHeight

                    MonoText {
                        theme: root.theme
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.geometry.outerPadding
                        anchors.right: parent.right
                        anchors.rightMargin: root.theme.geometry.outerPadding
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.binary ? "󰋩  " + row.modelData.preview : row.modelData.preview
                        tone: row.index === root.selectedIndex
                            ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: root.selectedIndex = row.index
                        onClicked: root.activate()
                    }
                }

                MonoText {
                    theme: root.theme
                    anchors.centerIn: parent
                    visible: root.clipboard.entries.length === 0
                    text: root.clipboard.error || "剪貼簿是空的"
                    tone: root.theme.colors.textMuted
                    font.pixelSize: root.theme.typography.emptySize
                }
            }
        }
    }
}
