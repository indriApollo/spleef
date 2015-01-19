
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

spleef.round = function(x) -- rounds up (default floor rounds down)
	x = math.floor(x+0.5)
	return x
end

spleef.copy_table = function(t)
	local nt = {}
	for k, v in pairs(t) do
		nt[k] = v
	end
	return nt
end

-- spleef funcs 


spleef.spleefcirclerim = function(center,radius,height,nodes,area,spleef_node_id)
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

spleef.spleefcircle = function(center,radius,height,nodes,area,spleef_node_id)
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

spleef.spleefsquarerim = function(border,pos1,pos2,height,nodes,area,spleef_node_id)
	local z = 0
	for x=0,border do
		nodes[area:index(pos1.x+x,height,pos1.z)] = spleef_node_id
		nodes[area:index(pos1.x+x,height,pos2.z)] = spleef_node_id
		nodes[area:index(pos1.x,height,pos1.z+z)] = spleef_node_id
		nodes[area:index(pos2.x,height,pos1.z+z)] = spleef_node_id
		z = z + 1
	end
end

spleef.spleefsquare = function(pos1,pos2,height,nodes,area,spleef_node_id)
	for i in area:iter(pos1.x,height,pos1.z, pos2.x,height,pos2.z) do
		nodes[i] = spleef_node_id
	end
end

spleef.set_spleef_teleporter = function(settopos,teleporttopos)
	minetest.set_node(settopos,{name="spleef:teleporter"})
	minetest.override_item("spleef:teleporter",{
		on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			player:setpos(teleporttopos)
		end
		})
end
