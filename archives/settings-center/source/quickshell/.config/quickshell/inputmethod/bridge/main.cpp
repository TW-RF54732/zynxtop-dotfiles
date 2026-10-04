#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusServiceWatcher>
#include <QDBusVirtualObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QSocketNotifier>
#include <QTimer>
#include <cstdio>
#include <unistd.h>

// Kimpanel transport only. All presentation and interaction live in QML.
class Panel : public QDBusVirtualObject {
    Q_OBJECT
public:
    QDBusConnection bus = QDBusConnection::sessionBus();
    QJsonObject state{{"connected", false}, {"preedit", ""}, {"aux", ""},
        {"showPreedit", false}, {"showAux", false}, {"showCandidates", false},
        {"candidates", QJsonArray()}, {"selectedIndex", -1}, {"hasPrev", false},
        {"hasNext", false}, {"layout", 0}, {"position", QJsonObject{{"valid", false}}}};
    QTimer publish;
    QProcess geometry;
    QProcess nativeCaret;
    QTimer caretPoll;
    QByteArray input;
    bool relative = false;
    bool geometryDirty = false;
    bool nativeCoordinatesEnabled = !qEnvironmentVariableIsEmpty("HYPRLAND_INSTANCE_SIGNATURE");
    double scale = 1;
    int spotX = 0, spotY = 0, spotW = 0, spotH = 0;

    Panel() {
        publish.setSingleShot(true);
        connect(&publish, &QTimer::timeout, this, [this] {
            const auto data = QJsonDocument(state).toJson(QJsonDocument::Compact);
            fwrite(data.constData(), 1, data.size(), stdout);
            fputc('\n', stdout); fflush(stdout);
        });
        connect(&geometry, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int code, QProcess::ExitStatus) {
                const auto window = QJsonDocument::fromJson(geometry.readAllStandardOutput()).object();
                const auto at = window["at"].toArray();
                QJsonObject position{{"valid", false}};
                if (code == 0 && at.size() == 2 && !window["address"].toString().isEmpty()) {
                    position = {{"valid", true}, {"x", at[0].toDouble() + spotX / scale},
                        {"y", at[1].toDouble() + (spotY + spotH) / scale},
                        {"top", at[1].toDouble() + spotY / scale}};
                }
                state["position"] = position; changed();
                if (geometryDirty) { geometryDirty = false; resolvePosition(); }
            });
        connect(&geometry, &QProcess::errorOccurred, this, [this] {
            state["position"] = QJsonObject{{"valid", false}}; changed();
        });
        geometry.setProgram("hyprctl"); geometry.setArguments({"-j", "activewindow"});
        nativeCaret.setProgram("hyprctl"); nativeCaret.setArguments({"-j", "quickshell-caret"});
        caretPoll.setInterval(50);
        connect(&caretPoll, &QTimer::timeout, this, [this] {
            if (nativeCaret.state() == QProcess::NotRunning) nativeCaret.start();
        });
        connect(&nativeCaret, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
            [this](int code, QProcess::ExitStatus) {
                const auto position = QJsonDocument::fromJson(nativeCaret.readAllStandardOutput()).object();
                if (code == 0 && position["valid"].toBool() && state["connected"].toBool()
                    && position != state["position"].toObject()) {
                    state["position"] = position; changed();
                }
            });
    }
    void changed() {
        const bool showing = state["connected"].toBool() && (state["showPreedit"].toBool()
            || state["showAux"].toBool() || state["showCandidates"].toBool());
        if (showing && nativeCoordinatesEnabled && !caretPoll.isActive()) {
            caretPoll.start();
            if (nativeCaret.state() == QProcess::NotRunning) nativeCaret.start();
        } else if (!showing) caretPoll.stop();
        if (!publish.isActive()) publish.start(0);
    }
    void resolvePosition() {
        // Native input-method-v2 contexts have no Kimpanel cursor rect. (0,0,0,0)
        // is missing data, not a caret at the screen origin.
        if (spotW == 0 && spotH == 0) {
            state["position"] = QJsonObject{{"valid", false}}; changed(); return;
        }
        if (!relative) {
            state["position"] = QJsonObject{{"valid", true}, {"x", spotX},
                {"y", spotY + spotH}, {"top", spotY}}; changed();
        } else if (geometry.state() == QProcess::NotRunning) geometry.start();
        else geometryDirty = true;
    }
    QString introspect(const QString &) const override {
        return QStringLiteral(
            "<interface name='org.kde.impanel2'>"
            "<method name='SetLookupTable'><arg type='as' direction='in'/><arg type='as' direction='in'/>"
            "<arg type='as' direction='in'/><arg type='b' direction='in'/><arg type='b' direction='in'/>"
            "<arg type='i' direction='in'/><arg type='i' direction='in'/></method>"
            "<method name='SetSpotRect'><arg type='i' direction='in'/><arg type='i' direction='in'/>"
            "<arg type='i' direction='in'/><arg type='i' direction='in'/></method>"
            "<method name='SetRelativeSpotRect'><arg type='i' direction='in'/><arg type='i' direction='in'/>"
            "<arg type='i' direction='in'/><arg type='i' direction='in'/></method>"
            "<method name='SetRelativeSpotRectV2'><arg type='i' direction='in'/><arg type='i' direction='in'/>"
            "<arg type='i' direction='in'/><arg type='i' direction='in'/><arg type='d' direction='in'/></method>"
            "</interface>");
    }
    bool handleMessage(const QDBusMessage &message, const QDBusConnection &connection) override {
        if (message.interface() != "org.kde.impanel2") return false;
        const auto args = message.arguments();
        if (message.member() == "SetLookupTable" && message.signature() == "asasasbbii") {
            const auto labels = qdbus_cast<QStringList>(args[0]);
            const auto texts = qdbus_cast<QStringList>(args[1]);
            QJsonArray items;
            for (int i = 0; i < texts.size(); ++i)
                items.append(QJsonObject{{"label", labels.value(i)}, {"text", texts[i]},
                    {"selectable", !labels.value(i).isEmpty()}});
            state["candidates"] = items; state["hasPrev"] = args[3].toBool();
            state["hasNext"] = args[4].toBool(); state["selectedIndex"] = args[5].toInt();
            state["layout"] = args[6].toInt(); changed();
        } else if ((message.member() == "SetSpotRect" && message.signature() == "iiii")
            || (message.member() == "SetRelativeSpotRect" && message.signature() == "iiii")
            || (message.member() == "SetRelativeSpotRectV2" && message.signature() == "iiiid")) {
            relative = message.member() != "SetSpotRect";
            spotX = args[0].toInt(); spotY = args[1].toInt();
            spotW = args[2].toInt(); spotH = args[3].toInt();
            scale = args.size() == 5 ? qMax(0.01, args[4].toDouble()) : 1;
            resolvePosition();
        } else return false;
        connection.send(message.createReply()); return true;
    }
    void send(const QString &name, const QVariantList &args = {}) {
        auto message = QDBusMessage::createSignal("/org/kde/impanel", "org.kde.impanel", name);
        message.setArguments(args); bus.send(message);
    }
    void backend(const QString &owner) {
        state["connected"] = !owner.isEmpty();
        state["showPreedit"] = false; state["showAux"] = false;
        state["showCandidates"] = false; state["candidates"] = QJsonArray();
        state["position"] = QJsonObject{{"valid", false}};
        changed(); if (!owner.isEmpty()) send("PanelCreated");
    }
    void command(const QJsonObject &object) {
        if (!state["connected"].toBool()) return;
        const auto action = object["action"].toString();
        if (action == "select") {
            const int index = object["index"].toInt(-1);
            const auto items = state["candidates"].toArray();
            if (state["showCandidates"].toBool() && index >= 0 && index < items.size()
                && items[index].toObject()["selectable"].toBool()) send("SelectCandidate", {index});
        } else if (action == "previous" && state["hasPrev"].toBool()) send("LookupTablePageUp");
        else if (action == "next" && state["hasNext"].toBool()) send("LookupTablePageDown");
    }
