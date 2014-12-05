

-- global mod namespace
spleef = {}

spleef.mod_name = minetest.get_current_modname()
spleef.mod_path = minetest.get_modpath(spleef.mod_name)

local mod_name = spleef.mod_name
local mod_path = spleef.mod_path

local loadmodule = function(path)
	local file = io.open(path)
	if not file then
		minetest.log("error","["..mod_name.."] Unable to load "..path)
		return false
	end
	file:close()
	return dofile(path)
end

loadmodule(mod_path .. "/functions.lua")
loadmodule(mod_path .. "/restore.lua")
loadmodule(mod_path .. "/spleef.lua")
loadmodule(mod_path .. "/register.lua")

minetest.log("info","["..mod_name.."] mod enabled")