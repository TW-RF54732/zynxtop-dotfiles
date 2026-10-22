import QtQuick
import "../components"

// Static fastfetch-style Arch logo, centered in its column so the left and right margins match.
Item {
    id: root
    required property var theme
    readonly property string logo: [
        "      /\\      ",
        "     /  \\     ",
        "    /\\   \\    ",
        "   /      \\   ",
        "  /   ,,   \\  ",
        " /   |  |  -\\ ",
        "/_-''    ''-_\\"
    ].join("\n")

    MonoText {
        anchors.centerIn: parent
        theme: root.theme
        text: root.logo
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        tone: root.theme.colors.textSecondary
        font.pixelSize: 18
        lineHeight: 1.0
    }
}
