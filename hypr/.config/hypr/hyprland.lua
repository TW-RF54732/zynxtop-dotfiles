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
