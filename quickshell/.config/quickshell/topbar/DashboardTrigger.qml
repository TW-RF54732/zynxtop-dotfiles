import "../components"

IconButton {
    id: root
    signal toggled()
    implicitWidth: theme.topBar.statusHitSize
    implicitHeight: theme.topBar.height
    name: "dashboard"
    iconSize: theme.topBar.iconSize
    lineWidth: theme.topBar.iconStrokeWidth
    onClicked: root.toggled()
}
