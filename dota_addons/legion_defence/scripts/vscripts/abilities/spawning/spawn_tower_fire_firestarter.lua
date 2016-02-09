
require("abilities/spawn_fire_tower")

if spawn_tower_fire_firestarter == nil then
	spawn_tower_fire_firestarter = class(spawn_fire_tower)
end

function spawn_tower_fire_firestarter:GetSpawnUnit()
	return "npc_legion_fire_firestarter"
end



