import QtQuick

JsonProcessService {
    property var stats: ({})
    command: ["python3", Qt.resolvedUrl("system_stats.py").toString().replace("file://", "")]
    onMessageReceived: message => stats = message
    onDisconnected: stats = ({})
}
