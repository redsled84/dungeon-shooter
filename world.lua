local bump = require "bump"
local Powerup = require "powerup"
local tilesize = require "tilesize"
local World = {}

function World.aabb(a, x, y, w, h)
	return a.x < x + w and a.x + a.width > x and
		a.y < y + h and a.y + a.height > y
end

function World:initialize(list)
	if self.world then
		local items, len = self.world:getItems()
		for i = 1, len do
			self.world:remove(items[i])
		end
	end

	self.world = bump.newWorld()
	self:addBlocksToWorld(list)
end

function World:addBlocksToWorld(list)
	for i = 1, #list do
		local p = list[i]
		if p.num == 1 then
			self:add(p.x * tilesize, p.y * tilesize, tilesize, tilesize)
		elseif p.num == 2 then
			local n = math.random(0, 2)
			local name = ""
			if n == 0 then
				name = "health"
			elseif n == 1 then
				name = "ammunition"
			elseif n == 2 then
				name = "speed"
			end

			local x, y = p.x * tilesize, p.y * tilesize
			local powerup = Powerup:new(name)
			powerup.kind = "powerup"
			self.world:add(powerup, x, y, tilesize, tilesize)
		end
	end
end

function World:add(x, y, width, height, kind)
	local block = {
		kind = kind or "solid",
		x = x,
		y = y,
		width = width,
		height = height
	}
	self.world:add(block, x, y, width, height)
end

function World:getWorld()
	return self.world
end

function World:remove(item)
	self.world:remove(item)
end

return World