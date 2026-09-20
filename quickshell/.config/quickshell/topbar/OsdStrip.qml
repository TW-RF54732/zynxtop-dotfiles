pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../services"

Item {
    id: root

    required property var theme
    required property OsdService osd
    required property real barHeight

    // New entries are prepended. Since TopBar anchors this strip by its right
    // edge, growing leftward leaves every existing card at the same screen x.
    readonly property var entries: {
        const result = osd.statuses.slice().reverse()
        if (osd.transientVisible) {
            result.unshift({
                id: "__transient__",
                icon: osd.transientIcon,
                text: osd.transientText,
                value: osd.transientValue,
                progress: osd.transientProgress,
                muted: osd.transientIcon === "muted",
                compact: false,
                transient: true
            })
        }
        return result
    }

    width: cardsRow.implicitWidth
    height: barHeight

    function synchronize() {
        const next = entries
        for (let i = cardModel.count - 1; i >= 0; --i) {
            if (!next.some(entry => String(entry.id) === cardModel.get(i).key))
                cardModel.setProperty(i, "removing", true)
        }
        for (let i = 0; i < next.length; ++i) {
            const key = String(next[i].id)
            let existing = -1
            for (let j = 0; j < cardModel.count; ++j) {
                if (cardModel.get(j).key === key) { existing = j; break }
            }
            if (existing < 0)
                cardModel.insert(i, {key: key, entry: next[i], removing: false})
            else {
                cardModel.setProperty(existing, "entry", next[i])
                cardModel.setProperty(existing, "removing", false)
            }
        }
    }

    ListModel { id: cardModel; dynamicRoles: true }
    onEntriesChanged: synchronize()
    Component.onCompleted: synchronize()

    function finishRemoval(key) {
        for (let i = cardModel.count - 1; i >= 0; --i) {
            if (cardModel.get(i).key === key && cardModel.get(i).removing) {
                cardModel.remove(i)
                return
            }
        }
    }

    Row {
        id: cardsRow
        height: root.barHeight
        spacing: root.theme.osd.gap

        Repeater {
            model: cardModel

            delegate: OsdCard {
                id: card
                required property var entry
                required property bool removing
                required property string key
                property real popupProgress: 0
                property bool ready: false

                theme: root.theme
                shown: true
                fixedHeight: root.barHeight
                compact: entry.compact === true
                width: compact ? root.barHeight
                    : entry.transient === true ? root.theme.osd.width
                    : Math.min(root.theme.osd.statusWidth, root.theme.osd.width)
                icon: entry.icon || "star"
                title: entry.text || ""
                value: entry.value || ""
                progress: entry.progress !== undefined ? entry.progress : -1
                progressMuted: entry.muted === true
                presentationOpacity: popupProgress
                transform: Translate {
                    y: (1 - card.popupProgress) * -card.height
                }

                function updatePopup() {
                    if (!ready)
                        return
                    popupProgress = removing ? 0 : 1
                }

                Component.onCompleted: {
                    ready = true
                    Qt.callLater(updatePopup)
                }
                onRemovingChanged: updatePopup()
                Behavior on popupProgress {
                    NumberAnimation {
                        duration: root.theme.notifications.slideDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: [0.22, 1, 0.36, 1, 1, 1]
                        onFinished: {
                            if (card.ready && card.removing && card.popupProgress <= 0)
                                root.finishRemoval(card.key)
                        }
                    }
                }
            }
        }
    }
}
