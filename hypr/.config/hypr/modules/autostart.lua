-------------------
---- AUTOSTART ----
-------------------
local programs = require("modules.programs")

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    -- hl.exec_cmd("mako")
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hyprpm reload")
    hl.exec_cmd("qs -n -d")
end)
