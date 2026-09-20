import QtQuick

QtObject {
    id: root

    readonly property var colors: QtObject {
        readonly property color surface: "#c2111318"
        readonly property color topBarSurface: "#a6111318"
        readonly property color frame: "#282C34"
        readonly property color separator: "#282C34"
        readonly property color prompt: "#B7BBC2"
        readonly property color textPrimary: "#FFFFFF"
        readonly property color textSecondary: "#ABB2BF"
        readonly property color textMuted: "#5C6370"
        readonly property color textSelection: "#5C6370"
        readonly property color status: "#ABB2BF"
    }

    readonly property var typography: QtObject {
        readonly property string family: "JetBrainsMono Nerd Font Mono"
        readonly property int promptSize: 25
        readonly property int inputSize: 21
        readonly property int bodySize: 16
        readonly property int detailSize: 12
        readonly property int emptySize: 14
    }

    readonly property var geometry: QtObject {
        readonly property int cornerRadius: 5
        readonly property int frameWidth: 5
        readonly property int insetCurveRadius: 5
        readonly property int separatorHeight: 1
        readonly property int outerPadding: 24
        readonly property int controlSize: 38
        readonly property int iconSize: 21
        readonly property real iconStrokeWidth: 1.7
    }

    readonly property var motion: QtObject {
        readonly property int fastDuration: 140
        readonly property int selectionDuration: 110
        readonly property int listScrollDuration: 180
        readonly property int edgeBounceDuration: 120
        readonly property int edgeBounceDistance: 18
    }

    readonly property var launcher: QtObject {
        readonly property int maxWidth: 720
        readonly property int screenMargin: 48
        readonly property real verticalPosition: 1 / 3
        readonly property int searchHeight: 60
        readonly property int resultHeight: 62
        readonly property int emptyResultHeight: 78
        readonly property int footerHeight: 39
        readonly property int maxVisibleResults: 7
        readonly property int iconSize: 34
        readonly property int inputLeftMargin: 54
        readonly property int resultTextLeftMargin: 72
        readonly property int resultSideMargin: 22
        readonly property int resultTextSpacing: 2
    }

    readonly property var clipboard: QtObject {
        readonly property int width: 520
        readonly property int headerHeight: 44
        readonly property int rowHeight: 48
        readonly property int maxVisibleRows: 8
        readonly property int emptyHeight: 72
        readonly property int screenMargin: 8
        readonly property int cursorGap: 6
    }

    readonly property var wireguard: QtObject {
        readonly property int width: 760
        readonly property int height: 500
        readonly property int sidebarWidth: 210
        readonly property int padding: 24
    }

    readonly property var inputMethod: QtObject {
        readonly property string fontFamily: "Noto Sans CJK TC"
        readonly property int fontSize: 20
        readonly property int minWidth: 0
        readonly property int maxWidth: 480
        readonly property int rowHeight: 40
        readonly property int maxVisibleRows: 10
        readonly property int padding: 12
        readonly property int screenMargin: 8
        readonly property int cursorGap: 6
        readonly property bool horizontal: false
    }

    readonly property var dashboard: QtObject {
        readonly property int height: 300
        readonly property int gap: 8
        readonly property int animationDuration: 260
    }

    readonly property var notifications: QtObject {
        readonly property int laneWidth: 360
        readonly property int cardWidth: 248
        readonly property int iconWidth: root.topBar.height
        readonly property int stackStep: iconWidth
        readonly property int overlap: 12
        readonly property int padding: 8
        readonly property int gap: 8
        readonly property int defaultTimeout: 16000
        readonly property int hoverCloseDelay: 180
        readonly property int slideDuration: 320
        readonly property int expandDuration: 500
        readonly property int detailMaxLines: 4
        readonly property int detailMaxHeight: 100
        readonly property int historyDetailMaxHeight: 160
    }

    readonly property var osd: QtObject {
        readonly property int width: root.notifications.cardWidth
        readonly property int statusCardHeight: 48
        readonly property int statusWidth: 160
        readonly property int progressCardHeight: root.topBar.height
        readonly property int iconSize: 22
        readonly property int progressHeight: 5
        readonly property int padding: root.notifications.padding
        readonly property int gap: 8
        readonly property int transientTimeout: 1400
        readonly property int messageTimeout: 1800
        readonly property int animationDuration: 180
    }

    readonly property var topBar: QtObject {
        readonly property int height: 48
        readonly property int maxWidth: 2200
        readonly property int sideMargin: 24
        readonly property int topMargin: 10
        readonly property int bottomMargin: 8
        readonly property int radius: 5
        readonly property int horizontalPadding: 14
        readonly property int itemSpacing: 10
        readonly property int workspaceSpacing: 2
        readonly property int workspaceSize: 34
        readonly property real workspaceSelectionOpacity: 0.7
        readonly property int iconSize: root.geometry.iconSize
        readonly property real iconStrokeWidth: root.geometry.iconStrokeWidth
        readonly property int statusHitSize: root.geometry.controlSize
        readonly property int dividerWidth: 1
        readonly property int dividerHeight: 20
        readonly property real workspaceSweepWidth: 0.2
        readonly property int workspaceSweepHeight: 2
        readonly property int workspaceSweepDuration: 400
        readonly property int textSize: root.typography.bodySize
        readonly property int clockSize: 17
        readonly property int windowHeight: topMargin + height + bottomMargin
    }
}
