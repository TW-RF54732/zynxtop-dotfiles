import QtQuick

QtObject {
    // Coordinates are logical pixels in the selected screen's coordinate space.
    property real availableWidth: 0
    property real availableHeight: 0
    property real popupWidth: 0
    property real popupHeight: 0
    property real cursorX: 0
    property real cursorBottom: 0
    property real cursorTop: cursorBottom
    property bool cursorValid: false
    property real margin: 8
    property real gap: 6
    readonly property real x: Math.max(margin, Math.min(
        cursorValid ? cursorX : (availableWidth - popupWidth) / 2,
        availableWidth - popupWidth - margin))
    readonly property real y: {
        const below = cursorBottom + gap
        const preferred = cursorValid
            ? (below + popupHeight <= availableHeight - margin ? below : cursorTop - popupHeight - gap)
            : availableHeight - popupHeight - margin
        return Math.max(margin, Math.min(preferred, availableHeight - popupHeight - margin))
    }
}
