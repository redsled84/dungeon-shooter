local Weapon = {}

function Weapon.getWeapon(name, min, max)
	if name == "pistol" then
		return {
			macro = 1,
			rof = .1,
			bulletInfo = {
				list = {},
				width = 6,
				height = 6,
				speed = 600,
				minAtkPwr = min,
				maxAtkPwr = max
			}
		}
	elseif name == "rifle" then
		return {
			macro = 2,
			rof = .5,
			bulletInfo = {
				list = {},
				width = 4,
				height = 4,
				speed = 900,
				minAtkPwr = min,
				maxAtkPwr = max
			}	
		}
	end
end

return Weapon