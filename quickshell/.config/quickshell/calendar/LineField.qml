import QtQuick

// Borderless one-line input; the placeholder doubles as the label. The hairline underline is
// always shown with `alwaysUnderline`, otherwise only on hover or focus.
Item {
    id: root
    required property var theme
    property alias text: input.text
    property alias readOnly: input.readOnly
    property string placeholder: ""
    property int pixelSize: 13
    property bool bold: false
    property bool mono: false
    property bool alwaysUnderline: false
    property color textColor: theme.colors.textPrimary
    readonly property bool editing: input.activeFocus
    signal accepted()

    function focusInput() {
        input.forceActiveFocus();
        input.selectAll();
    }

    implicitWidth: 200
    implicitHeight: input.implicitHeight + 5

    TextInput {
        id: input
        width: parent.width
        color: root.textColor
        selectionColor: root.theme.colors.textSelection
        selectedTextColor: root.theme.colors.textPrimary
        font.family: root.mono ? root.theme.typography.family : root.theme.app.uiFamily
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        clip: true
        selectByMouse: true
        onAccepted: root.accepted()
    }
    UiText {
        theme: root.theme
        anchors.left: input.left
        anchors.verticalCenter: input.verticalCenter
        visible: input.text === "" && !input.readOnly
        text: root.placeholder
        mono: root.mono
        font.pixelSize: root.pixelSize
        font.bold: root.bold
        color: root.theme.colors.textMuted
    }
    HoverHandler { id: hover; enabled: !input.readOnly }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: input.activeFocus ? root.theme.colors.textSecondary
            : hover.hovered ? root.theme.colors.textMuted
            : root.alwaysUnderline ? root.theme.app.raisedBorder : "transparent"
    }
}
