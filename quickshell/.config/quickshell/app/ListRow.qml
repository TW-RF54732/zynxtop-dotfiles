import QtQuick

// One row of a glass-sidebar list. Put a leading marker (swatch, StatusDot) as a child at
// x ≈ 8 and keep `textX` at 26; without one set `textX: 8`. `muted` is the "＋ …" add-row style.
Rectangle {
    id: root
    required property var theme
    property string text: ""
    property string detail: ""
    property bool mono: false
    property bool selected: false
    property bool muted: false
    property bool interactive: true
    property bool clickable: true
    property int textX: 26
    property color textColor: muted
        ? (hovered || selected ? theme.colors.textPrimary : theme.colors.textMuted)
        : (selected ? theme.colors.textPrimary : theme.colors.textSecondary)
    readonly property bool hovered: mouse.containsMouse
    signal clicked()

    implicitWidth: 160
    implicitHeight: 28
    radius: theme.app.eventRadius
    opacity: interactive ? 1 : 0.4
    color: (hovered && clickable) || selected ? theme.app.hover : "transparent"

    UiText {
        theme: root.theme
        x: root.textX
        width: parent.width - x - (detailText.text ? detailText.implicitWidth + 16 : 8)
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        mono: root.mono
        elide: Text.ElideRight
        color: root.textColor
    }
    UiText {
        id: detailText
        theme: root.theme
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        font.pixelSize: 11
        color: root.theme.colors.textMuted
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive && root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
