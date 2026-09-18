pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import "components"

PanelWindow {
    id: launcher

    property int selectedIndex: 0
    property var results: []
    property bool commandMode: query.text.trim().charAt(0) === ">"
    property bool hasQuery: query.text.trim().length > 0
    property bool showAll: false
    property bool expanded: hasQuery || showAll
    property bool shown: false
    property real edgeBounceTarget: 0
    property real edgeBounceReturn: 0

    Style { id: style }

    FileView {
        id: usageFile
        property alias counts: usageData.counts
        path: Quickshell.stateDir + "/launcher-usage.json"
        blockLoading: true
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: usageData
            property var counts: ({})
        }
    }

    visible: false
    focusable: true
    exclusiveZone: 0
    anchors { top: true; right: true; bottom: true; left: true }
    color: "transparent"
    WlrLayershell.namespace: "quickshell-launcher"

    function show() {
        closeTimer.stop()
        visible = true
        showAll = false
        query.text = ""
        selectedIndex = 0
        refreshResults()
        query.forceActiveFocus()
        Qt.callLater(() => shown = true)
    }

    function hide() {
        shown = false
        closeTimer.restart()
    }

    function toggle() {
        if (visible && shown) hide()
        else show()
    }

    Timer {
        id: closeTimer
        interval: style.motion.fastDuration
        onTriggered: {
            launcher.visible = false
            launcher.showAll = false
            query.text = ""
        }
    }

    function score(entry, needle) {
        const name = entry.name.toLowerCase()
        const generic = (entry.genericName || "").toLowerCase()
        const keywords = (entry.keywords || []).join(" ").toLowerCase()
        if (name === needle) return 1000
        if (name.startsWith(needle)) return 700 - name.length
        const wordIndex = name.indexOf(" " + needle)
        if (wordIndex >= 0) return 500 - wordIndex
        const nameIndex = name.indexOf(needle)
        if (nameIndex >= 0) return 350 - nameIndex
        if (generic.indexOf(needle) >= 0) return 180
        if (keywords.indexOf(needle) >= 0) return 100

        let pos = -1
        let gap = 0
        for (let i = 0; i < needle.length; ++i) {
            const next = name.indexOf(needle.charAt(i), pos + 1)
            if (next < 0) return -1
            gap += next - pos - 1
            pos = next
        }
        return 80 - gap
    }

    function usageCount(entry) {
        return Number(usageFile.counts[entry.id] || 0)
    }

    function recordLaunch(entry) {
        const counts = Object.assign({}, usageFile.counts)
        counts[entry.id] = Number(counts[entry.id] || 0) + 1
        usageFile.counts = counts
    }

    function normalizedAppId(value) {
        return String(value || "")
            .toLowerCase()
            .replace(/\.desktop$/, "")
            .replace(/[^a-z0-9]/g, "")
    }

    function activateTrayItem(entry) {
        const appIds = [entry.id, entry.name, entry.startupClass, entry.icon]
            .map(normalizedAppId)
            .filter(value => value.length > 0)
        const items = SystemTray.items.values

        for (let i = 0; i < items.length; ++i) {
            const item = items[i]
            const trayIds = [item.id, item.title, item.icon, item.tooltipTitle]
                .map(normalizedAppId)
            if (trayIds.some(value => value.length > 0 && appIds.indexOf(value) >= 0)) {
                item.activate()
                return true
            }
        }
        return false
    }

    function refreshResults() {
        const needle = query.text.trim().toLowerCase()
        if (needle.length === 0 && !showAll) {
            results = []
            selectedIndex = 0
            return
        }
        if (needle.startsWith(">")) {
            results = []
            selectedIndex = 0
            return
        }

        const found = []
        const apps = DesktopEntries.applications.values
        for (let i = 0; i < apps.length; ++i) {
            const app = apps[i]
            if (app.noDisplay) continue
            if (showAll && needle.length === 0) {
                const launches = usageCount(app)
                found.push({ app: app, rank: launches, launches: launches })
                continue
            }
            const textRank = score(app, needle)
            if (textRank >= 0) {
                const launches = usageCount(app)
                const usageRank = Math.min(120, Math.log2(launches + 1) * 20)
                found.push({ app: app, rank: textRank + usageRank, launches: launches })
            }
        }
        found.sort((a, b) => b.rank - a.rank
            || b.launches - a.launches
            || a.app.name.localeCompare(b.app.name))
        results = found
        selectedIndex = Math.min(selectedIndex, Math.max(0, results.length - 1))
    }

    function moveSelection(delta) {
        if (results.length === 0) return
        const nextIndex = selectedIndex + delta
        if (nextIndex < 0 || nextIndex >= results.length) {
            bounceAtEdge(delta)
            return
        }

        const rowHeight = style.launcher.resultHeight
        const currentRowTop = selectedIndex * rowHeight - resultList.contentY
        const leavingVisibleEdge = delta > 0
            ? currentRowTop >= resultList.height - rowHeight
            : currentRowTop <= 0
        selectedIndex = nextIndex

        if (leavingVisibleEdge) {
            const centered = selectedIndex * rowHeight
                - (resultList.height - rowHeight) / 2
            const maximum = Math.max(0, resultList.contentHeight - resultList.height)
            animateListTo(Math.max(0, Math.min(maximum, centered)))
        }
    }

    function animateListTo(position) {
        edgeBounceAnimation.stop()
        listScrollAnimation.stop()
        listScrollAnimation.to = position
        listScrollAnimation.restart()
    }

    function bounceAtEdge(direction) {
        listScrollAnimation.stop()
        edgeBounceAnimation.stop()
        const maximum = Math.max(0, resultList.contentHeight - resultList.height)
        edgeBounceReturn = direction > 0 ? maximum : 0
        edgeBounceTarget = edgeBounceReturn
            + (direction > 0 ? style.motion.edgeBounceDistance : -style.motion.edgeBounceDistance)
        edgeBounceAnimation.restart()
    }

    NumberAnimation {
        id: listScrollAnimation
        target: resultList
        property: "contentY"
        duration: style.motion.listScrollDuration
        easing.type: Easing.Linear
    }

    SequentialAnimation {
        id: edgeBounceAnimation
        NumberAnimation {
            target: resultList
            property: "contentY"
            to: launcher.edgeBounceTarget
            duration: style.motion.edgeBounceDuration
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            target: resultList
            property: "contentY"
            to: launcher.edgeBounceReturn
            duration: style.motion.edgeBounceDuration
            easing.type: Easing.InQuad
        }
    }

    function activate() {
        if (commandMode) {
            const command = query.text.trim().slice(1).trim()
            if (command.length > 0)
                Quickshell.execDetached(["sh", "-lc", command])
            hide()
            return
        }
        if (results.length > 0) {
            const app = results[selectedIndex].app
            recordLaunch(app)
            if (!activateTrayItem(app))
                app.execute()
            hide()
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
        function show(): void { launcher.show() }
        function hide(): void { launcher.hide() }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launcher.hide()
    }

    GlassFrame {
        id: surface
        theme: style
        anchors.top: parent.top
        anchors.topMargin: parent.height * style.launcher.verticalPosition - searchBox.height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        readonly property real expandedWidth: Math.min(style.launcher.maxWidth,
                                                        parent.width - style.launcher.screenMargin)
        width: launcher.shown ? expandedWidth : 0
        height: searchBox.height
            + (launcher.expanded && !launcher.commandMode ? resultList.height : 0)
            + (launcher.expanded ? footer.height : 0)
        opacity: launcher.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: style.motion.fastDuration; easing.type: Easing.OutCubic }
        }

        Behavior on width {
            NumberAnimation { duration: style.motion.fastDuration; easing.type: Easing.OutCubic }
        }

        Behavior on height {
            NumberAnimation { duration: style.motion.fastDuration; easing.type: Easing.OutCubic }
        }

        MouseArea { anchors.fill: parent; onClicked: event => event.accepted = true }

        Rectangle {
            id: searchBox
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: style.launcher.searchHeight
            color: "transparent"

            MonoText {
                theme: style
                anchors.left: parent.left
                anchors.leftMargin: style.geometry.outerPadding
                anchors.verticalCenter: parent.verticalCenter
                text: launcher.commandMode ? "$" : ">"
                tone: style.colors.prompt
                font.pixelSize: style.typography.promptSize
                font.bold: true
            }

            TextInput {
                id: query
                anchors.left: parent.left
                anchors.leftMargin: style.launcher.inputLeftMargin
                anchors.right: parent.right
                anchors.rightMargin: style.geometry.outerPadding
                anchors.verticalCenter: parent.verticalCenter
                color: style.colors.textPrimary
                selectionColor: style.colors.textSelection
                selectedTextColor: style.colors.textPrimary
                font.family: style.typography.family
                font.pixelSize: style.typography.inputSize
                clip: true

                onTextChanged: {
                    if (text.trim().length > 0)
                        launcher.showAll = false
                    launcher.refreshResults()
                }
                Keys.onEscapePressed: launcher.hide()
                Keys.onReturnPressed: launcher.activate()
                Keys.onEnterPressed: launcher.activate()
                Keys.onTabPressed: event => {
                    if (text.trim().length === 0) {
                        launcher.showAll = true
                        launcher.selectedIndex = 0
                        launcher.refreshResults()
                        resultList.positionViewAtBeginning()
                        event.accepted = true
                    }
                }
                Keys.onDownPressed: launcher.moveSelection(1)
                Keys.onUpPressed: launcher.moveSelection(-1)
            }

            Separator {
                theme: style
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        InsetHighlight {
            id: selectionHighlight
            theme: style
            x: 0
            y: resultList.y - resultList.contentY - style.geometry.insetCurveRadius
            selectionOffset: launcher.selectedIndex * style.launcher.resultHeight
            width: surface.width
            height: style.launcher.resultHeight + style.geometry.insetCurveRadius * 2
            visible: resultList.visible && launcher.results.length > 0
            z: 1
        }

        ListView {
            id: resultList
            anchors.top: searchBox.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: launcher.results.length === 0
                ? style.launcher.emptyResultHeight
                : Math.min(style.launcher.maxVisibleResults, launcher.results.length)
                    * style.launcher.resultHeight
            visible: launcher.expanded && !launcher.commandMode
            clip: true
            z: 2
            model: launcher.results
            currentIndex: launcher.selectedIndex
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                    id: resultRow
                    required property var modelData
                    required property int index
                    width: resultList.width
                    height: style.launcher.resultHeight
                    color: "transparent"

                    IconImage {
                        anchors.left: parent.left
                        anchors.leftMargin: surface.border.width + style.launcher.resultSideMargin
                        anchors.verticalCenter: parent.verticalCenter
                        width: style.launcher.iconSize
                        height: style.launcher.iconSize
                        source: Quickshell.iconPath(resultRow.modelData.app.icon, true)
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.leftMargin: surface.border.width + style.launcher.resultTextLeftMargin
                        anchors.right: parent.right
                        anchors.rightMargin: surface.border.width + style.launcher.resultSideMargin
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: style.launcher.resultTextSpacing

                        MonoText {
                            theme: style
                            width: parent.width
                            text: resultRow.modelData.app.name
                            tone: resultRow.index === launcher.selectedIndex
                                ? style.colors.textPrimary : style.colors.textSecondary
                            elide: Text.ElideRight
                            font.pixelSize: style.typography.bodySize
                        }
                        MonoText {
                            theme: style
                            width: parent.width
                            text: resultRow.modelData.app.comment || resultRow.modelData.app.genericName || resultRow.modelData.app.id
                            tone: style.colors.textMuted
                            elide: Text.ElideRight
                            font.pixelSize: style.typography.detailSize
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: launcher.selectedIndex = resultRow.index
                        onClicked: launcher.activate()
                    }
                }

            MonoText {
                theme: style
                anchors.centerIn: parent
                visible: launcher.results.length === 0
                text: "no matching application"
                tone: style.colors.textMuted
                font.pixelSize: style.typography.emptySize
            }
        }

        Rectangle {
            id: footer
            visible: launcher.expanded
            anchors.top: launcher.commandMode ? searchBox.bottom : resultList.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: style.launcher.footerHeight
            color: "transparent"
            radius: style.geometry.cornerRadius

        }
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => query.forceActiveFocus())
    }
}
