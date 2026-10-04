import QtQuick
import "services"

QtObject {
    id: root
    property SettingsPreferences preferences: SettingsPreferences {}

    readonly property var colors: QtObject {
        readonly property color surface: Qt.rgba(17/255, 19/255, 24/255, root.preferences.value("surfaceOpacity", 0.76))
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
        readonly property string family: root.preferences.value("typography.family", "JetBrainsMono Nerd Font Mono")
        readonly property int promptSize: root.preferences.value("typography.promptSize", 25)
        readonly property int inputSize: root.preferences.value("typography.inputSize", 21)
        readonly property int bodySize: root.preferences.value("typography.bodySize", 16)
        readonly property int detailSize: root.preferences.value("typography.detailSize", 12)
        readonly property int emptySize: root.preferences.value("typography.emptySize", 14)
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
        readonly property int maxWidth: root.preferences.value("launcher.maxWidth", 720)
        readonly property int screenMargin: root.preferences.value("launcher.screenMargin", 48)
        readonly property real verticalPosition: root.preferences.value("launcher.verticalPosition", 1 / 3)
        readonly property int searchHeight: root.preferences.value("launcher.searchHeight", 60)
        readonly property int resultHeight: root.preferences.value("launcher.resultHeight", 62)
        readonly property int emptyResultHeight: root.preferences.value("launcher.emptyResultHeight", 78)
        readonly property int footerHeight: root.preferences.value("launcher.footerHeight", 39)
        readonly property int maxVisibleResults: root.preferences.value("launcher.maxVisibleResults", 7)
        readonly property int iconSize: root.preferences.value("launcher.iconSize", 34)
        readonly property int inputLeftMargin: root.preferences.value("launcher.inputLeftMargin", 54)
        readonly property int resultTextLeftMargin: root.preferences.value("launcher.resultTextLeftMargin", 72)
        readonly property int resultSideMargin: root.preferences.value("launcher.resultSideMargin", 22)
        readonly property int resultTextSpacing: root.preferences.value("launcher.resultTextSpacing", 2)
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
        readonly property string fontFamily: root.preferences.value("inputMethod.fontFamily", "Noto Sans CJK TC")
        readonly property int fontSize: root.preferences.value("inputMethod.fontSize", 20)
        readonly property int minWidth: root.preferences.value("inputMethod.minWidth", 0)
        readonly property int maxWidth: root.preferences.value("inputMethod.maxWidth", 480)
        readonly property int rowHeight: root.preferences.value("inputMethod.rowHeight", 40)
        readonly property int maxVisibleRows: root.preferences.value("inputMethod.maxVisibleRows", 10)
        readonly property int padding: root.preferences.value("inputMethod.padding", 12)
        readonly property int screenMargin: root.preferences.value("inputMethod.screenMargin", 8)
        readonly property int cursorGap: root.preferences.value("inputMethod.cursorGap", 6)
        readonly property bool horizontal: root.preferences.value("inputMethod.horizontal", false)
    }

    readonly property var sidebar: QtObject {
        readonly property int width: root.preferences.value("sidebar.width", 400)
        readonly property int margin: root.preferences.value("sidebar.margin", 24)
        readonly property int padding: root.preferences.value("sidebar.padding", 20)
        readonly property int gap: root.preferences.value("sidebar.gap", 8)
        readonly property int animationDuration: root.preferences.value("sidebar.animationDuration", 220)
    }

    readonly property var dashboard: QtObject {
        readonly property int height: 300
        readonly property int gap: 8
        readonly property int animationDuration: 260
    }

    readonly property var notifications: QtObject {
        readonly property int laneWidth: root.preferences.value("notifications.laneWidth", 360)
        readonly property int cardWidth: root.preferences.value("notifications.cardWidth", 248)
        readonly property int iconWidth: root.preferences.value("notifications.iconWidth", root.topBar.height)
        readonly property int stackStep: root.preferences.value("notifications.stackStep", iconWidth)
        readonly property int overlap: root.preferences.value("notifications.overlap", 12)
        readonly property int padding: root.preferences.value("notifications.padding", 8)
        readonly property int gap: root.preferences.value("notifications.gap", 8)
        readonly property int defaultTimeout: root.preferences.value("notifications.defaultTimeout", 16000)
        readonly property int hoverCloseDelay: root.preferences.value("notifications.hoverCloseDelay", 180)
        readonly property int slideDuration: root.preferences.value("notifications.slideDuration", 320)
        readonly property int expandDuration: root.preferences.value("notifications.expandDuration", 500)
        readonly property int detailMaxLines: root.preferences.value("notifications.detailMaxLines", 4)
        readonly property int detailMaxHeight: root.preferences.value("notifications.detailMaxHeight", 100)
        readonly property int historyDetailMaxHeight: root.preferences.value("notifications.historyDetailMaxHeight", 160)
        readonly property int historyExpandDuration: root.preferences.value("notifications.historyExpandDuration", 280)
    }

    readonly property var osd: QtObject {
        readonly property int width: root.preferences.value("osd.width", root.notifications.cardWidth)
        readonly property int statusCardHeight: root.preferences.value("osd.statusCardHeight", 48)
        readonly property int statusWidth: root.preferences.value("osd.statusWidth", 160)
        readonly property int progressCardHeight: root.preferences.value("osd.progressCardHeight", root.topBar.height)
        readonly property int iconSize: root.preferences.value("osd.iconSize", 22)
        readonly property int progressHeight: root.preferences.value("osd.progressHeight", 5)
        readonly property int padding: root.preferences.value("osd.padding", root.notifications.padding)
        readonly property int gap: root.preferences.value("osd.gap", 8)
        readonly property int transientTimeout: root.preferences.value("osd.transientTimeout", 1400)
        readonly property int messageTimeout: root.preferences.value("osd.messageTimeout", 1800)
        readonly property int animationDuration: root.preferences.value("osd.animationDuration", 180)
    }

    readonly property var topBar: QtObject {
        readonly property int height: root.preferences.value("topBar.height", 48)
        readonly property int maxWidth: root.preferences.value("topBar.maxWidth", 2200)
        readonly property int sideMargin: root.preferences.value("topBar.sideMargin", 24)
        readonly property int topMargin: root.preferences.value("topBar.topMargin", 10)
        readonly property int bottomMargin: root.preferences.value("topBar.bottomMargin", 8)
        readonly property int radius: root.preferences.value("topBar.radius", 5)
        readonly property int horizontalPadding: root.preferences.value("topBar.horizontalPadding", 14)
        readonly property int itemSpacing: root.preferences.value("topBar.itemSpacing", 10)
        readonly property int workspaceSpacing: root.preferences.value("topBar.workspaceSpacing", 2)
        readonly property int workspaceSize: root.preferences.value("topBar.workspaceSize", 34)
        readonly property real workspaceSelectionOpacity: root.preferences.value("topBar.workspaceSelectionOpacity", 0.7)
        readonly property int iconSize: root.preferences.value("topBar.iconSize", root.geometry.iconSize)
        readonly property real iconStrokeWidth: root.preferences.value("topBar.iconStrokeWidth", root.geometry.iconStrokeWidth)
        readonly property int statusHitSize: root.preferences.value("topBar.statusHitSize", root.geometry.controlSize)
        readonly property int dividerWidth: root.preferences.value("topBar.dividerWidth", 1)
        readonly property int dividerHeight: root.preferences.value("topBar.dividerHeight", 20)
        readonly property real workspaceSweepWidth: root.preferences.value("topBar.workspaceSweepWidth", 0.2)
        readonly property int workspaceSweepHeight: root.preferences.value("topBar.workspaceSweepHeight", 2)
        readonly property int workspaceSweepDuration: root.preferences.value("topBar.workspaceSweepDuration", 400)
        readonly property int textSize: root.preferences.value("topBar.textSize", root.typography.bodySize)
        readonly property int clockSize: root.preferences.value("topBar.clockSize", 17)
        readonly property int windowHeight: root.preferences.value("topBar.windowHeight", topMargin + height + bottomMargin)
    }
}
