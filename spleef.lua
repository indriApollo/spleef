
-- spleef core

spleef.placespleef = function(playerpos,facedir,spleef_size,space,nlevels,nodename,spleef_mode,spleef_liquid)
	spleef_size = spleef_size - 1 -- decrease by 1 to match caster's expectation
	if spleef_mode == "circle" and spleef_size%2 ~= 0 then -- spleefcircle needs an even number
		spleef_size = spleef_size + 1
	end
	space = space + 1 -- increment space to match caster's expectation (space + tickness level)

	local pos1 = {} -- pos1 is adjusted to always be the lower left corner (see top comments)
	local tpnodepos = {}
	if facedir == 0 then
		pos1 = {x=spleef.round(playerpos.x), y=spleef.round(playerpos.y), z=spleef.round(playerpos.z)+1}
		tpnodepos = pos1
	elseif facedir == 1 then
		pos1 = {x=spleef.round(playerpos.x)+1, y=spleef.round(playerpos.y), z=spleef.round(playerpos.z)-spleef_size}
		tpnodepos = {x=playerpos.x+1,y=playerpos.y,z=playerpos.z}
	elseif facedir == 2 then
		pos1 = {x=spleef.round(playerpos.x)-spleef_size, y=spleef.round(playerpos.y), z=spleef.round(playerpos.z)-spleef_size-1}
		tpnodepos = {x=playerpos.x,y=playerpos.y,z=playerpos.z-1}
	elseif facedir == 3 then
		pos1 = {x=spleef.round(playerpos.x)-spleef_size-1, y=spleef.round(playerpos.y), z=spleef.round(playerpos.z)}
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

	spleef.saveNodesToFile(nodes,pos1,pos2,"spleef_save") -- the old nodes are saved

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
			spleef.spleefcircle(center,radius,pos1.y,nodes,area,spleef_node_id) -- bottom
			spleef.spleefcircle(center,radius,pos1.y+1,nodes,area,spleef_liquid_id) --liquid
			spleef.spleefcirclerim(center,radius,pos1.y+1,nodes,area,spleef_node_id) -- rim
		elseif spleef_mode == "square" then
			spleef.spleefsquare(pos1,pos2,pos1.y,nodes,area,spleef_node_id) -- bottom
			spleef.spleefsquarerim(border,pos1,pos2,pos1.y+1,nodes,area,spleef_node_id) -- border
			local sqr_liq_pos1 = {x=pos1.x+1,y=pos1.y,z=pos1.z+1} -- liquid is square - tickness border
			local sqr_liq_pos2 = {x=pos2.x-1,y=pos2.y,z=pos2.z-1}
			spleef.spleefsquare(sqr_liq_pos1,sqr_liq_pos2,pos1.y+1,nodes,area,spleef_liquid_id) -- liquid
		end
		pos1.y = pos1.y + 1 -- setting right height for levels
	end

	for k=1,nlevels*space do
		if spleef_mode == "square" then
			if k%space == 0 then
				minetest.log("info","square")
				spleef.spleefsquare(pos1,pos2,pos1.y+k,nodes,area,spleef_node_id) -- fill with spleef content
			else
				minetest.log("info","square air")
				spleef.spleefsquare(pos1,pos2,pos1.y+k,nodes,area,air_id) -- fill with air
			end
		elseif spleef_mode == "circle" then
			if k%space == 0 then
				minetest.log("info","circle")
				spleef.spleefcircle(center,radius,pos1.y+k,nodes,area,spleef_node_id) -- fill with spleef content
			else
				minetest.log("info","circle air")
				spleef.spleefcircle(center,radius,pos1.y+k,nodes,area,air_id) -- fill with air
			end
		end
	end

	-- write changes to map
	manip:set_data(nodes)
	manip:write_to_map()
	manip:update_map()

	spleef.set_spleef_teleporter(tpnodepos,tppos)

end
