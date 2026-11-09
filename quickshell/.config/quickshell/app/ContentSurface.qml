import QtQuick

// Solid content area of an app window, beside the glass sidebar and under the title bar.
Rectangle {
    required property var theme
    color: theme.app.surface
    topLeftRadius: theme.app.contentRadius
}
