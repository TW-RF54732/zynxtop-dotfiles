import QtQuick
import Quickshell
import "../components"

Item {
    id: root
    required property var theme
    property string appIcon: ""
    property string appName: ""
    property string desktopEntry: ""
    property int candidateIndex: 0
    readonly property var candidates: {
        const icons = [appIcon]
        const normalize = value => String(value || "").toLowerCase().replace(/\.desktop$/, "").replace(/[^a-z0-9]/g, "")
        const ids = [desktopEntry, appName].map(normalize).filter(value => value.length > 0)
        const entry = desktopEntry ? DesktopEntries.byId(desktopEntry.replace(/\.desktop$/, "")) : null
        if (entry) icons.push(entry.icon)
        for (const app of DesktopEntries.applications.values) {
            if ([app.id, app.name, app.startupClass].some(value => ids.includes(normalize(value)))) icons.push(app.icon)
        }
        const result = []
        for (const icon of icons) {
            if (!icon) continue
            const url = icon.startsWith("/") ? "file://" + icon
                : /^[a-z][a-z0-9+.-]*:/i.test(icon) ? icon : Quickshell.iconPath(icon, true)
            if (url && !result.includes(url)) result.push(url)
        }
        return result
    }
    onCandidatesChanged: candidateIndex = 0
    Image {
        id: image
        anchors.fill: parent
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
        source: root.candidates[root.candidateIndex] || ""
        visible: status === Image.Ready
        onStatusChanged: if (status === Image.Error && root.candidateIndex + 1 < root.candidates.length) root.candidateIndex++
    }
    MonoIcon {
        anchors.fill: parent
        theme: root.theme
        name: "bell"
        visible: !image.visible
    }
}
