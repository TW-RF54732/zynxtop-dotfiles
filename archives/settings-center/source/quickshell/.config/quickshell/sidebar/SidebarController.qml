import QtQuick

QtObject {
    id: root
    property var screens: []
    property string focusedMonitorName: ""
    property var targetScreen: null
    property bool requestedVisible: false
    signal opened()

    function show() {
        if (requestedVisible) return;
        targetScreen = screens.find(screen => screen.name === focusedMonitorName)
            || screens[0] || null;
        if (!targetScreen) return;
        requestedVisible = true;
        opened();
    }
    function hide() { requestedVisible = false; }
    function toggle() {
        if (requestedVisible) hide();
        else show();
    }
    onScreensChanged: {
        if (targetScreen && !screens.includes(targetScreen)) hide();
    }
}