public slots:
    void preedit(const QString &text, const QString &) { state["preedit"] = text; changed(); }
    void aux(const QString &text, const QString &) { state["aux"] = text; changed(); }
    void showPreedit(bool value) { state["showPreedit"] = value; changed(); }
    void showAux(bool value) { state["showAux"] = value; changed(); }
    void showCandidates(bool value) { state["showCandidates"] = value; changed(); }
    void cursor(int value) { state["selectedIndex"] = value; changed(); }
    void caret(int value) { state["caret"] = value; changed(); }
    void enable(bool value) { if (!value) backend(""); }
};

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    Panel panel;
    if (!panel.bus.isConnected()) { fprintf(stderr, "Session D-Bus unavailable\n"); return 1; }
    // Do not replace or queue behind another desktop's input panel.
    if (!panel.bus.registerVirtualObject("/org/kde/impanel", &panel)
        || !panel.bus.registerService("org.kde.impanel")) {
        fprintf(stderr, "Cannot own Kimpanel service; another panel may be running\n"); return 1;
    }
    const QString service = "org.kde.kimpanel.inputmethod", path = "/kimpanel";
    const QString interface = "org.kde.kimpanel.inputmethod";
    const QList<QPair<QString, const char *>> subscriptions{
        {"UpdatePreeditText", SLOT(preedit(QString,QString))}, {"UpdateAux", SLOT(aux(QString,QString))},
        {"ShowPreedit", SLOT(showPreedit(bool))}, {"ShowAux", SLOT(showAux(bool))},
        {"ShowLookupTable", SLOT(showCandidates(bool))}, {"UpdateLookupTableCursor", SLOT(cursor(int))},
        {"UpdatePreeditCaret", SLOT(caret(int))}, {"Enable", SLOT(enable(bool))}};
    for (const auto &signal : subscriptions)
        panel.bus.connect(service, path, interface, signal.first, &panel, signal.second);
    QDBusServiceWatcher watcher(service, panel.bus, QDBusServiceWatcher::WatchForOwnerChange);
    QObject::connect(&watcher, &QDBusServiceWatcher::serviceOwnerChanged, &panel,
        [&panel](const QString &, const QString &, const QString &owner) { panel.backend(owner); });
    panel.backend(panel.bus.interface()->serviceOwner(service).value());
    QSocketNotifier stdinReady(STDIN_FILENO, QSocketNotifier::Read);
    QObject::connect(&stdinReady, &QSocketNotifier::activated, &app, [&] {
        char buffer[4096]; const auto count = ::read(STDIN_FILENO, buffer, sizeof(buffer));
        if (count <= 0) { app.quit(); return; }
        panel.input.append(buffer, count);
        if (panel.input.size() > 65536) { panel.input.clear(); return; }
        int newline;
        while ((newline = panel.input.indexOf('\n')) >= 0) {
            const auto line = panel.input.left(newline); panel.input.remove(0, newline + 1);
            panel.command(QJsonDocument::fromJson(line).object());
        }
    });
    return app.exec();
}
#include "main.moc"
