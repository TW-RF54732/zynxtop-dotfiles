//@ pragma AppId org.dotfiles.Settings
//@ pragma ShellId settings-center
//@ pragma StateDir $BASE/settings-center
import QtQuick
import Quickshell
import "settings"
import "services"

ShellRoot {
    Style { id: theme }
    AudioService { id: audio }
    WireGuardService { id: wireguard }
    SettingsWindow { theme: theme; audio: audio; wireguard: wireguard }
}
