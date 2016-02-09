
require("abilities/spawn_fire_tower")

if spawn_tower_fire_flame_archer == nil then
	spawn_tower_fire_flame_archer = class(spawn_fire_tower)
end

function spawn_tower_fire_flame_archer:GetSpawnUnit()
	return "npc_legion_fire_flame_archer"
end




