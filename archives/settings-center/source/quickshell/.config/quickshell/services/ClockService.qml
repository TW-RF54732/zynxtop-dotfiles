import Quickshell

Scope {
    id: root
    SettingsPreferences { id: preferences }
    readonly property string timeFormat: preferences.value("clock.format", "hh:mm")
    readonly property date displayDate: new Date(clock.date.getTime()
        + (preferences.value("clock.utc", true) ? clock.date.getTimezoneOffset() * 60 * 1000 : 0))
    readonly property bool daytime: displayDate.getHours() >= 6 && displayDate.getHours() < 18

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
