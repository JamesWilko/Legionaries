
require("abilities/spawn_fire_tower")

if spawn_tower_fire_flamebound == nil then
	spawn_tower_fire_flamebound = class(spawn_fire_tower)
end

function spawn_tower_fire_flamebound:GetSpawnUnit()
	return "npc_legion_fire_flamebound"
end
