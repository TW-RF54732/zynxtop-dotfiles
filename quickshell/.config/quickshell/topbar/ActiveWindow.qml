import QtQuick
import "../components"

Item {
    id: root

    required property var theme
    required property string title

    visible: title.length > 0
    implicitWidth: label.implicitWidth
    implicitHeight: theme.topBar.height

    MonoText {
        id: label
        theme: root.theme
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        tone: root.theme.colors.textSecondary
        font.pixelSize: root.theme.topBar.textSize
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
