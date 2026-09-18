import QtQml
import QtQml.Models

ListModel {
    id: root
    // Plain display records only: keep QObject-backed application models separate.
    property var items: []
    property var signatures: []
    signal refreshed(bool structureChanged)
    dynamicRoles: true

    onItemsChanged: synchronize()
    Component.onCompleted: synchronize()

    function synchronize() {
        const next = items || []
        const structural = count !== next.length
        let changed = structural
        const nextSignatures = []
        for (let i = 0; i < next.length; ++i) {
            const signature = JSON.stringify(next[i])
            nextSignatures.push(signature)
            if (i >= count) append({ entry: next[i] })
            else if (signatures[i] !== signature) {
                setProperty(i, "entry", next[i])
                changed = true
            }
        }
        if (count > next.length) remove(next.length, count - next.length)
        signatures = nextSignatures
        if (changed) refreshed(structural)
    }
}
