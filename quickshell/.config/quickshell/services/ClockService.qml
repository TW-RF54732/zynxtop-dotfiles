import Quickshell

Scope {
    // Taipei (UTC+8, no DST): shift so the local-field getters read Taipei wall time.
    readonly property date displayDate: new Date(clock.date.getTime()
        + clock.date.getTimezoneOffset() * 60 * 1000 + 8 * 60 * 60 * 1000)
    // Top half filled = AM, bottom half filled = PM (12-hour clock).
    readonly property bool daytime: displayDate.getHours() < 12
    readonly property string timeText: {
        const h = displayDate.getHours() % 12 || 12
        return h + ":" + Qt.formatDateTime(displayDate, "mm")
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
