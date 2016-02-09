
require("abilities/spawn_fire_tower")

if spawn_tower_fire_pyromancer == nil then
	spawn_tower_fire_pyromancer = class(spawn_fire_tower)
end

function spawn_tower_fire_pyromancer:GetSpawnUnit()
	return "npc_legion_fire_pyromancer"
end




