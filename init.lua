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

local function dumpNodesToFile(nodes,pos1,pos2)
	-- first two lines are positions x:y:z
	-- each following line has a node id
	local mod_path = minetest.get_modpath("spleef")
	local dump_file = io.open(mod_path.."/dump.txt", "w")
	dump_file:write(pos1.x..":"..pos1.y..":"..pos1.z.."\n")
	dump_file:write(pos2.x..":"..pos2.y..":"..pos2.z.."\n")
	for i,v in ipairs(nodes) do
		dump_file:write(v.."\n")
	end
	io.close(dump_file)
end

local function spleefcircle(pos1,pos2,height,nodes,area,spleef_node_id)
	-- circle is (x-x0)^2 + (z-z0)^2 = radius^2
	-- point is part of a circle if (x-x0)^2 + (z-z0)^2 <= radius^2
	local heighty = pos1.y + height
	local radius = (pos2.x-pos1.x)/2
	local centerx = pos1.x+radius
	local centerz = pos1.z+radius
	local centerpos = {x=centerx,y=heighty+1,z=centerz}
	local powradius = math.pow(radius,2)
	minetest.log("info","centerpos "..centerx..":"..heighty..":"..centerz)

	for z=pos1.z,pos2.z do
		for x=pos1.x,pos2.x do
			if math.floor(math.pow(x-centerx,2)+math.pow(z-centerz,2)) <= powradius + 1 then -- point is in circle, +1 to round corners
				nodes[area:index(x,heighty,z)] = spleef_node_id
			end
		end
	end
	return centerpos
end

local function spleefsquare(pos1,pos2,height,nodes,area,spleef_node_id)
	local heighty = pos1.y + height
	local tppos = {x=pos2.x,y=heighty+1,z=pos2.z}
	for i in area:iter(pos1.x,heighty,pos1.z, pos2.x,heighty,pos2.z) do
		nodes[i] = spleef_node_id
	end
	return tppos
end

local function setspleetTeleporter(settopos,teleporttopos)
	minetest.set_node(settopos,{name="spleef:teleporter"})
	minetest.override_item("spleef:teleporter",{
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			player:setpos(teleporttopos)
		end
		})
end

local function placespleef(playerpos,facedir,spleef_size,space,nlevels,nodename,spleef_mode)
	spleef_size = spleef_size - 1 -- decrease by 1 to match caster's expectation
	if spleef_mode == "circle" and spleef_size%2 ~= 0 then -- spleefcircle needs an even number
		spleef_size = spleef_size + 1
	end
	space = space + 1 -- increment space to match caster's expectation

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

	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})
	local nodes = manip:get_data()

	dumpNodesToFile(nodes,pos1,pos2) -- the old nodes are saved

	local air_id = minetest.get_content_id("air")
	local spleef_node_id = minetest.get_content_id("default:"..nodename)
	local tppos = {}

	for i=1,nlevels*space do
		if spleef_mode == "square" then
			if i%space == 0 then
				minetest.log("info","square")
				tppos = spleefsquare(pos1,pos2,i,nodes,area,spleef_node_id) -- fill with spleef content
			else
				minetest.log("info","square air")
				spleefsquare(pos1,pos2,i,nodes,area,air_id) -- fill with air
			end
		elseif spleef_mode == "circle" then
			if i%space == 0 then
				minetest.log("info","circle")
				tppos = spleefcircle(pos1,pos2,i,nodes,area,spleef_node_id) -- fill with spleef content
			else
				minetest.log("info","circle air")
				spleefcircle(pos1,pos2,i,nodes,area,air_id) -- fill with air
			end
		end
	end

	-- write changes to map
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	setspleetTeleporter(tpnodepos,tppos)

end

local function restoreTerrain()
	local mod_path = minetest.get_modpath("spleef")
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

local goldblockNode = copy_table(minetest.registered_nodes["default:goldblock"]) -- copy table to add stuff
goldblockNode.description = "spleef teleporter"
goldblockNode.tiles = {"default_gold_block.png^default_tool_diamondshovel.png"}
goldblockNode.on_rightclick = function(pos, node, player, itemstack, pointed_thing)
minetest.chat_send_player(player:get_player_name(),"Spleef teleporter not set !")
end
minetest.register_node("spleef:teleporter",goldblockNode)

minetest.register_privilege("spleef", "Player can create a spleef arena")

minetest.register_chatcommand("spleef", {
	params = "undo | do <size> <nlevels> <space> [square|circle]",
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

		local spleef_size = tonumber(params[2]) -- <size>
		if not params[2] then
			minetest.log("info","[spleef] Missing parameter <size> !")
			return false, "[spleef] Missing parameter <size> !"
		elseif not spleef_size or spleef_size < 3 then -- spleef must be at least 3x3 to avoid complications
			minetest.log("info","[spleef] Invalid parameter <size> !")
			return false, "[spleef] Invalid parameter <size> !"
		end

		local nlevels = tonumber(params[3]) -- <nlevels>
		if not params[3] then
			minetest.log("info","[spleef] Missing parameter <nlevels> !")
			return false, "[spleef] Missing parameter <nlevels> !"
		elseif not nlevels or nlevels <= 0 then
			minetest.log("info","[spleef] Invalid parameter <nlevels> !")
			return false, "[spleef] Invalid parameter <nlevels> !"
		end

		local space = tonumber(params[4]) -- <space>
		if not params[4] then
			minetest.log("info","[spleef] Missing parameter <space> !")
			return false, "[spleef] Missing parameter <space> !"
		elseif not space or space <= 0 then
			minetest.log("info","[spleef] Invalid parameter <space> !")
			return false, "[spleef] Invalid parameter <space> !"
		end

		local spleef_mode = params[5] -- [square|circle]
		if not params[5] then
			spleef_mode = "square"
		elseif spleef_mode ~= "circle" and spleef_mode ~= "square" then
			minetest.log("info","[spleef] Invalid parameter [square|circle] !")
			return false, "[spleef] Invalid parameter [square|circle] !"
		end
		local nodename = "dirt"

		placespleef(playerpos,facedir,spleef_size,space,nlevels,nodename,spleef_mode)

		minetest.log("action","[spleef] Done!") -- everything went fine :D
		return true, "[spleef] Done."
	end,
})
