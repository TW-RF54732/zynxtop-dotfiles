import QtQuick
import Quickshell
import Quickshell.Widgets
import "../components"

Rectangle {
    id: resultRow
    required property var app
    required property var theme
    property bool selected: false
    signal hovered()
    signal activated()
    height: resultRow.theme.launcher.resultHeight
    color: "transparent"

    IconImage {
        anchors.left: parent.left
        anchors.leftMargin: resultRow.theme.geometry.frameWidth + resultRow.theme.launcher.resultSideMargin
        anchors.verticalCenter: parent.verticalCenter
        width: resultRow.theme.launcher.iconSize
        height: resultRow.theme.launcher.iconSize
        source: Quickshell.iconPath(resultRow.app.icon, true)
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: resultRow.theme.geometry.frameWidth + resultRow.theme.launcher.resultTextLeftMargin
        anchors.right: parent.right
        anchors.rightMargin: resultRow.theme.geometry.frameWidth + resultRow.theme.launcher.resultSideMargin
        anchors.verticalCenter: parent.verticalCenter
        spacing: resultRow.theme.launcher.resultTextSpacing

        MonoText {
            theme: resultRow.theme
            width: parent.width
            text: resultRow.app.name
            tone: resultRow.selected
                ? resultRow.theme.colors.textPrimary : resultRow.theme.colors.textSecondary
            elide: Text.ElideRight
            font.pixelSize: resultRow.theme.typography.bodySize
        }
        MonoText {
            theme: resultRow.theme
            width: parent.width
            text: resultRow.app.comment || resultRow.app.genericName || resultRow.app.id
            tone: resultRow.theme.colors.textMuted
            elide: Text.ElideRight
            font.pixelSize: resultRow.theme.typography.detailSize
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: resultRow.hovered()
        onClicked: resultRow.activated()
    }
}
