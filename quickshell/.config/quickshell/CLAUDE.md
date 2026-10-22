# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Quickshell (QML) desktop shell for Hyprland: Launcher, Top Bar (with notification strip and OSD), Dashboard, right-side Sidebar (user card, calendar, notification center), Clipboard history, Chinese input-method candidate window, and a WireGuard window. This directory is the `quickshell` package of a GNU Stow dotfiles repo (`~/dotfiles`, sibling packages `kitty`, `hypr`); `~/.config/quickshell` links back here. Docs (README, `docs/`) are written in Traditional Chinese; the README is the detailed behavior spec for each panel, so check it before changing UX.

## Commands

- Run the shell: `qs` (or `qs -p ~/.config/quickshell`). After adding new files, re-link: `cd ~/dotfiles && stow --no-folding --target="$HOME" quickshell`.
- IPC examples: `qs ipc call launcher toggle`, `qs ipc call topbar toggleDashboard`, `qs ipc call clipboard toggle`, `qs ipc call osd set <id> <icon> <text>`.
- Tests (each script copies the config to a temp dir, runs a `*-tests.qml` headlessly with `QT_QPA_PLATFORM=offscreen` and a 15s timeout, and greps the log for `FAIL:`/`ERROR`/`PASS: ...`):
  - `bash tests/run-smoke.sh` — `tests.qml` (whole-shell smoke)
  - `bash tests/run-notifications.sh` — notification service/strip/history (uses a private `dbus-run-session`; also runs the scroll tests and a history-reload pass)
  - `bash tests/run-pages.sh`, `run-sidebar.sh`, `run-sidebar-wayland.sh`, `run-ui-kit.sh`, `run-bridge.sh` (input-method C++ bridge)
  - To run a single suite, run the one script that owns it; there is no per-case filter. The test QML files live at the repo root (`notification-tests.qml`, `sidebar-tests.qml`, `page-tests.qml`, ...).
- Test scripts require `rg` and `python` on PATH. `notify-send "title" "body"` is the manual check for notifications (disable mako/dunst first).
- Input-method helpers are C++ built via `inputmethod/bridge/build.sh` and `inputmethod/hyprland-caret/ensure.sh`.

## Architecture

Layering (see `docs/MODULARITY.md`): `Style.qml` (theme: colors, fonts, geometry, per-panel sizes/animation times) → `components/` (generic visual pieces taking an injected `theme`) → `services/` (system state/operations) → feature folders (`launcher/`, `topbar/`, `dashboard/`, `notifications/`, `sidebar/`, `inputmethod/`) → top-level windows (`Launcher.qml`, `TopBar.qml`, `Dashboard.qml`, `Sidebar.qml`, `Clipboard.qml`, ...) → `shell.qml`.

Key rules:
- `shell.qml` instantiates the theme (`Style`) and every service **once**, then injects them into windows as properties (`theme`, `compositor`, `audio`, `notifications`, ...). Panels must not read Pipewire/Hyprland/Networking directly or duplicate styles; feature components communicate via properties and signals, never by referencing IDs in other files.
- Per-screen state goes through `services/MonitorContext.qml`; system services remain shared singletons-by-injection. Multi-monitor panels (Top Bar, notifications, Dashboard) mirror across all screens.
- `NotificationService` owns the single Quickshell `NotificationServer`, history persistence (`Quickshell.stateDir/notification-history.json`, max 500), and unread/read state; `notifications/NotificationStrip.qml` (Top Bar) and `dashboard/NotificationCenter.qml` (Sidebar) are views of it. Only one notification daemon may run on the desktop.
- Python helpers (`services/system_stats.py`, `system_status.py`, `user_info.py`, `wireguard_config_temp.py`) are run via `Process`/`JsonProcessService` and return JSON to QML services.
- Animation primitives are shared: `AnimatedVisibility` (deferred unload), `RevealSurface`, `AnimatedListView`, `PanelTransition`. Top Bar notification cards are drawn in one shared Canvas with opaque colors and opacity applied last to avoid blended overlaps; avoid changing this to per-card transparency.
- Visuals depend on Hyprland layer rules keyed on layer namespaces (`quickshell-launcher`, `quickshell-topbar`, `quickshell-topbar-glass`) for blur/xray; keep namespaces stable. Hyprland config itself lives in the sibling `hypr` package.
- Runtime state (launcher usage counts, notification history) goes in `Quickshell.stateDir`; `.qmlls.ini` is generated and gitignored.
- `archives/` (at repo root) holds the unused Settings Center prototype; it is not part of any Stow package.

## Design principles (owner's direction)

- **Style**: calm, minimal, unified. One look across all panels: Kitty `#111318` glass base, One Dark grays, monochrome `MonoIcon`/`MonoText`, small radius. Do not introduce colorful or inconsistent elements.
- **Top Bar is for focus only**: it permanently shows just the clock, the focused window title, and workspaces (plus transient OSD/notifications). Anything rarely used or visually unpredictable must not go there. Do not add tray icons, power buttons, system stats, or decorative widgets to it.
- **Dashboard is for system status and control**: it is pulled down on demand and holds system info, media/audio, tray, and power. Infrequent controls belong here, not in the Top Bar.
- **Tray**: third-party icons cannot be styled consistently and their count varies, so keep them only in the Dashboard as small (18px) icons inside the flyout card (`dashboard/TrayPanel.qml`); show nothing but a muted `EMPTY` when there are none.
- **Power**: a Dashboard icon button opens the power list in the same flyout card (entries shared with `PowerMenu.qml` via `services/powerEntries.js`). Lock/Sleep/Hibernate run directly; Reboot/power-off close the Dashboard and open the centered `PowerMenu.qml` confirmation (`showConfirm`; IPC: `qs ipc call powermenu toggle`). Confirmation never happens inline in the Dashboard.
- **Flyout**: the tray and power buttons share one floating card (`dashboard/DashboardFlyout.qml`) split off the Dashboard's right side: the Dashboard shrinks, the card is top-aligned, separated by `dashboard.gap`, styled like the Dashboard, and both contents share one width.
- **Dashboard layout**: keep the four-column arrangement `SYSTEM | OS (intentionally empty) | MEDIA/CONTROLS | TRAY/POWER buttons (slim 40px column)`, height 300px. The owner prefers this left/right balance; do not collapse it into equal halves or add a footer bar.
- **Top Bar center decoration**: undecided. Leave the center empty until the owner picks something; any decoration must not add polling cost or break focus.
- Prefer small, incremental changes over redesigns; show static previews before large visual changes.
