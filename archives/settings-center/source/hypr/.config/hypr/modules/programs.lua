---------------------
---- MY PROGRAMS ----
---------------------

local programs = {
    terminal = "kitty",
    file_manager = "dolphin",
    menu = "qs ipc call launcher toggle",
    browser = "zen-browser",
}

local path = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/settings-center/programs.lua"
local file = io.open(path, "r")
if file then
    file:close()
    for key, value in pairs(dofile(path)) do programs[key] = value end
end
return programs
