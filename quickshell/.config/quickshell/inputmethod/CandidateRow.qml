import QtQuick
import "../components"

InteractiveSurface {
    id: root
    required property var candidate
    property bool selected: false
    active: selected
    interactive: candidate.selectable === true
    implicitWidth: label.implicitWidth + value.implicitWidth + theme.inputMethod.padding * 2 + 12
    implicitHeight: theme.inputMethod.rowHeight
    radius: 0
    MonoText {
        id: label
        theme: root.theme
        anchors.left: parent.left
        anchors.leftMargin: root.theme.inputMethod.padding
        anchors.verticalCenter: parent.verticalCenter
        text: root.candidate.label || ""
        tone: root.theme.colors.textMuted
        font.pixelSize: root.theme.typography.detailSize
    }
    MonoText {
        id: value
        theme: root.theme
        anchors.left: label.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: root.theme.inputMethod.padding
        anchors.verticalCenter: parent.verticalCenter
        text: root.candidate.text || ""
        font.family: root.theme.inputMethod.fontFamily
        font.pixelSize: root.theme.inputMethod.fontSize
        tone: root.selected ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
        elide: Text.ElideRight
    }
}
