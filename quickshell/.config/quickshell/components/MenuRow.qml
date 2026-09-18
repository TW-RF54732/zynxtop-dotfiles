import QtQuick

InteractiveSurface {
    id: root
    required property var entry
    property bool selected: false
    interactive: entry.enabled !== false
    color: "transparent"
    opacity: interactive ? 1 : 0.35

    MonoIcon {
        id: icon
        theme: root.theme
        visible: !!root.entry.icon
        name: root.entry.icon || ""
        anchors.left: parent.left
        anchors.leftMargin: root.theme.geometry.outerPadding / 2
        anchors.verticalCenter: parent.verticalCenter
    }
    MonoText {
        theme: root.theme
        anchors.left: parent.left
        anchors.leftMargin: root.entry.icon
            ? root.theme.geometry.outerPadding + icon.width : root.theme.geometry.outerPadding / 2
        anchors.right: parent.right
        anchors.rightMargin: root.theme.geometry.outerPadding / 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.entry.text || ""
        tone: root.selected ? root.theme.colors.textPrimary : root.theme.colors.textSecondary
        elide: Text.ElideRight
    }
}
