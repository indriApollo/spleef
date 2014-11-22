-- We want the spleef to be front-right of the caster
-- x: left(--), right(++)
-- y: front(++), back(--)
-- z: top(++),bottom(--)

--            z facedir 0
--                 ^
--                 |
--                 |
-- facedir 3  -----------> x facedir 1
--                 |
--                 |
--                 facedir 2
--
--          ___________ pos2
--         |           |
--         |           |
--         |           |
--         |           |
--         |___________|
--     pos1


-- dev funcs

local mod_path = minetest.get_modpath("spleef")

local function round(x) -- rounds up (default floor rounds down)
	x = math.floor(x+0.5)
	return x
end

local function copy_table(t)
	local nt = {}
	for k, v in pairs(t) do
		nt[k] = v
	end
	return nt
end

-- restore funcs


local function dumpNodesToFile(nodes,pos1,pos2)
	-- first two lines are positions x:y:z
	-- each following line has a node id
	local dump_file = io.open(mod_path.."/dump.txt", "w")
	dump_file:write(pos1.x..":"..pos1.y..":"..pos1.z.."\n")
	dump_file:write(pos2.x..":"..pos2.y..":"..pos2.z.."\n")
	for i,v in ipairs(nodes) do
		dump_file:write(v.."\n")
	end
	io.close(dump_file)
end

local function restoreTerrain()
	local dump_file = io.open(mod_path.."/dump.txt", "r")
	if not dump_file then -- no file, nothing to undo
		minetest.log("info","[spleef] Nothing to undo.")
		return false, "[spleef] Nothing to undo."
	end
	local content = {}
	for line in dump_file:lines() do
		table.insert (content, line);
	end
	local rawpos1 = string.split(content[1],":")
	local rawpos2 = string.split(content[2],":")
	if not rawpos1 or not rawpos2 then
		minetest.log("error","[spleef] Restore file corrupted !")
		return false, "[spleef] Restore file corrupted !"
	end
	local pos1 = {x=rawpos1[1],y=rawpos1[2],z=rawpos1[3]}
	local pos2 = {x=rawpos2[1],y=rawpos2[2],z=rawpos2[3]}

	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	table.remove(content,1) -- remove pos1 from content table
	table.remove(content,2) -- remove pos2 from content table
	-- table has now matching indices with nodes

	local nodes = manip:get_data()
	for i in area:iterp(pos1, pos2) do
		nodes[i] = content[i] -- old nodes back in nodes table
	end
	-- write changes to map
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	io.close(dump_file)
	os.remove(mod_path.."/dump.txt")
	return true, "[spleef] undo successful."
end

-- spleef funcs 


local function spleefcirclerim(center,radius,height,nodes,area,spleef_node_id)
	-- circle is (x-x0)^2 + (z-z0)^2 = radius^2

	-- http://en.wikipedia.org/wiki/Midpoint_circle_algorithm

	local x = radius
	local z = 0
	local radiusError = 1 - x
	while x >= z do
		nodes[area:index(x+center.x,height,z+center.z)] = spleef_node_id
		nodes[area:index(z+center.x,height,x+center.z)] = spleef_node_id
		nodes[area:index(-x+center.x,height,z+center.z)] = spleef_node_id
		nodes[area:index(-z+center.x,height,x+center.z)] = spleef_node_id
		nodes[area:index(-x+center.x,height,-z+center.z)] = spleef_node_id
		nodes[area:index(-z+center.x,height,-x+center.z)] = spleef_node_id
		nodes[area:index(x+center.x,height,-z+center.z)] = spleef_node_id
		nodes[area:index(z+center.x,height,-x+center.z)] = spleef_node_id
		z = z + 1
		if radiusError < 0 then
			radiusError = radiusError + 2*z+1
		else
			x = x - 1
			radiusError = radiusError + 2*(z-x+1)
		end
	end
end

local function spleefcircle(center,radius,height,nodes,area,spleef_node_id)
	local x = radius
	local z = 0
	local radiusError = 1 - x

	while x >= z do

		for i=0,x do
			nodes[area:index(i+center.x,height,z+center.z)] = spleef_node_id
			nodes[area:index(i+center.x,height,center.z-z)] = spleef_node_id
			nodes[area:index(center.x-i,height,z+center.z)] = spleef_node_id
			nodes[area:index(center.x-i,height,center.z-z)] = spleef_node_id
			nodes[area:index(z+center.x,height,i+center.z)] = spleef_node_id
			nodes[area:index(center.x-z,height,i+center.z)] = spleef_node_id
			nodes[area:index(z+center.x,height,center.z-i)] = spleef_node_id
			nodes[area:index(center.x-z,height,center.z-i)] = spleef_node_id
		end

		z = z + 1
		if radiusError < 0 then
			radiusError = radiusError + 2*z+1
		else
			x = x - 1
			radiusError = radiusError + 2*(z-x+1)
		end
	end
