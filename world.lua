local bump = require "bump"
local Dungeon = require "dungeon"
local Enemy = require "enemy"
local Powerup = require "powerup"
local SoundFX = require "soundfx"
local tilesize = require "tilesize"
local World = {}

function World.aabb(a, x, y, w, h)
	return a.x < x + w and a.x + a.width > x and
		a.y < y + h and a.y + a.height > y
end

function World:initialize(foreground, background)
	if self.world then
		local items, len = self.world:getItems()
		for i = 1, len do
			self.world:remove(items[i])
		end
	end

	self.enemies = {}

	self.world = bump.newWorld()
	self:addBlocksToWorld(foreground, background)
end

local remove = table.remove
function World:update(dt, list, x, y, player)
	for i = #self.enemies, 1, -1 do
		local enemy = self.enemies[i]
		enemy:update(dt, self.world, list, player)
		enemy:fireBullets(x, y, self.world)

		if enemy.health < 0 then
			enemy:removeBullets(self.world)
			remove(self.enemies, i)
			self.world:remove(enemy)
			SoundFX:play("killed", .5)
			break
		end
	end
end

function World:addBlocksToWorld(foreground, background)
	for i = 1, #background do
		local p = background[i]
		if p.num == 1 then
			self:add(p.x * tilesize, p.y * tilesize, tilesize, tilesize)
		end
		if p.num == 6 then
			self:add(p.x * tilesize, p.y * tilesize, tilesize, tilesize, "exit")
		end
	end
	for i = 1, #foreground do
		local p = foreground[i]
		if p.num == 2 then
			local n = math.random(0, 1)
			local name = ""
			if n == 0 then
				name = "health"
			elseif n == 1 then
				name = "speed"
			end

			local x, y = p.x * tilesize, p.y * tilesize
			local powerup = Powerup:new(name, x, y)
			powerup.kind = "powerup"
			self.world:add(powerup, x, y, powerup.width, powerup.height)
		elseif p.num == 3 then
			local room = Dungeon:getRoomFromPosition(p.x, p.y)
			local enemy = Enemy:new(p.x * tilesize, p.y * tilesize, room)
			self.enemies[#self.enemies+1] = enemy
			self.world:add(enemy, enemy.x, enemy.y, tilesize, tilesize)
		elseif p.num == 4 then
			local x, y = p.x * tilesize, p.y * tilesize
			local powerup = Powerup:new("ammunition", x, y)
			powerup.kind = "powerup"
			self.world:add(powerup, x, y, 32, 32)
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

function World:drawShadows()
	local items, len = self.world:getItems()
	for i = 1, len do
		local item = items[i]
		if item.kind == "player" or item.kind == "enemy" then
			local x = (item.x or item.x1) + item.width / 2
			local y = (item.y or item.y1) + item.height - 4
			local rw, rh = item.width / 1.5, item.height / 2.25
			love.graphics.setColor(0, 0, 0, 100)
			love.graphics.ellipse("fill", x, y, rw, rh)
		end
	end
end

function World:draw()
	local items, len = self.world:getItems()
	for i = 1, len do
		local item = items[i]
		if item.kind == "powerup" then
			item:draw()
		end
	end

	for i = 1, #self.enemies do
		self.enemies[i]:draw()
	end
end

function World:drawListNums(list)
	for i = 1, #list do
		local p = list[i]
		love.graphics.print(p.num, p.x*tilesize, p.y*tilesize)
	end
end

return World