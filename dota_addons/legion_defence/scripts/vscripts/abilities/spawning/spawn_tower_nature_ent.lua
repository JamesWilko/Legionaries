
require("abilities/spawn_nature_tower")

if spawn_tower_nature_ent == nil then
	spawn_tower_nature_ent = class(spawn_nature_tower)
end

function spawn_tower_nature_ent:GetSpawnUnit()
	return "npc_legion_nature_ent"
end









