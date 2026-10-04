import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var entries: []
    property string error: ""
    signal refreshed()
    signal copied()

    function refresh() {
        if (!listProcess.running) listProcess.running = true
    }

    function copy(entry) {
        if (!entry || copyProcess.running) return
        const mime = entry.mime.length > 0 ? entry.mime : "text/plain;charset=utf-8"
        copyProcess.pendingCommand = ["sh", "-c",
            "printf '%s' \"$1\" | cliphist decode | wl-copy --type \"$2\"",
            "clipboard", entry.raw, mime]
        copyProcess.running = true
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        stdout: StdioCollector { id: listOutput }
        stderr: StdioCollector { id: listError }
        onExited: exitCode => {
            const parsed = []
            const lines = listOutput.text.split("\n")
            for (let i = 0; i < lines.length && parsed.length < 50; ++i) {
                const line = lines[i]
                const separator = line.indexOf("\t")
                if (separator < 1) continue
                const preview = line.slice(separator + 1).trim()
                const binary = preview.startsWith("[[ binary data")
                let mime = ""
                if (binary) {
                    const match = preview.match(/\b(png|jpe?g|webp|gif|bmp|tiff?)\b/i)
                    if (match) {
                        const format = match[1].toLowerCase()
                        mime = "image/" + (format === "jpg" ? "jpeg" : format === "tif" ? "tiff" : format)
                    }
                }
                parsed.push({
                    raw: line,
                    preview: binary ? preview.replace(/^\[\[ binary data /, "").replace(/\]\]$/, "") : preview,
                    binary: binary,
                    mime: mime
                })
            }
            root.entries = parsed
            root.error = exitCode === 0 ? "" : (listError.text.trim() || "無法讀取剪貼簿")
            root.refreshed()
        }
    }

    Process {
        id: copyProcess
        property list<string> pendingCommand: []
        command: pendingCommand
        stderr: StdioCollector { id: copyError }
        onExited: exitCode => {
            root.error = exitCode === 0 ? "" : (copyError.text.trim() || "無法複製項目")
            if (exitCode === 0) root.copied()
        }
    }
}
