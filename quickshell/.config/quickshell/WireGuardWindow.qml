pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "components"
import "services"

FloatingWindow {
    id: root

    required property var theme
    required property WireGuardService wireguard
    property bool addMode: false

    title: "WireGuard"
    visible: false
    implicitWidth: root.theme.wireguard.width
    implicitHeight: root.theme.wireguard.height
    minimumSize: Qt.size(implicitWidth, implicitHeight)
    maximumSize: Qt.size(implicitWidth, implicitHeight)
    color: "transparent"

    function present() {
        root.visible = true
        root.minimized = false
        root.wireguard.refresh()
    }

    function dismiss() {
        root.closeEditor()
        root.visible = false
    }

    function toggleVisibility() {
        if (root.visible) dismiss()
        else present()
    }

    function openEditor() {
        root.wireguard.addError = ""
        tunnelName.text = ""
        configInput.text = ""
        root.addMode = true
        Qt.callLater(() => tunnelName.forceActiveFocus())
    }

    function closeEditor() {
        root.addMode = false
        tunnelName.text = ""
        configInput.text = ""
        root.wireguard.addError = ""
    }

    onVisibleChanged: wireguard.monitoring = visible
    onClosed: dismiss()

    Connections {
        target: root.wireguard
        function onConfigurationAdded() { root.closeEditor() }
    }

    IpcHandler {
        target: "wireguard"
        function show(): void { root.present() }
        function hide(): void { root.dismiss() }
        function toggle(): void { root.toggleVisibility() }
    }

    GlassFrame {
        anchors.fill: parent
        theme: root.theme

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.theme.geometry.frameWidth
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 12
                Layout.topMargin: 10
                Layout.bottomMargin: 10

                Item {
                    Layout.fillWidth: true
                    implicitHeight: appTitle.implicitHeight

                    MonoText {
                        id: appTitle
                        theme: root.theme
                        text: "WIREGUARD"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor
                        onPressed: root.startSystemMove()
                    }
                }

                TextButton {
                    theme: root.theme
                    text: "CLOSE"
                    implicitHeight: 30
                    onClicked: root.dismiss()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: root.theme.colors.separator
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ColumnLayout {
                    Layout.preferredWidth: root.theme.wireguard.sidebarWidth
                    Layout.fillHeight: true
                    spacing: 0

                    MonoText {
                        theme: root.theme
                        Layout.leftMargin: 16
                        Layout.topMargin: 16
                        Layout.bottomMargin: 8
                        text: "TUNNELS"
                        tone: root.theme.colors.textMuted
                        font.pixelSize: 11
                    }

                    ListView {
                        id: tunnelList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: root.wireguard.profiles
                        currentIndex: Math.max(0,
                            root.wireguard.profiles.indexOf(root.wireguard.selectedProfile))

                        delegate: InteractiveSurface {
                            id: tunnelRow
                            required property string modelData
                            required property int index
                            width: tunnelList.width
                            height: 48
                            theme: root.theme
                            active: index === tunnelList.currentIndex
                            onClicked: root.wireguard.selectedProfile = modelData

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 8
                                height: 8
                                radius: 4
                                color: tunnelRow.active && root.wireguard.connected
                                    ? root.theme.colors.textPrimary : root.theme.colors.textMuted
                            }

                            MonoText {
                                theme: root.theme
                                anchors.left: parent.left
                                anchors.leftMargin: 34
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                text: tunnelRow.modelData
                                tone: tunnelRow.active
                                    ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: root.theme.colors.separator
                    }

                    TextButton {
                        theme: root.theme
                        Layout.fillWidth: true
                        Layout.margins: 10
                        implicitHeight: 38
                        text: "+  ADD TUNNEL"
                        active: root.addMode
                        interactive: !root.wireguard.busy && !root.wireguard.adding
                        onClicked: root.openEditor()
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    implicitWidth: 1
                    color: root.theme.colors.separator
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 24
                    spacing: 14

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: !root.addMode
                        spacing: 14

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3

                                MonoText {
                                    theme: root.theme
                                    text: root.wireguard.selectedProfile
                                    font.pixelSize: 22
                                    font.bold: true
                                }
                                MonoText {
                                    theme: root.theme
                                    text: "WireGuard tunnel"
                                    tone: root.theme.colors.textMuted
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                implicitWidth: statusText.implicitWidth + 22
                                implicitHeight: 28
                                radius: root.theme.geometry.cornerRadius
                                color: root.theme.colors.frame

                                MonoText {
                                    id: statusText
                                    anchors.centerIn: parent
                                    theme: root.theme
                                    text: root.wireguard.displayStatus
                                    tone: root.wireguard.connected
                                        ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: root.theme.colors.separator
                        }

                        MonoText {
                            theme: root.theme
                            text: "STATUS"
                            tone: root.theme.colors.textMuted
                            font.pixelSize: 11
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 8

                            MonoText { theme: root.theme; text: "Interface"; tone: root.theme.colors.textMuted; font.pixelSize: 12 }
                            MonoText { theme: root.theme; text: root.wireguard.selectedProfile; font.pixelSize: 12 }
                            MonoText { theme: root.theme; text: "State"; tone: root.theme.colors.textMuted; font.pixelSize: 12 }
                            MonoText { theme: root.theme; text: root.wireguard.displayStatus; font.pixelSize: 12 }
                            MonoText { theme: root.theme; text: "Service"; tone: root.theme.colors.textMuted; font.pixelSize: 12 }
                            MonoText { theme: root.theme; text: root.wireguard.unitName(root.wireguard.selectedProfile); font.pixelSize: 12 }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: !root.addMode && root.wireguard.error !== ""
                        clip: true

                        MonoText {
                            theme: root.theme
                            width: parent.width
                            text: root.wireguard.error
                            tone: root.theme.colors.textSecondary
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                        visible: !root.addMode && root.wireguard.error === ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !root.addMode

                        Item { Layout.fillWidth: true }
                        TextButton {
                            theme: root.theme
                            implicitWidth: 150
                            implicitHeight: 42
                            text: root.wireguard.connected ? "DEACTIVATE" : "ACTIVATE"
                            active: root.wireguard.connected
                            interactive: !root.wireguard.busy && !root.wireguard.adding
                            onClicked: root.wireguard.toggle()
                        }
                    }

                    MonoText {
                        theme: root.theme
                        Layout.fillWidth: true
                        visible: root.addMode
                        text: "ADD EMPTY TUNNEL"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.addMode
                        spacing: 6

                        MonoText { theme: root.theme; text: "NAME"; tone: root.theme.colors.textMuted; font.pixelSize: 11 }
                        TextField {
                            id: tunnelName
                            Layout.fillWidth: true
                            implicitHeight: 38
                            color: root.theme.colors.textPrimary
                            selectionColor: root.theme.colors.textSelection
                            selectedTextColor: root.theme.colors.textPrimary
                            font.family: root.theme.typography.family
                            font.pixelSize: 13
                            placeholderText: "home, office, wg0…"
                            placeholderTextColor: root.theme.colors.textMuted
                            leftPadding: 10
                            rightPadding: 10
                            background: Rectangle {
                                color: root.theme.colors.frame
                                radius: root.theme.geometry.cornerRadius
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.addMode
                        spacing: 6

                        MonoText { theme: root.theme; text: "CONFIGURATION"; tone: root.theme.colors.textMuted; font.pixelSize: 11 }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: configInput
                                color: root.theme.colors.textPrimary
                                selectionColor: root.theme.colors.textSelection
                                selectedTextColor: root.theme.colors.textPrimary
                                font.family: root.theme.typography.family
                                font.pixelSize: 12
                                wrapMode: TextEdit.NoWrap
                                placeholderText: "[Interface]\nPrivateKey = …\nAddress = …\n\n[Peer]\nPublicKey = …"
                                placeholderTextColor: root.theme.colors.textMuted
                                padding: 12
                                background: Rectangle {
                                    color: root.theme.colors.frame
                                    radius: root.theme.geometry.cornerRadius
                                }
                            }
                        }
                    }

                    MonoText {
                        theme: root.theme
                        Layout.fillWidth: true
                        visible: root.addMode
                        text: root.wireguard.addError || "Only paste trusted configs; wg-quick hooks run as root."
                        tone: root.theme.colors.textSecondary
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.addMode

                        Item { Layout.fillWidth: true }
                        TextButton {
                            theme: root.theme
                            text: "CANCEL"
                            implicitHeight: 40
                            onClicked: root.closeEditor()
                        }
                        TextButton {
                            theme: root.theme
                            text: root.wireguard.adding ? "SAVING…" : "SAVE"
                            implicitWidth: 110
                            implicitHeight: 40
                            active: true
                            interactive: !root.wireguard.adding
                                && tunnelName.text.trim().length > 0
                                && configInput.text.trim().length > 0
                            onClicked: root.wireguard.addConfiguration(tunnelName.text, configInput.text)
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.addMode ? root.closeEditor() : root.dismiss()
    }
}
