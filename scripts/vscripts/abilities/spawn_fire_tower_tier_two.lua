
require("abilities/spawn_fire_tower")

if spawn_fire_tower_tier_two == nil then
	spawn_fire_tower_tier_two = class(spawn_fire_tower)
end

function spawn_fire_tower_tier_two:GetSpawnUnit()
	return "npc_dota_hero_clinkz"
end
