import Quickshell
import "services"

ShellRoot {
    Style { id: sharedTheme }
    CompositorService { id: compositorService }
    AudioService { id: audioService }
    NetworkService { id: networkService }
    // Owns persistent states, transient feedback, and the public OSD IPC.
    OsdService {
        id: osdService
        audio: audioService
        network: networkService
        defaultTransientTimeout: sharedTheme.osd.messageTimeout
        volumeTimeout: sharedTheme.osd.transientTimeout
    }
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
        osd: osdService
        clock: clockService
        notifications: notificationService
    }
}
