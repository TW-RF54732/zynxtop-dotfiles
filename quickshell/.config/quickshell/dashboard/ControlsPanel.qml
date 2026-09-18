pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../services"

ColumnLayout {
    id: root
    required property var theme
    required property AudioService audio
    spacing: 6

    RowLayout {
        Layout.fillWidth: true
        MonoText { theme: root.theme; Layout.fillWidth: true; text: "AUDIO"; tone: root.theme.colors.textSecondary; font.pixelSize: 12 }
        MonoText { theme: root.theme; font.pixelSize: 18; text: root.audio.available ? Math.round(root.audio.volume * 100) + "%" : "—" }
        TextButton { implicitWidth: 30; implicitHeight: 30; theme: root.theme; text: root.audio.muted ? "󰝟" : "󰕾"; active: root.audio.muted; interactive: root.audio.available; onClicked: root.audio.setMuted(!root.audio.muted) }
    }
    Rectangle {
        id: volumeBar
        Layout.fillWidth: true
        implicitHeight: 18
        color: "transparent"
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 5; radius: 2.5
            color: root.theme.colors.frame
            Rectangle { width: parent.width * root.audio.volume; height: parent.height; radius: parent.radius; color: root.audio.muted ? root.theme.colors.textMuted : root.theme.colors.textSecondary }
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.audio.available
            cursorShape: Qt.PointingHandCursor
            function updateVolume(x) { root.audio.setVolume(x / width) }
            onPressed: event => updateVolume(event.x)
            onPositionChanged: event => { if (pressed) updateVolume(event.x) }
            onWheel: event => root.audio.adjustVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }
    ComboBox {
        id: outputSelector
        Layout.fillWidth: true
        implicitHeight: 30
        model: root.audio.outputs
        textRole: "description"
        currentIndex: root.audio.outputs.indexOf(root.audio.sink)
        enabled: root.audio.outputs.length > 0
        displayText: root.audio.sink ? root.audio.sink.description || root.audio.sink.name : "NO OUTPUT"
        onActivated: index => root.audio.selectOutput(root.audio.outputs[index])
        contentItem: MonoText {
            theme: root.theme
            text: outputSelector.displayText
            font.pixelSize: 12
            tone: root.theme.colors.textSecondary
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
            rightPadding: 28
        }
        indicator: MonoText {
            theme: root.theme
            x: outputSelector.width - width - 8
            anchors.verticalCenter: parent.verticalCenter
            text: "▾"
            tone: root.theme.colors.textSecondary
        }
        background: Rectangle { radius: 4; color: root.theme.colors.frame }
        delegate: ItemDelegate {
            id: outputRow
            required property var modelData
            required property int index
            width: outputSelector.width
            height: 34
            highlighted: outputSelector.highlightedIndex === index
            contentItem: MonoText {
                theme: root.theme
                text: (outputRow.modelData === root.audio.sink ? "✓ " : "") + (outputRow.modelData.description || outputRow.modelData.name)
                font.pixelSize: 12
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { color: outputRow.highlighted ? root.theme.colors.frame : "transparent" }
        }
        popup: Popup {
            y: outputSelector.height + 4
            width: outputSelector.width
            height: Math.min(180, outputList.contentHeight + 8)
            padding: 4
            contentItem: ListView {
                id: outputList
                clip: true
                model: outputSelector.popup.visible ? outputSelector.delegateModel : null
                currentIndex: outputSelector.highlightedIndex
                ScrollIndicator.vertical: ScrollIndicator { }
            }
            background: Rectangle {
                color: root.theme.colors.surface
                border.color: root.theme.colors.separator
                border.width: 1
                radius: 4
            }
        }
    }
}
