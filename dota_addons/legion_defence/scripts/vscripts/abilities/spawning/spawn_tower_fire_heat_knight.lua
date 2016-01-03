
require("abilities/spawn_fire_tower")

if spawn_tower_fire_heat_knight == nil then
	spawn_tower_fire_heat_knight = class(spawn_fire_tower)
end

function spawn_tower_fire_heat_knight:GetSpawnUnit()
	return "npc_legion_fire_heat_knight"
end
