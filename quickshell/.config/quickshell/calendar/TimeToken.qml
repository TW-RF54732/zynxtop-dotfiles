import QtQuick
import "../app"
import "../sidebar/Calendar.js" as Calendar

// "HH:MM" token: wheel steps by the caller's snap; click to type ("930", "9:30", "15").
Item {
    id: root
    required property var theme
    property int minutes: 0
    property bool interactive: true
    property bool typing: false
    signal stepped(int direction)
    signal typed(int minutes)

    implicitWidth: Math.max(token.implicitWidth, input.contentWidth)
    implicitHeight: token.implicitHeight

    function finish() {
        if (!typing) return;
        const value = Calendar.parseTime(input.text);
        typing = false;
        if (value >= 0) typed(value);
    }

    Token {
        id: token
        theme: root.theme
        visible: !root.typing
        mono: true
        interactive: root.interactive
        text: Calendar.formatMinutes(root.minutes)
        onStepped: direction => root.stepped(direction)
        onClicked: {
            input.text = text;
            root.typing = true;
            input.forceActiveFocus();
            input.selectAll();
        }
    }
    TextInput {
        id: input
        visible: root.typing
        width: Math.max(contentWidth, token.implicitWidth)
        color: root.theme.colors.textPrimary
        selectionColor: root.theme.colors.textSelection
        selectedTextColor: root.theme.colors.textPrimary
        font.family: root.theme.typography.family
        font.pixelSize: 13
        maximumLength: 5
        onAccepted: root.finish()
        onActiveFocusChanged: if (!activeFocus) root.finish()
        Keys.onEscapePressed: event => { root.typing = false; event.accepted = true; }
        Rectangle {
            anchors.top: parent.bottom
            anchors.topMargin: 2
            width: parent.width
            height: 1
            color: root.theme.colors.textSecondary
        }
    }
}
