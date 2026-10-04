import QtQuick
import "../components"

GlassFrame {
    id: root
    required property var inputMethod
    property real maximumWidth: theme.inputMethod.maxWidth
    readonly property real inset: theme.geometry.frameWidth
    implicitWidth: Math.ceil(Math.min(maximumWidth, Math.max(theme.inputMethod.minWidth,
        candidates.preferredWidth + inset * 2,
        headerMetrics.advanceWidth(inputMethod.preedit) + theme.inputMethod.padding * 2 + inset * 2,
        headerMetrics.advanceWidth(inputMethod.auxiliary) + theme.inputMethod.padding * 2 + inset * 2)))
    implicitHeight: inset * 2
        + (compositionHeader.visible ? compositionHeader.implicitHeight : 0)
        + (auxiliaryHeader.visible ? auxiliaryHeader.implicitHeight : 0)
        + (divider.visible ? divider.implicitHeight : 0)
        + (candidates.visible ? candidates.implicitHeight : 0)

    FontMetrics {
        id: headerMetrics
        font.family: root.theme.inputMethod.fontFamily
        font.pixelSize: root.theme.inputMethod.fontSize
    }

    Column {
        id: contents
        x: root.inset
        y: root.inset
        width: root.width - root.inset * 2
        CompositionText {
            id: compositionHeader
            theme: root.theme
            composition: root.inputMethod.preedit
            visible: root.inputMethod.preedit.length > 0
            width: parent.width - root.theme.inputMethod.padding * 2
            x: root.theme.inputMethod.padding
            topPadding: root.theme.inputMethod.padding
            bottomPadding: root.theme.inputMethod.padding
        }
        CompositionText {
            id: auxiliaryHeader
            theme: root.theme
            composition: root.inputMethod.auxiliary
            visible: root.inputMethod.auxiliary.length > 0
            width: parent.width - root.theme.inputMethod.padding * 2
            x: root.theme.inputMethod.padding
            topPadding: root.theme.inputMethod.padding
            bottomPadding: root.theme.inputMethod.padding
            tone: root.theme.colors.textSecondary
        }
        Separator {
            id: divider
            theme: root.theme
            width: parent.width
            visible: (root.inputMethod.preedit.length > 0 || root.inputMethod.auxiliary.length > 0)
                && root.inputMethod.candidates.length > 0
        }
        CandidatePages {
            id: candidates
            theme: root.theme
            // Like Launcher, draw the inset curves against the full frame width.
            x: -root.inset
            width: root.width
            maximumWidth: root.maximumWidth - root.inset * 2
            pageNumber: root.inputMethod.pageNumber || 1
            pageDirection: root.inputMethod.pageDirection || 0
            pageRevision: root.inputMethod.pageRevision || 0
            candidates: root.inputMethod.candidates
            selectedIndex: root.inputMethod.selectedIndex
            horizontal: root.theme.inputMethod.horizontal
            visible: root.inputMethod.candidates.length > 0
            onCandidateSelected: index => root.inputMethod.select(index)
            onPageRequested: direction => {
                if (direction < 0) root.inputMethod.previousPage()
                else root.inputMethod.nextPage()
            }
        }
    }
}
