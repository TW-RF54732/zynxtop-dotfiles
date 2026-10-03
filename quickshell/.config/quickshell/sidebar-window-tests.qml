import QtQuick
import QtTest
import Quickshell
import "services"

ShellRoot {
    Style { id: theme }
    CompositorService { id: compositor }
    ClockService { id: clock }
    UserService { id: user }
    NotificationService { id: notifications }
    Sidebar {
        id: sidebar
        theme: theme; compositor: compositor; clock: clock; user: user; notifications: notifications
    }
    Timer { interval: 200; running: true; onTriggered: pointer.exercise() }
    TestCase {
        id: pointer
        name: "SidebarWindow"
        when: false
        function exercise() {
            sidebar.show()
            wait(350)
            // Scope's default QQmlListProperty has no visual children count.
            const window = qtest_results.findChild(sidebar, "sidebarWindow")
            verify(window !== null && window.visible, "panel opens on Wayland")
            parent = window.contentItem
            // Use the actual target window when there is more than one monitor.
            const targetPanel = findChild(window.contentItem, "sidebarPanel")
            const calendar = findChild(targetPanel, "sidebarCalendar")
            const next = findChild(calendar, "nextMonthButton")
            const previousMonth = calendar.displayedMonth
            mouseClick(next, next.width / 2, next.height / 2, Qt.LeftButton)
            compare(calendar.displayedMonth, (previousMonth + 1) % 12)
            verify(window.visible, "calendar click keeps sidebar open")
            mouseClick(targetPanel, 8, 8, Qt.LeftButton)
            mouseClick(targetPanel, 8, 8, Qt.RightButton)
            wait(300)
            verify(window.visible, "panel padding consumes clicks")
            mouseClick(window.contentItem, 1, 1, Qt.LeftButton)
            wait(350)
            verify(!window.visible, "outside click closes sidebar")
            sidebar.show()
            wait(350)
            compare(calendar.displayedMonth, clock.displayDate.getMonth(), "reopen returns calendar to this month")
            keyClick(Qt.Key_Escape)
            wait(350)
            verify(!window.visible, "Escape closes sidebar")
            sidebar.show()
            wait(350)
            mouseClick(window.contentItem, 1, 1, Qt.RightButton)
            wait(350)
            verify(!window.visible, "outside right click closes sidebar")
            sidebar.toggle(); wait(40); sidebar.toggle(); wait(40); sidebar.toggle()
            wait(350)
            verify(window.visible, "rapid toggles settle open")
            sidebar.hide()
            wait(350)
            verify(!window.visible, "hide releases the overlay")
            console.log("PASS: sidebar Wayland click and keyboard checks")
            Qt.quit()
        }
    }
}
