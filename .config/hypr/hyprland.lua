---@diagnostic disable: undefined-global
-- Hyprland Lua config, split into modules/ (one file per section).
-- https://wiki.hypr.land/Configuring/Start/

local dir = os.getenv("HOME") .. "/.config/hypr/"
package.path = dir .. "?.lua;" .. package.path

local modules = { "monitors", "autostart", "env", "look", "misc", "input", "binds", "rules" }

-- Drop require's cache first, so `hyprctl reload` re-runs edited modules even
-- if the Lua state outlives the reload.
package.loaded["modules.programs"] = nil
for _, m in ipairs(modules) do
	package.loaded["modules." .. m] = nil
end
for _, m in ipairs(modules) do
	require("modules." .. m)
end
