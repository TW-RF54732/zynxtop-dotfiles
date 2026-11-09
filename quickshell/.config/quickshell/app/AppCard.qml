import QtQuick

// Raised card with a 1px border: floating editors, info boxes, text areas.
Rectangle {
    required property var theme
    radius: theme.app.cardRadius
    color: theme.app.raised
    border.width: 1
    border.color: theme.app.cardBorder
}
