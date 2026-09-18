import QtQuick
import Quickshell
import Quickshell.Wayland
import "components"
import "inputmethod"

Scope {
    id: root
    required property var theme
    required property var inputMethod
    required property var compositor
    property var retainedSnapshot: ({})
    readonly property var displayedPosition: visibility.mounted && !inputMethod.visible
        ? retainedSnapshot.position || ({ valid: false }) : inputMethod.cursorPosition
    function retainState() {
        if (inputMethod.visible) retainedSnapshot = inputMethod.snapshot
    }
    Component.onCompleted: retainState()
    Connections {
        target: root.inputMethod
        function onSnapshotChanged() { root.retainState() }
    }
    AnimatedVisibility {
        id: visibility
        requestedVisible: root.inputMethod.visible && root.targetScreen !== null
        duration: root.theme.motion.fastDuration
    }
    QtObject {
        id: presentation
        readonly property string preedit: root.retainedSnapshot.showPreedit ? root.retainedSnapshot.preedit || "" : ""
        readonly property string auxiliary: root.retainedSnapshot.showAux ? root.retainedSnapshot.aux || "" : ""
        readonly property var candidates: root.retainedSnapshot.showCandidates ? root.retainedSnapshot.candidates || [] : []
        readonly property int selectedIndex: root.retainedSnapshot.selectedIndex ?? -1
        readonly property bool hasPrevious: root.retainedSnapshot.hasPrev === true
        readonly property bool hasNext: root.retainedSnapshot.hasNext === true
        readonly property int layoutHint: root.retainedSnapshot.layout || 0
        function select(index) { root.inputMethod.select(index) }
        function previousPage() { root.inputMethod.previousPage() }
        function nextPage() { root.inputMethod.nextPage() }
    }
    readonly property var targetScreen: {
        const position = displayedPosition
        const screens = Quickshell.screens
        if (position.valid) {
            for (const screen of screens) {
                if (position.x >= screen.x && position.x < screen.x + screen.width
                    && position.top >= screen.y && position.top < screen.y + screen.height) return screen
            }
        }
        const window = compositor.activeWindow
        if (window && window.monitor) {
            for (const screen of screens) if (screen.name === window.monitor.name) return screen
        }
        return screens.length > 0 ? screens[0] : null
    }
    PanelWindow {
        id: window
        screen: root.targetScreen
        visible: visibility.mounted
        focusable: false
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        anchors { top: true; left: true }
        implicitWidth: panel.implicitWidth
        implicitHeight: Math.max(1, reveal.height)
        margins { left: placement.x; top: placement.y }
        WlrLayershell.namespace: "quickshell-inputmethod"
        PopupPlacement {
            id: placement
            availableWidth: window.screen ? window.screen.width : 0
            availableHeight: window.screen ? window.screen.height : 0
            popupWidth: window.implicitWidth
            popupHeight: window.implicitHeight
            cursorValid: root.displayedPosition.valid === true
            cursorX: (root.displayedPosition.x || 0) - (window.screen ? window.screen.x : 0)
            cursorBottom: (root.displayedPosition.y || 0) - (window.screen ? window.screen.y : 0)
            cursorTop: (root.displayedPosition.top || 0) - (window.screen ? window.screen.y : 0)
            margin: root.theme.inputMethod.screenMargin
            gap: root.theme.inputMethod.cursorGap
        }
        RevealSurface {
            id: reveal
            theme: root.theme
            shown: visibility.shown
            expandedWidth: panel.implicitWidth
            expandedHeight: panel.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter
            CandidatePanel {
                id: panel
                width: reveal.expandedWidth
                height: reveal.expandedHeight
                anchors.horizontalCenter: parent.horizontalCenter
                theme: root.theme
                inputMethod: presentation
                maximumWidth: Math.max(1, Math.min(root.theme.inputMethod.maxWidth,
                    placement.availableWidth - placement.margin * 2))
            }
        }
    }
}