end

local function spleefsquarerim(border,pos1,pos2,height,nodes,area,spleef_node_id)
	local z = 0
	for x=0,border do
		nodes[area:index(pos1.x+x,height,pos1.z)] = spleef_node_id
		nodes[area:index(pos1.x+x,height,pos2.z)] = spleef_node_id
		nodes[area:index(pos1.x,height,pos1.z+z)] = spleef_node_id
		nodes[area:index(pos2.x,height,pos1.z+z)] = spleef_node_id
		z = z + 1
	end
end

local function spleefsquare(pos1,pos2,height,nodes,area,spleef_node_id)
	for i in area:iter(pos1.x,height,pos1.z, pos2.x,height,pos2.z) do
		nodes[i] = spleef_node_id
	end
end

local function setspleetTeleporter(settopos,teleporttopos)
	minetest.set_node(settopos,{name="spleef:teleporter"})
	minetest.override_item("spleef:teleporter",{
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			player:setpos(teleporttopos)
		end
		})
end

-- spleef core


local function placespleef(playerpos,facedir,spleef_size,space,nlevels,nodename,spleef_mode,spleef_liquid)
	spleef_size = spleef_size - 1 -- decrease by 1 to match caster's expectation
	if spleef_mode == "circle" and spleef_size%2 ~= 0 then -- spleefcircle needs an even number
		spleef_size = spleef_size + 1
	end
	space = space + 1 -- increment space to match caster's expectation (space + tickness level)

	local pos1 = {} -- pos1 is adjusted to always be the lower left corner (see top comments)
	local tpnodepos = {}
	if facedir == 0 then
		pos1 = {x=round(playerpos.x), y=round(playerpos.y), z=round(playerpos.z)+1}
		tpnodepos = pos1
	elseif facedir == 1 then
		pos1 = {x=round(playerpos.x)+1, y=round(playerpos.y), z=round(playerpos.z)-spleef_size}
		tpnodepos = {x=playerpos.x+1,y=playerpos.y,z=playerpos.z}
	elseif facedir == 2 then
		pos1 = {x=round(playerpos.x)-spleef_size, y=round(playerpos.y), z=round(playerpos.z)-spleef_size-1}
		tpnodepos = {x=playerpos.x,y=playerpos.y,z=playerpos.z-1}
	elseif facedir == 3 then
		pos1 = {x=round(playerpos.x)-spleef_size-1, y=round(playerpos.y), z=round(playerpos.z)}
		tpnodepos = {x=playerpos.x-1,y=playerpos.y,z=playerpos.z}
	end
	local pos2 = {x=pos1.x+spleef_size, y=pos1.y+space*nlevels, z=pos1.z+spleef_size} -- pos2 is the top right corner
	if spleef_liquid then
		pos1.y = pos1.y - 2 -- 2 lower to match size of bassin
	end

	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	local nodes = manip:get_data()

	dumpNodesToFile(nodes,pos1,pos2) -- the old nodes are saved

	local air_id = minetest.get_content_id("air")
	local spleef_node_id = minetest.get_content_id(nodename)
	local radius = (pos2.x-pos1.x)/2
	local border = pos2.x-pos1.x
	local centerx = pos1.x+radius
	local centerz = pos1.z+radius
	local center = {x=centerx,y=pos1.y,z=centerz}
	local tppos = {x=centerx,y=pos2.y+1,z=centerz}

	if spleef_liquid then
		local spleef_liquid_id = minetest.get_content_id(spleef_liquid)
		if spleef_mode == "circle" then
			spleefcircle(center,radius,pos1.y,nodes,area,spleef_node_id) -- bottom
			spleefcircle(center,radius,pos1.y+1,nodes,area,spleef_liquid_id) --liquid
			spleefcirclerim(center,radius,pos1.y+1,nodes,area,spleef_node_id) -- rim
		elseif spleef_mode == "square" then
			print('square bassin')
			spleefsquare(pos1,pos2,pos1.y,nodes,area,spleef_node_id) -- bottom
			spleefsquarerim(border,pos1,pos2,pos1.y+1,nodes,area,spleef_node_id) -- border
			local sqr_liq_pos1 = {x=pos1.x+1,y=pos1.y,z=pos1.z+1} -- liquid is square - tickness border
			local sqr_liq_pos2 = {x=pos2.x-1,y=pos2.y,z=pos2.z-1}
			spleefsquare(sqr_liq_pos1,sqr_liq_pos2,pos1.y+1,nodes,area,spleef_liquid_id) -- liquid
		end
		pos1.y = pos1.y + 1 -- setting right height for levels
	end

	for k=1,nlevels*space do
		if spleef_mode == "square" then
			if k%space == 0 then
				minetest.log("info","square")
				spleefsquare(pos1,pos2,pos1.y+k,nodes,area,spleef_node_id) -- fill with spleef content
			else
				minetest.log("info","square air")
				spleefsquare(pos1,pos2,pos1.y+k,nodes,area,air_id) -- fill with air
			end
		elseif spleef_mode == "circle" then
			if k%space == 0 then
				minetest.log("info","circle")
				spleefcircle(center,radius,pos1.y+k,nodes,area,spleef_node_id) -- fill with spleef content
			else
				minetest.log("info","circle air")
				spleefcircle(center,radius,pos1.y+k,nodes,area,air_id) -- fill with air
			end
		end
	end

	-- write changes to map
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	setspleetTeleporter(tpnodepos,tppos)

