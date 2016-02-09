
require("abilities/spawn_water_tower")

if spawn_tower_water_seer == nil then
	spawn_tower_water_seer = class(spawn_water_tower)
end

function spawn_tower_water_seer:GetSpawnUnit()
	return "npc_legion_water_seer"
end




