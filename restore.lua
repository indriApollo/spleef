
-- restore funcs

spleef.saveNodesToFile = function(nodes,pos1,pos2,file_name)
	-- first two lines are positions x:y:z
	-- each following line has a node id
	local save_file = io.open(spleef.mod_path.."/"..file_name, "w")
	local save_content = {pos1=pos1,pos2=pos2,nodenames={}}
	for i,v in ipairs(nodes) do
		save_content.nodenames[i] = minetest.get_name_from_content_id(v)
	end
	save_file:write(minetest.serialize(save_content))
	io.close(save_file)
end

spleef.restoreTerrain = function(file_name)
	local save_file = io.open(spleef.mod_path.."/"..file_name, "r")
	if not save_file then -- no file, nothing to undo
		minetest.log("info","["..spleef.mod_name.."] Nothing to undo.")
		return false, "["..spleef.mod_name.."] Nothing to undo."
	end
	local save_content = minetest.deserialize(save_file:read("*all"))
	local pos1 = save_content.pos1
	local pos2 = save_content.pos2
	local nodenames = save_content.nodenames

	if not pos1 or not pos2 or not nodenames then
		minetest.log("error","["..spleef.mod_name.."] Restore file corrupted !")
		return false, "["..spleef.mod_name.."] Restore file corrupted !"
	end

	local manip = minetest.get_voxel_manip()
	local emerged_pos1, emerged_pos2 = manip:read_from_map(pos1, pos2)
	local area = VoxelArea:new({MinEdge=emerged_pos1, MaxEdge=emerged_pos2})

	local nodes = manip:get_data()
	for i in area:iterp(pos1, pos2) do
		nodes[i] = minetest.get_content_id(nodenames[i]) -- old nodes back in nodes table
	end
	print("id "..minetest.get_content_id("foo:bar"))
	print('name '..minetest.get_name_from_content_id(127))
	-- write changes to map
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	io.close(save_file)
	os.remove(spleef.mod_path.."/"..file_name)
	return true, "["..spleef.mod_name.."] undo successful."
end
