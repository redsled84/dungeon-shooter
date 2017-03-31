math.randomseed(os.time())
math.random();math.random();math.random();

-- TODOS: Dungeon needs an down ladder to new level

local inspect = require "inspect"
local Dungeon = require "dungeon"
local Hud = require "hud"
local MST = require "mst"
local Player = require "player"
local Shake = require "shake"
local SoundFX = require "soundfx"
local tilesize = require "tilesize"
local Viewport = require "viewport"
local World = require "world"
local LightWorld = require "lightworld"

local stats = {
	-- health = 110,
	health = 120,
	speed = 225,
	ammo = 35,
	rof = .35,
	minAtkPwr = 75,
	maxAtkPwr = 95
}

local defaultStats = {
	health = stats.health,
	speed = stats.speed,
	ammo = stats.ammo,
	rof = stats.rof,
	minAtkPwr = stats.minAtkPwr,
	maxAtkPwr = stats.maxAtkPwr
}

lightWorld = LightWorld({
    ambient = {45,45,45},
    refractionStrength = 32.0,
    reflectionVisibility = 0.75,
    shadowBlur = 0.0
})		


local lights = {}
shadowBodies = {}
local depth = 0
function loadGame()
	if depth > 0 then
		Dungeon:increaseDifficulty(depth, #World.enemies)
		Dungeon:initialize(Dungeon.maxEnemies, Dungeon.maxPowerups, Dungeon.maxRooms, Dungeon.maxAmmoCrates)
	else
		Dungeon:initialize()
	end
	MST:initialize(Dungeon:getRooms())
	Dungeon:generateDoors(MST:getTree())
	Dungeon:generateDrawList()
	World:initialize(Dungeon:getDrawList("foreground"), Dungeon:getDrawList("background"))

	local room = Dungeon:getRoom(1)

	if Player:isDead() then
		Player:initialize(room, World:getWorld(), defaultStats)
	else
		Player:initialize(room, World:getWorld(), stats)
	end

	if #lights > 0 then
		for i = #lightWorld.lights, 1, -1 do
			table.remove(lightWorld.lights, i)
		end
	end
	if #shadowBodies > 0 then
		for i = #lightWorld.bodies, 1, -1 do
			table.remove(lightWorld.bodies, i)
		end
	end

	for i = 1, #Dungeon.rooms do
		local room = Dungeon.rooms[i]
		print((room.x+room.width/2)*tilesize, (room.y+room.height/2)*tilesize)
		local light = lightWorld:newLight((room.x+room.width/2)*tilesize+20, (room.y+room.height/2)*tilesize+20, 255, 255, 255, 250)
		light:setGlowStrength(0.1)
		lights[#lights+1] = light
	end

	for i = 1, #Dungeon.drawList.background do
		local t = Dungeon.drawList.background[i]
		if t.num == 1 then
			local rect = lightWorld:newRectangle(t.x*tilesize+20, t.y*tilesize+20, tilesize, tilesize)
			shadowBodies[#shadowBodies+1] = rect
		end
	end
	
	-- 2.4
	Viewport:initialize(Player.x, Player.y, 1)
	Shake.reset()
	depth = depth + 1
end

function updateStats()
	stats.health = Player.health
	stats.speed = Player.speed
	stats.ammo = Player.ammunition
	stats.rof = Player.rof
	stats.minAtkPwr = Player.minAtkPwr
	stats.maxAtkPwr = Player.maxAtkPwr
end

function love.load()
	love.graphics.setBackgroundColor(30,30,30)

	SoundFX:initialize()
	loadGame()
	--[[
	print(inspect(shadowBodies))
	]]
	love.graphics.setBackgroundColor(0,0,0)
end

function love.update(dt)
	if not Player:isDead() then
		-- print(collectgarbage("count"))
		Player:update(dt, World:getWorld(), Dungeon:getDrawList("background"), World.enemies)
		World:update(dt, Dungeon:getDrawList("background"), Player.x + Player.width / 2, Player.y + Player.height / 2, Player)
		Dungeon:updateDungeonComplete(#World.enemies)

		-- Camera/Viewport
		-- for i = 1, #Dungeon.rooms do
		-- 	local room = Dungeon.rooms[i]
		-- 	Viewport:roomConstraint(Player, room)
		-- end
		updateStats(dt)
		Shake.update(dt)

		Viewport:lockToPlayer(Player.x, Player.y)
		-- lightMouse:setPosition(Player.x, Player.y)

		-- print(Player.health, stats.health)
	end

    lightWorld:setTranslation(-Viewport.camera.x + love.graphics.getWidth()/2, -Viewport.camera.y + love.graphics.getHeight()/2)
    lightWorld:update(dt)
	-- lightMouse:setPosition(Player.x+Player.width/2, Player.y+Player.height/2, 1)
	-- print(collectgarbage("count"))
end

function love.draw()
	Viewport:attach()
	lightWorld:draw(function()
		-- Shake.preDraw()
		--[[
		]]
		Dungeon:drawFloor()
		-- MST:draw()
		-- World:drawShadows()
		Dungeon:drawWalls()
		Player:draw()
		
		World:draw()
		--[[
		]]
		-- Shake.postDraw()
		-- World:drawListNums(Dungeon:getDrawList())
		--[[
		love.graphics.setColor(255,255,255)
		for i = 1, #shadowBodies do
			local rect = shadowBodies[i]
			love.graphics.polygon("fill", rect:getPoints())
		end
		]]
	end)
	Viewport:detach()
	Hud:drawBackgroundOverlay()
	Hud:drawPlayerStats()
	Hud:drawDepth(depth)

	if not Player:isDead() then
		Hud:drawLevelStatus(Player.canContinue, depth, love.graphics.getWidth()/2, love.graphics.getHeight()/2)
	else
		Hud:drawDeadStatus(depth)
	end
end

function love.keypressed(key)
	-- if key == "f" and (Player.canContinue or Player:isDead()) then
	if key == "f" then
		if Player:isDead() then
			depth = 0
		end
		loadGame()
	end
	if key == "escape" then
		love.event.quit()
	end

	if not Player:isDead() then
		Player:fireBullet(key, World:getWorld())
	end
end