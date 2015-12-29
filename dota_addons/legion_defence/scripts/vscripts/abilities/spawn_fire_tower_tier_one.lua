
require("abilities/spawn_fire_tower")

if spawn_fire_tower_tier_one == nil then
	spawn_fire_tower_tier_one = class(spawn_fire_tower)
end

function spawn_fire_tower_tier_one:GetSpawnUnit()
	return "npc_legion_fire_tier1_level1"
end
