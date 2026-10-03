import QtQuick
import QtQuick.Layouts
import "../components"

RowLayout {
    id: root
    required property var theme
    required property var user
    required property date today
    spacing: 14
    Rectangle {
        Layout.preferredWidth: 52
        Layout.preferredHeight: 52
        radius: root.theme.geometry.cornerRadius
        color: root.theme.colors.frame
        clip: true
        Image {
            id: avatarImage
            anchors.fill: parent
            source: root.user.avatar
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        MonoText {
            theme: root.theme
            anchors.centerIn: parent
            text: Array.from(root.user.displayName)[0] || "?"
            font.pixelSize: 24
            visible: avatarImage.status !== Image.Ready
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        MonoText {
            theme: root.theme
            Layout.fillWidth: true
            text: root.user.displayName
            textFormat: Text.PlainText
            elide: Text.ElideRight
        }
        MonoText {
            theme: root.theme
            Layout.fillWidth: true
            text: Qt.formatDate(root.today, "yyyy/MM/dd") + " · "
                + ["週日", "週一", "週二", "週三", "週四", "週五", "週六"][root.today.getDay()] + " UTC"
            font.pixelSize: 12
            tone: root.theme.colors.textSecondary
            elide: Text.ElideRight
        }
    }
}
