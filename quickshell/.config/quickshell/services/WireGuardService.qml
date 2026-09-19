import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property alias profiles: profileData.profiles
    property alias selectedProfile: profileData.selectedProfile
    property bool monitoring: false
    property string activeState: "unknown"
    property string statusError: ""
    property string actionError: ""
    property string addError: ""
    property string pendingStatusProfile: ""
    property string actionProfile: ""
    property string pendingProfile: ""
    property string pendingConfig: ""
    property string tempPath: ""
    property string detailProfile: ""
    readonly property bool connected: activeState === "active"
    readonly property bool transitioning: activeState === "activating" || activeState === "deactivating"
    readonly property bool adding: tempWriter.running || installProcess.running
    readonly property bool busy: actionProcess.running || transitioning
    readonly property bool canToggle: !busy && !adding
                                              && (activeState === "active" || activeState === "inactive"
                                                  || activeState === "failed")
    readonly property string displayStatus: {
        if (actionProcess.running)
            return connected ? "DISCONNECTING" : "CONNECTING"
        if (activeState === "active") return "CONNECTED"
        if (activeState === "inactive") return "DISCONNECTED"
        if (activeState === "activating") return "CONNECTING"
        if (activeState === "deactivating") return "DISCONNECTING"
        if (activeState === "failed") return "FAILED"
        return statusProcess.running ? "CHECKING" : "UNAVAILABLE"
    }
    readonly property string actionLabel: {
        if (busy) return displayStatus + "…"
        if (activeState === "active") return "DISCONNECT"
        if (activeState === "inactive" || activeState === "failed") return "CONNECT"
        return "RETRY"
    }
    readonly property string error: actionError || statusError
    signal configurationAdded(string profile)

    FileView {
        id: profileFile
        path: Quickshell.stateDir + "/wireguard-profiles.json"
        blockLoading: true
        printErrors: false
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: profileData
            property var profiles: ["wg"]
            property string selectedProfile: "wg"
        }
    }

    function validProfile(value) {
        return /^[A-Za-z0-9_=+.-]{1,15}$/.test(String(value || ""))
    }

    function normalizeProfiles() {
        const source = Array.isArray(profiles) ? profiles : []
        const unique = []
        for (let i = 0; i < source.length; ++i) {
            const name = String(source[i])
            if (validProfile(name) && unique.indexOf(name) < 0) unique.push(name)
        }
        if (unique.indexOf("wg") < 0) unique.unshift("wg")
        profiles = unique
        if (unique.indexOf(selectedProfile) < 0) selectedProfile = unique[0]
    }

    function unitName(profile) {
        return "wg-quick@" + profile + ".service"
    }

    function applyState(value) {
        const normalized = String(value || "").trim()
        const known = ["active", "inactive", "activating", "deactivating", "failed"]
        activeState = known.indexOf(normalized) >= 0 ? normalized : "unknown"
    }

    function refresh() {
        if (statusProcess.running || !validProfile(selectedProfile)) return
        statusError = ""
        pendingStatusProfile = selectedProfile
        statusProcess.command = ["/usr/bin/systemctl", "show", unitName(pendingStatusProfile),
                                 "--property=ActiveState", "--value"]
        statusProcess.running = true
    }

    function toggle() {
        if (busy || adding) return
        if (!canToggle) {
            refresh()
            return
        }

        actionError = ""
        actionProfile = selectedProfile
        actionProcess.command = ["/usr/bin/pkexec", "/usr/bin/systemctl",
                                 connected ? "stop" : "start", unitName(actionProfile)]
        actionProcess.running = true
    }

    function addConfiguration(name, config) {
        if (adding || busy) return
        const profile = String(name || "").trim().replace(/\.conf$/i, "")
        const value = String(config || "").trim()
        if (!validProfile(profile)) {
            addError = "Name must be 1–15 letters, numbers, dots, dashes, or underscores"
            return
        }
        if (profiles.indexOf(profile) >= 0) {
            addError = "A configuration named " + profile + " is already registered"
            return
        }
        if (!/^\s*\[Interface\]\s*$/mi.test(value)) {
            addError = "Configuration must contain an [Interface] section"
            return
        }

        addError = ""
        pendingProfile = profile
        pendingConfig = value + "\n"
        tempPath = ""
        tempWriter.command = ["/usr/bin/python3",
            Qt.resolvedUrl("wireguard_config_temp.py").toString().replace("file://", "")]
        tempWriter.running = true
    }

    function cleanupTemp() {
        if (tempPath.indexOf("/tmp/quickshell-wireguard-") === 0)
            Quickshell.execDetached(["/usr/bin/rm", "-f", "--", tempPath])
        tempPath = ""
    }

    function loadFailureDetails(profile) {
        if (detailProcess.running || !validProfile(profile)) return
        detailProfile = profile
        detailProcess.command = ["/usr/bin/systemctl", "status", unitName(profile),
                                 "--no-pager", "--lines=8"]
        detailProcess.running = true
    }

    onSelectedProfileChanged: {
        activeState = "unknown"
        statusError = ""
        actionError = ""
        if (monitoring) refresh()
    }

    onMonitoringChanged: {
        if (monitoring) refresh()
        else pollTimer.stop()
    }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        running: root.monitoring
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess
        stdout: StdioCollector { id: statusOutput }
        stderr: StdioCollector { id: statusErrorOutput }
        onExited: exitCode => {
            if (root.pendingStatusProfile !== root.selectedProfile) return
            if (exitCode === 0) {
                root.applyState(statusOutput.text)
                root.statusError = ""
                if (root.activeState === "failed" && !root.actionError)
                    root.loadFailureDetails(root.selectedProfile)
            } else {
                root.applyState("unknown")
                root.statusError = statusErrorOutput.text.trim() || "Unable to read WireGuard status"
            }
        }
    }

    Process {
        id: actionProcess
        stderr: StdioCollector { id: actionErrorOutput }
        onExited: exitCode => {
            if (exitCode === 126 || exitCode === 127)
                root.actionError = "Authentication cancelled or denied"
            else if (exitCode !== 0)
                root.actionError = actionErrorOutput.text.trim() || "WireGuard action failed (" + exitCode + ")"
            if (root.actionProfile === root.selectedProfile) {
                if (exitCode !== 0) root.loadFailureDetails(root.actionProfile)
                root.refresh()
            }
        }
    }

    Process {
        id: tempWriter
        stdinEnabled: true
        stdout: SplitParser { onRead: data => root.tempPath = data.trim() }
        stderr: StdioCollector { id: tempErrorOutput }
        onStarted: write(JSON.stringify({ config: root.pendingConfig }) + "\n")
        onExited: exitCode => {
            root.pendingConfig = ""
            if (exitCode !== 0 || root.tempPath.indexOf("/tmp/quickshell-wireguard-") !== 0) {
                root.addError = tempErrorOutput.text.trim() || "Unable to prepare configuration"
                root.cleanupTemp()
                return
            }
            installProcess.command = ["/usr/bin/pkexec", "/usr/bin/install", "-m", "0600", "--",
                                      root.tempPath, "/etc/wireguard/" + root.pendingProfile + ".conf"]
            installProcess.running = true
        }
    }

    Process {
        id: installProcess
        stderr: StdioCollector { id: installErrorOutput }
        onExited: exitCode => {
            root.cleanupTemp()
            if (exitCode === 0) {
                const next = root.profiles.slice()
                next.push(root.pendingProfile)
                root.profiles = next
                root.selectedProfile = root.pendingProfile
                root.configurationAdded(root.pendingProfile)
            } else if (exitCode === 126 || exitCode === 127) {
                root.addError = "Authentication cancelled or denied"
            } else {
                root.addError = installErrorOutput.text.trim()
                    || "Unable to install WireGuard configuration (" + exitCode + ")"
            }
        }
    }

    Process {
        id: detailProcess
        stdout: StdioCollector { id: detailOutput }
        stderr: StdioCollector { id: detailErrorOutput }
        onExited: {
            if (root.detailProfile !== root.selectedProfile) return
            const details = (detailOutput.text || detailErrorOutput.text).trim()
            if (details) root.actionError = details
        }
    }
}
