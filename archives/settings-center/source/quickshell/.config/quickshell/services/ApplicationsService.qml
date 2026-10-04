import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Scope {
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

    function search(query, showAll) {
        return rankEntries(DesktopEntries.applications.values, query, showAll)
    }

    function rankEntries(apps, query, showAll) {
        const needle = query.trim().toLowerCase()
        if (needle.length === 0 && !showAll) {
            return []
        }
        if (needle.startsWith(">")) {
            return []
        }

        const found = []
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
        return found
    }

    function launch(app) {
        recordLaunch(app)
        if (!activateTrayItem(app))
            app.execute()
    }

    function executeCommand(command) {
        if (command.length > 0)
            Quickshell.execDetached(["sh", "-lc", command])
    }
}
