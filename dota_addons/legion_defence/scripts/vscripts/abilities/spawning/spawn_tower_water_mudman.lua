
require("abilities/spawn_water_tower")

if spawn_tower_water_mudman == nil then
	spawn_tower_water_mudman = class(spawn_water_tower)
end

function spawn_tower_water_mudman:GetSpawnUnit()
	return "npc_legion_water_mudman"
end






