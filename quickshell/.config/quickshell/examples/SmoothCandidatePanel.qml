import QtQuick
import "../components"
import "../inputmethod"

GlassFrame {
    id: root
    required property var inputMethod
    property real maximumWidth: theme.inputMethod.maxWidth
    implicitWidth: Math.min(maximumWidth, list.preferredWidth + theme.geometry.frameWidth * 2)
    implicitHeight: contents.implicitHeight + theme.geometry.frameWidth * 2

    Column {
        id: contents
        x: root.theme.geometry.frameWidth
        y: root.theme.geometry.frameWidth
        width: root.width - root.theme.geometry.frameWidth * 2
        CompositionText {
            theme: root.theme
            composition: root.inputMethod.preedit
            x: root.theme.inputMethod.padding
            width: parent.width - root.theme.inputMethod.padding * 2
            topPadding: root.theme.inputMethod.padding
            bottomPadding: root.theme.inputMethod.padding
        }
        Separator { theme: root.theme; width: parent.width }
        SmoothCandidateList {
            id: list
            theme: root.theme
            x: -root.theme.geometry.frameWidth
            width: root.width
            selectionInset: 0
            maximumWidth: root.maximumWidth - root.theme.geometry.frameWidth * 2
            candidates: root.inputMethod.candidates
            selectedIndex: root.inputMethod.selectedIndex
            horizontal: root.inputMethod.layoutHint === 1
            onCandidateSelected: index => root.inputMethod.select(index)
        }
    }
}
