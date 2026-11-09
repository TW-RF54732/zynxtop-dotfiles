import QtQuick
import QtQuick.Controls

// Multi-line mono input in a bordered card (pasting configs, notes). Placeholder is the label.
AppCard {
    id: root
    property alias text: area.text
    property string placeholder: ""
    property bool wrap: false
    readonly property bool editing: area.activeFocus

    function focusInput() { area.forceActiveFocus(); }

    radius: theme.app.eventRadius
    border.color: area.activeFocus ? theme.colors.textMuted : theme.app.raisedBorder

    ScrollView {
        anchors.fill: parent
        anchors.margins: 1
        clip: true
        TextArea {
            id: area
            color: root.theme.colors.textPrimary
            selectionColor: root.theme.colors.textSelection
            selectedTextColor: root.theme.colors.textPrimary
            font.family: root.theme.typography.family
            font.pixelSize: 12
            wrapMode: root.wrap ? TextEdit.Wrap : TextEdit.NoWrap
            placeholderText: root.placeholder
            placeholderTextColor: root.theme.colors.textMuted
            padding: 12
            background: null
        }
    }
}
