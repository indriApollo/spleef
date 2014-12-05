
-- restore funcs

spleef.dumpNodesToFile = function(nodes,pos1,pos2)
	-- first two lines are positions x:y:z
	-- each following line has a node id
	local dump_file = io.open(spleef.mod_path.."/dump.txt", "w")
	dump_file:write(pos1.x..":"..pos1.y..":"..pos1.z.."\n")
	dump_file:write(pos2.x..":"..pos2.y..":"..pos2.z.."\n")
	for i,v in ipairs(nodes) do
		dump_file:write(v.."\n")
	end
	io.close(dump_file)
end

spleef.restoreTerrain = function()
	local dump_file = io.open(spleef.mod_path.."/dump.txt", "r")
	if not dump_file then -- no file, nothing to undo
		minetest.log("info","["..spleef.mod_name.."] Nothing to undo.")
		return false, "["..spleef.mod_name.."] Nothing to undo."
	end
	local content = {}
	for line in dump_file:lines() do
		table.insert (content, line);
	end
	local rawpos1 = string.split(content[1],":")
	local rawpos2 = string.split(content[2],":")
	if not rawpos1 or not rawpos2 then
		minetest.log("error","["..spleef.mod_name.."] Restore file corrupted !")
		return false, "["..spleef.mod_name.."] Restore file corrupted !"
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
	os.remove(spleef.mod_path.."/dump.txt")
	return true, "["..spleef.mod_name.."] undo successful."
end
