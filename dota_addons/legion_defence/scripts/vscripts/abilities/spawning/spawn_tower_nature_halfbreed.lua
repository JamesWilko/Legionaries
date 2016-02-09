
require("abilities/spawn_nature_tower")

if spawn_tower_nature_halfbreed == nil then
	spawn_tower_nature_halfbreed = class(spawn_nature_tower)
end

function spawn_tower_nature_halfbreed:GetSpawnUnit()
	return "npc_legion_nature_halfbreed"
end






