
require("abilities/spawn_water_tower")

if spawn_tower_water_spirit == nil then
	spawn_tower_water_spirit = class(spawn_water_tower)
end

function spawn_tower_water_spirit:GetSpawnUnit()
	return "npc_legion_water_spirit"
end




