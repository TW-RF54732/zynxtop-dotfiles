import QtQuick

Item {
    id: root

    required property var theme
    property bool shown: false
    property string icon: ""
    property string title: ""
    property string value: ""
    property real progress: -1
    property bool progressMuted: false
    property bool compact: false
    property real presentationOpacity: 1
    property real fixedHeight: -1

    readonly property real contentHeight: fixedHeight >= 0 ? fixedHeight
        : progress >= 0 ? theme.osd.progressCardHeight : theme.osd.statusCardHeight

    width: compact ? contentHeight : (parent ? parent.width : theme.osd.width)
    height: shown ? contentHeight : 0
    opacity: shown ? presentationOpacity : 0
    visible: height > 0
    clip: false

    GlassFrame {
        anchors.fill: parent
        theme: root.theme
        radius: root.theme.topBar.radius
        color: root.theme.colors.topBarSurface
        border.width: root.theme.topBar.dividerWidth
        border.color: root.theme.colors.separator

        MonoIcon {
            id: statusIcon
            theme: root.theme
            name: root.icon
            width: root.theme.osd.iconSize
            height: width
            anchors.left: root.compact ? undefined : parent.left
            anchors.leftMargin: root.compact ? 0 : root.theme.osd.padding
            anchors.horizontalCenter: root.compact ? parent.horizontalCenter : undefined
            anchors.verticalCenter: parent.verticalCenter
        }

        MonoText {
            id: titleText
            theme: root.theme
            text: root.title
            font.pixelSize: root.theme.topBar.textSize
            visible: text.length > 0
            anchors.left: statusIcon.right
            anchors.leftMargin: root.theme.osd.padding
            anchors.right: valueText.visible ? valueText.left : parent.right
            anchors.rightMargin: root.theme.osd.padding
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
        }

        MonoText {
            id: valueText
            theme: root.theme
            text: root.value
            visible: text.length > 0
            tone: root.theme.colors.textSecondary
            font.pixelSize: root.theme.typography.detailSize
            anchors.right: parent.right
            anchors.rightMargin: root.theme.osd.padding
            anchors.baseline: titleText.baseline
        }

        Rectangle {
            id: progressTrack
            visible: root.progress >= 0
            anchors.left: statusIcon.right
            anchors.leftMargin: root.theme.osd.padding
            anchors.right: valueText.left
            anchors.rightMargin: root.theme.osd.padding
            anchors.verticalCenter: parent.verticalCenter
            height: root.theme.osd.progressHeight
            radius: height / 2
            color: root.theme.colors.frame
            clip: true

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progress))
                height: parent.height
                radius: parent.radius
                color: root.progressMuted
                    ? root.theme.colors.textMuted : root.theme.colors.textSecondary
                Behavior on width {
                    NumberAnimation { duration: root.theme.motion.fastDuration; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
