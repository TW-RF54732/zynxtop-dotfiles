import QtQuick
import Quickshell.Networking

QtObject {
    readonly property bool available: Networking.backend !== NetworkBackendType.None
    readonly property bool offline: available && Networking.connectivity === NetworkConnectivity.None
}
