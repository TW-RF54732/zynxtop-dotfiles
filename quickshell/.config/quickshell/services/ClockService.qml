import Quickshell

Scope {
    readonly property date displayDate: new Date(clock.date.getTime()
        + clock.date.getTimezoneOffset() * 60 * 1000)
    readonly property bool daytime: displayDate.getHours() >= 6 && displayDate.getHours() < 18

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
