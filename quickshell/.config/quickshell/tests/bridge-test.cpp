#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QProcess>
#include <QTimer>
#include <cstdio>

class Fixture : public QObject {
    Q_OBJECT
public:
    bool selected = false, paged = false;
public slots:
    void select(int index) { selected = index == 1; }
    void page() { paged = true; }
};
int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    if (argc != 2) return 2;
    auto bus = QDBusConnection::sessionBus();
    if (!bus.registerService("org.kde.kimpanel.inputmethod")) return 3;
    Fixture fixture;
    bus.connect("org.kde.impanel", "/org/kde/impanel", "org.kde.impanel",
        "SelectCandidate", &fixture, SLOT(select(int)));
    bus.connect("org.kde.impanel", "/org/kde/impanel", "org.kde.impanel",
        "LookupTablePageDown", &fixture, SLOT(page()));
    QProcess bridge;
    QByteArray output;
    bool snapshotOK = false;
    bool missingCaretOK = false;
    QObject::connect(&bridge, &QProcess::readyReadStandardOutput, &app, [&] {
        output += bridge.readAllStandardOutput();
        int newline;
        while ((newline = output.indexOf('\n')) >= 0) {
            const auto data = QJsonDocument::fromJson(output.left(newline)).object();
            output.remove(0, newline + 1);
            if (data["showCandidates"].toBool() && !data["position"].toObject()["valid"].toBool())
                missingCaretOK = true;
            if (data["showCandidates"].toBool() && data["candidates"].toArray().size() == 2
                && data["preedit"].toString() == "ㄓㄨㄥ" && data["selectedIndex"].toInt() == 1
                && data["position"].toObject()["y"].toInt() == 120) {
                snapshotOK = true;
                bridge.write("{\"action\":\"select\",\"index\":1}\n{\"action\":\"next\"}\n");
            }
        }
    });
    bridge.start(argv[1]);
    QTimer::singleShot(400, &app, [&] {
        auto method = QDBusMessage::createMethodCall("org.kde.impanel", "/org/kde/impanel",
            "org.kde.impanel2", "SetLookupTable");
        method.setArguments({QStringList{"1", "2"}, QStringList{"中文", "中午"},
            QStringList{"", ""}, false, true, 1, 0});
        if (bus.call(method).type() == QDBusMessage::ErrorMessage) { app.exit(4); return; }
        auto spot = QDBusMessage::createMethodCall("org.kde.impanel", "/org/kde/impanel",
            "org.kde.impanel2", "SetSpotRect");
        spot.setArguments({0, 0, 0, 0}); bus.call(spot);
        auto sendSignal = [&](const QString &name, const QVariantList &args) {
            auto message = QDBusMessage::createSignal("/kimpanel", "org.kde.kimpanel.inputmethod", name);
            message.setArguments(args); bus.send(message);
        };
        sendSignal("UpdatePreeditText", {QString("ㄓㄨㄥ"), QString()});
        sendSignal("ShowPreedit", {true}); sendSignal("ShowLookupTable", {true});
    });
    QTimer::singleShot(550, &app, [&] {
        auto spot = QDBusMessage::createMethodCall("org.kde.impanel", "/org/kde/impanel",
            "org.kde.impanel2", "SetSpotRect");
        spot.setArguments({100, 100, 2, 20}); bus.call(spot);
    });
    QTimer::singleShot(1000, &app, [&] {
        if (!snapshotOK || !missingCaretOK || !fixture.selected || !fixture.paged) {
            fprintf(stderr, "FAIL: Kimpanel data/selection/page round trip\n"); app.exit(5);
        } else { puts("PASS: Kimpanel data/selection/page round trip"); app.exit(0); }
    });
    const auto result = app.exec();
    bridge.closeWriteChannel();
    if (!bridge.waitForFinished(1000)) { bridge.kill(); bridge.waitForFinished(); }
    return result;
}
#include "bridge-test.moc"