end


-- registering nodes

local goldblockNode = copy_table(minetest.registered_nodes["default:goldblock"]) -- copy table to add stuff
goldblockNode.description = "spleef teleporter"
goldblockNode.tiles = {"default_gold_block.png^default_tool_diamondshovel.png"}
goldblockNode.on_rightclick = function(pos, node, player, itemstack, pointed_thing)
minetest.chat_send_player(player:get_player_name(),"Spleef teleporter not set !")
end
minetest.register_node("spleef:teleporter",goldblockNode)

local dirtNode = copy_table(minetest.registered_nodes["default:dirt"]) -- copy table to add stuff
dirtNode.description = "spleef snow"
dirtNode.tiles = {"default_snow.png"}
minetest.register_node("spleef:snow",dirtNode)

-- registering privilege

minetest.register_privilege("spleef", "Player can create a spleef arena")

-- registering chatcommand

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
			minetest.log("info","[spleef] Missing parameter undo | do !")
			return false, "[spleef] Missing parameter undo | do !"
		elseif params[1] == "undo" then
			local retval ,errmsg = restoreTerrain()
			return retval, errmsg
			-- exit function after undo
		elseif params[1] ~= "do" then
			minetest.log("info","[spleef] Invalid parameter undo | do !")
			return false, "[spleef] Invalid parameter undo | do !"
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
			minetest.log("info","[spleef] Missing parameter <nodename> !")
			return false, "[spleef] Missing parameter <nodename> !"
		elseif not valid_nodenames[nodename] then
			print(valid_nodenames[nodename])
			minetest.log("info","[spleef] Invalid parameter <nodename> !")
			return false, "[spleef] Invalid parameter <nodename> !"
		end

		local spleef_size = tonumber(params[3]) -- <size>
		if not params[3] then
			minetest.log("info","[spleef] Missing parameter <size> !")
			return false, "[spleef] Missing parameter <size> !"
		elseif not spleef_size or spleef_size < 3 then -- spleef must be at least 3x3 to avoid complications
			minetest.log("info","[spleef] Invalid parameter <size> !")
			return false, "[spleef] Invalid parameter <size> !"
		end

		local nlevels = tonumber(params[4]) -- <nlevels>
		if not params[4] then
			minetest.log("info","[spleef] Missing parameter <nlevels> !")
			return false, "[spleef] Missing parameter <nlevels> !"
		elseif not nlevels or nlevels <= 0 then
			minetest.log("info","[spleef] Invalid parameter <nlevels> !")
			return false, "[spleef] Invalid parameter <nlevels> !"
		end

		local space = tonumber(params[5]) -- <space>
		if not params[5] then
			minetest.log("info","[spleef] Missing parameter <space> !")
			return false, "[spleef] Missing parameter <space> !"
		elseif not space or space <= 0 then
			minetest.log("info","[spleef] Invalid parameter <space> !")
			return false, "[spleef] Invalid parameter <space> !"
		end

		local spleef_mode = params[6] -- [square|circle]
		if not params[6] then
			spleef_mode = "square"
		elseif spleef_mode ~= "circle" and spleef_mode ~= "square" then
			minetest.log("info","[spleef] Invalid parameter [square|circle] !")
			return false, "[spleef] Invalid parameter [square|circle] !"
		end

		local spleef_liquid = params[7] --[water|lava]
		if params[7] and spleef_liquid ~= "water" and spleef_liquid ~= "lava" then
			minetest.log("info","[spleef] Invalid parameter [water|lava] !")
			return false, "[spleef] Invalid parameter [water|lava] !"
		end

		if nodename ~= "snow" and not minetest.get_modpath("spleef_arena") then
			minetest.log("info","[spleef] You need to install the additional mod spleef_arena to use this content !")
			return false, "[spleef] You need to install the additional mod spleef_arena to use this content !"
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
		placespleef(playerpos,facedir,spleef_size,space,nlevels,nodename,spleef_mode,spleef_liquid)

		minetest.log("action","[spleef] Done!") -- everything went fine :D
		return true, "[spleef] Done."
	end,
})
