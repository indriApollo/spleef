
-- register nodes

local goldblockNode = spleef.copy_table(minetest.registered_nodes["default:goldblock"]) -- copy table to add stuff
goldblockNode.description = "spleef teleporter"
goldblockNode.tiles = {"spleef_top.png^default_tool_diamondshovel.png",
 "spleef_bottom.png","spleef_face.png","spleef_face.png","spleef_face.png","spleef_face.png"}
goldblockNode.on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		minetest.chat_send_player(player:get_player_name(),"Spleef teleporter not set !")
	end
minetest.register_node("spleef:teleporter",goldblockNode)

local dirtNode = spleef.copy_table(minetest.registered_nodes["default:dirt"]) -- copy table to add stuff
dirtNode.description = "spleef snow"
dirtNode.tiles = {"default_snow.png"}
minetest.register_node("spleef:snow",dirtNode)

-- register privilege

minetest.register_privilege("spleef", "Player can create a spleef arena")

-- register chatcommand

minetest.register_chatcommand("spleef", {
	params = "undo | do <nodename> <size> <nlevels> <space> [square|circle] [water|lava]",
	description = "Create a spleef arena. Use undo to restore terrain after an arena generation.",
	privs = {spleef = true},
	func = function(name,params)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, "Player not found"
		end
		local facedir = minetest.dir_to_facedir(player:get_look_dir())
		local playerpos = player:getpos()

		params = string.split(params," ") -- parameters are split to a table

		if not params[1] then -- undo | do
			minetest.log("info","["..spleef.mod_name.."] Missing parameter undo | do !")
			return false, "["..spleef.mod_name.."] Missing parameter undo | do !"
		elseif params[1] == "undo" then
			local retval ,errmsg = spleef.restoreTerrain("spleef_save")
			return retval, errmsg
			-- exit function after undo
		elseif params[1] ~= "do" then
			minetest.log("info","["..spleef.mod_name.."] Invalid parameter undo | do !")
			return false, "["..spleef.mod_name.."] Invalid parameter undo | do !"
		end

		local nodename = params[2] -- <nodename>
		local valid_nodenames = {
			snow = true,
			dirt = true,
			sand = true,
			desert = true,
			glass = true,
			gravel = true,
			leaves = true,
		}
		if not params[2] then
			minetest.log("info","["..spleef.mod_name.."] Missing parameter <nodename> !")
			return false, "["..spleef.mod_name.."] Missing parameter <nodename> !"
		elseif not valid_nodenames[nodename] then
			print(valid_nodenames[nodename])
			minetest.log("info","["..spleef.mod_name.."] Invalid parameter <nodename> !")
			return false, "["..spleef.mod_name.."] Invalid parameter <nodename> !"
		end

		local spleef_size = tonumber(params[3]) -- <size>
		if not params[3] then
			minetest.log("info","["..spleef.mod_name.."] Missing parameter <size> !")
			return false, "["..spleef.mod_name.."] Missing parameter <size> !"
		elseif not spleef_size or spleef_size < 3 then -- spleef must be at least 3x3 to avoid complications
			minetest.log("info","["..spleef.mod_name.."] Invalid parameter <size> !")
			return false, "["..spleef.mod_name.."] Invalid parameter <size> !"
		end

		local nlevels = tonumber(params[4]) -- <nlevels>
		if not params[4] then
			minetest.log("info","["..spleef.mod_name.."] Missing parameter <nlevels> !")
			return false, "["..spleef.mod_name.."] Missing parameter <nlevels> !"
		elseif not nlevels or nlevels <= 0 then
			minetest.log("info","["..spleef.mod_name.."] Invalid parameter <nlevels> !")
			return false, "["..spleef.mod_name.."] Invalid parameter <nlevels> !"
		end

		local space = tonumber(params[5]) -- <space>
		if not params[5] then
			minetest.log("info","["..spleef.mod_name.."] Missing parameter <space> !")
			return false, "["..spleef.mod_name.."] Missing parameter <space> !"
		elseif not space or space <= 0 then
			minetest.log("info","["..spleef.mod_name.."] Invalid parameter <space> !")
			return false, "["..spleef.mod_name.."] Invalid parameter <space> !"
		end

		local spleef_mode = params[6] -- [square|circle]
		if not params[6] then
			spleef_mode = "square"
		elseif spleef_mode ~= "circle" and spleef_mode ~= "square" then
			minetest.log("info","["..spleef.mod_name.."] Invalid parameter [square|circle] !")
			return false, "["..spleef.mod_name.."] Invalid parameter [square|circle] !"
		end

		local spleef_liquid = params[7] --[water|lava]
		if not params[7] then
			spleef_liquid = "water"
		elseif params[7] and spleef_liquid ~= "water" and spleef_liquid ~= "lava" then
			minetest.log("info","["..spleef.mod_name.."] Invalid parameter [water|lava] !")
			return false, "["..spleef.mod_name.."] Invalid parameter [water|lava] !"
		end

		if nodename ~= "snow" and not minetest.get_modpath("spleef_arena") then
			minetest.log("info","["..spleef.mod_name.."] You need to install the additional mod spleef_arena to use this content !")
			return false, "["..spleef.mod_name.."] You need to install the additional mod spleef_arena to use this content !"
		else -- https://github.com/jojoa1997/spleef_arena/blob/master/init.lua
			if nodename == "snow" then
				nodename = "spleef:snow"
			elseif nodename == "dirt" then
				nodename = "spleef_arena:spleef_block_dirt"
			elseif nodename == "glass" then
				nodename = "spleef_arena:spleef_block_glass"
			elseif nodename == "desert" then
				nodename = "spleef_arena:spleef_block_desert_sand"
			elseif nodename == "gravel" then
				nodename = "spleef_arena:spleef_block_gravel"
			elseif nodename == "sand" then
				nodename = "spleef_arena:spleef_block_sand"
			elseif nodename == "leaves" then
				nodename = "spleef_arena:spleef_block_leaves"
			end
		end

		spleef_liquid = "default:"..spleef_liquid.."_source"
		spleef.placespleef(playerpos,facedir,spleef_size,space,nlevels,nodename,spleef_mode,spleef_liquid)

		minetest.log("action","["..spleef.mod_name.."] Done!") -- everything went fine :D
		return true, "["..spleef.mod_name.."] Done."
	end,
})
