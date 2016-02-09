
require("abilities/spawn_nature_tower")

if spawn_tower_nature_ranger == nil then
	spawn_tower_nature_ranger = class(spawn_nature_tower)
end

function spawn_tower_nature_ranger:GetSpawnUnit()
	return "npc_legion_nature_ranger"
end




