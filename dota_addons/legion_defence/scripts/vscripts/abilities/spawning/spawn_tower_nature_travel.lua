
require("abilities/spawn_nature_tower")

if spawn_tower_nature_travel == nil then
	spawn_tower_nature_travel = class(spawn_nature_tower)
end

function spawn_tower_nature_travel:GetSpawnUnit()
	return "npc_legion_nature_travel"
end





