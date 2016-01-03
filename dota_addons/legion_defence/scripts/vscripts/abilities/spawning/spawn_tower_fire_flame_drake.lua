
require("abilities/spawn_fire_tower")

if spawn_tower_fire_flame_drake == nil then
	spawn_tower_fire_flame_drake = class(spawn_fire_tower)
end

function spawn_tower_fire_flame_drake:GetSpawnUnit()
	return "npc_legion_fire_flame_drake"
end
