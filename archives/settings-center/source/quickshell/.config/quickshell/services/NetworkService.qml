import QtQuick
import Quickshell.Networking

QtObject {
    readonly property bool available: Networking.backend !== NetworkBackendType.None
    readonly property bool offline: available && Networking.connectivity === NetworkConnectivity.None
    readonly property var connectedDevice: Networking.devices.values.find(device => device.connected) || null
    readonly property string interfaceName: connectedDevice ? connectedDevice.name : ""
}
