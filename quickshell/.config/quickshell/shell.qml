import Quickshell
import "services"

ShellRoot {
    Style { id: sharedTheme }
    CompositorService { id: compositorService }
    AudioService { id: audioService }
    NetworkService { id: networkService }
    ClockService { id: clockService }
    ApplicationsService { id: applicationsService }
    ClipboardService { id: clipboardService }
    InputMethodService { id: inputMethodService }
    NotificationService { id: notificationService; defaultTimeout: sharedTheme.notifications.defaultTimeout }
    WireGuardService { id: wireGuardService }

    InputMethodWindow {
        theme: sharedTheme
        inputMethod: inputMethodService
        compositor: compositorService
    }

    Launcher { theme: sharedTheme; applications: applicationsService }
    Clipboard {
        theme: sharedTheme
        clipboard: clipboardService
        compositor: compositorService
    }
    WireGuardWindow { theme: sharedTheme; wireguard: wireGuardService }
    TopBar {
        theme: sharedTheme
        compositor: compositorService
        audio: audioService
        network: networkService
        clock: clockService
        notifications: notificationService
    }
}
