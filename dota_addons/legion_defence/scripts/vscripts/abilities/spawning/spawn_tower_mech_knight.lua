
require("abilities/spawn_mech_tower")

if spawn_tower_mech_knight == nil then
	spawn_tower_mech_knight = class(spawn_mech_tower)
end

function spawn_tower_mech_knight:GetSpawnUnit()
	return "npc_legion_mech_knight"
end






