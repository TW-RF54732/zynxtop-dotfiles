import QtQuick
import "../components"

Item {
    id: root
    required property var theme
    property bool commandMode: false
    property alias text: query.text
    signal closeRequested()
    signal activationRequested()
    signal showAllRequested()
    signal selectionMoved(int delta)
    implicitHeight: theme.launcher.searchHeight

    function focusInput() { query.forceActiveFocus() }

    MonoText {
        theme: root.theme
        anchors.left: parent.left
        anchors.leftMargin: root.theme.geometry.outerPadding
        anchors.verticalCenter: parent.verticalCenter
        text: root.commandMode ? "$" : ">"
        tone: root.theme.colors.prompt
        font.pixelSize: root.theme.typography.promptSize
        font.bold: true
    }
    TextInput {
        id: query
        anchors.left: parent.left
        anchors.leftMargin: root.theme.launcher.inputLeftMargin
        anchors.right: parent.right
        anchors.rightMargin: root.theme.geometry.outerPadding
        anchors.verticalCenter: parent.verticalCenter
        color: root.theme.colors.textPrimary
        selectionColor: root.theme.colors.textSelection
        selectedTextColor: root.theme.colors.textPrimary
        font.family: root.theme.typography.family
        font.pixelSize: root.theme.typography.inputSize
        clip: true
        Keys.onEscapePressed: root.closeRequested()
        Keys.onReturnPressed: root.activationRequested()
        Keys.onEnterPressed: root.activationRequested()
        Keys.onTabPressed: event => {
            if (text.trim().length === 0) {
                root.showAllRequested()
                event.accepted = true
            }
        }
        Keys.onDownPressed: root.selectionMoved(1)
        Keys.onUpPressed: root.selectionMoved(-1)
    }
    Separator {
        theme: root.theme
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }
}
