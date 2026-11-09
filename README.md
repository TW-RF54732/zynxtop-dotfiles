# Dotfiles

Quickshell, Kitty, and Hyprland configurations managed with GNU Stow.

Install from this directory:

```sh
stow --no-folding --target="$HOME" quickshell kitty hypr
```

Each package stores its configuration under `<package>/.config/<package>/`.
Edit files in this repository; the links in `~/.config` use them directly.
`--no-folding` keeps configuration directories available for runtime files.
Runtime files such as `.qmlls.ini` remain in `~/.config/quickshell`.
Stow ignores `.gitignore` files; they are tracked in this repository and kept
as local copies where needed.

Hyprland retains the existing machine-specific monitor settings, wallpaper paths,
and local script paths. Wallpaper images and local scripts are not included.

The [Settings Center project](archives/settings-center/README.md) is archived:
its source and original plan are preserved for reference only. It is not in use
and is not part of the Stow packages installed above.

## SDDM login theme

`sddm/theme/` is a standalone QML greeter theme (`lolleo`) in the Quickshell
app-layer style: sharp wallpaper, one solid card, Chinese labels. Install with
root; it writes `/etc/sddm.conf.d/theme.conf` and generates the background from
your wallpaper (override with `WALLPAPER=/path/to.jpg`):

```sh
sudo ./sddm/install.sh
```

Preview without root (uses `xcb`; Qt on Wayland renders opaque windows in
16-bit, which tints dark colours green):

```sh
./sddm/preview.sh
```

## Lock screen

`hypr/` carries `hyprlock.conf`; `Super+L` locks the screen manually.

`hypridle.conf` (idle lock after 5 minutes) is kept but not autostarted. To
enable it, add `hl.exec_cmd("hypridle")` to `modules/autostart.lua`. Do not add
`hl.dsp.dpms` to it: that dispatch crashes Hyprland 0.57.1.
