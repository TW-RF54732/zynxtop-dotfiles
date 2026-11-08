import Quickshell

Scope {
    // Taipei (UTC+8, no DST): shift so the local-field getters read Taipei wall time.
    readonly property date displayDate: new Date(clock.date.getTime()
        + clock.date.getTimezoneOffset() * 60 * 1000 + 8 * 60 * 60 * 1000)
    // Fraction of the 24-hour day elapsed (0..1), shown under the 12-hour time.
    readonly property real dayProgress: (displayDate.getHours() * 60 + displayDate.getMinutes()) / (24 * 60)
    readonly property string timeText: {
        const h = displayDate.getHours() % 12 || 12
        return h + ":" + Qt.formatDateTime(displayDate, "mm")
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
