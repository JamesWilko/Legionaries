
require("abilities/spawn_fire_tower")

if spawn_tower_fire_vanguard == nil then
	spawn_tower_fire_vanguard = class(spawn_fire_tower)
end

function spawn_tower_fire_vanguard:GetSpawnUnit()
	return "npc_legion_fire_vanguard"
end
