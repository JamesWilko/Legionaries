
require("abilities/spawn_fire_tower")

if spawn_tower_fire_demon_summoner == nil then
	spawn_tower_fire_demon_summoner = class(spawn_fire_tower)
end

function spawn_tower_fire_demon_summoner:GetSpawnUnit()
	return "npc_legion_fire_demon_summoner"
end
