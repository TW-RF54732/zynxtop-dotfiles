pragma ComponentBehavior: Bound
import QtQuick
import "../components"

SelectableList {
    id: root
    required property var results
    required property int selectedIndex
    model: results
    currentIndex: selectedIndex
    rowHeight: theme.launcher.resultHeight
    maximumVisibleRows: theme.launcher.maxVisibleResults
    emptyHeight: theme.launcher.emptyResultHeight
    insetSelection: true
    hoverSelection: true

    delegate: ResultRow {
        required property var modelData
        required property int index
        width: root.width
        theme: root.theme
        app: modelData.app
        selected: index === root.selectedIndex
        onActivated: root.activationRequested()
    }
    MonoText {
        theme: root.theme
        anchors.centerIn: parent
        visible: root.results.length === 0
        text: "no matching application"
        tone: root.theme.colors.textMuted
        font.pixelSize: root.theme.typography.emptySize
    }
}
