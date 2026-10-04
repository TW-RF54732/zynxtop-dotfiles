-- Hyprland Lua configuration entrypoint.
-- Modules are loaded in dependency-friendly order.

require("modules.env")
require("modules.monitors")
require("modules.programs")

require("modules.appearance")
require("modules.animations")
require("modules.layouts")
require("modules.input")
require("modules.misc")

require("modules.rules")
require("modules.permissions")
require("modules.autostart")
require("modules.keybinds")

-- plugins
require("plugins.dynamic_cursors")
require("modules.programs_appearance")

-- User settings live outside Stow; missing overrides preserve the base config.
local settingsRoot = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/settings-center/"
for _, name in ipairs({"hyprland.lua", "monitors.lua"}) do
    local path = settingsRoot .. name
    local file = io.open(path, "r")
    if file then
        file:close()
        dofile(path)
    end
end
