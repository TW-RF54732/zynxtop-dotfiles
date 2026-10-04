import QtQuick
import "../components"

MonoText {
    required property string composition
    text: composition
    font.family: theme.inputMethod.fontFamily
    font.pixelSize: theme.inputMethod.fontSize
    wrapMode: Text.Wrap
}
