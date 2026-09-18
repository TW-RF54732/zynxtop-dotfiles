import QtQuick
import "../services"

QtObject {
    id: root
    required property ApplicationsService applications
    property string query: ""
    property bool showAll: false
    property int selectedIndex: 0
    property var results: []
    readonly property bool commandMode: query.trim().charAt(0) === ">"
    readonly property bool hasQuery: query.trim().length > 0
    readonly property bool expanded: hasQuery || showAll
    signal closeRequested()

    onQueryChanged: {
        if (query.trim().length > 0) showAll = false
        refreshResults()
    }

    function refreshResults() {
        results = applications.search(query, showAll)
        selectedIndex = Math.min(selectedIndex, Math.max(0, results.length - 1))
    }
    function reset() {
        showAll = false
        query = ""
        selectedIndex = 0
        refreshResults()
    }
    function showAllApplications() {
        showAll = true
        selectedIndex = 0
        refreshResults()
    }
    function activate() {
        if (commandMode) {
            applications.executeCommand(query.trim().slice(1).trim())
            closeRequested()
        } else if (results.length > 0) {
            applications.launch(results[selectedIndex].app)
            closeRequested()
        }
    }
}
