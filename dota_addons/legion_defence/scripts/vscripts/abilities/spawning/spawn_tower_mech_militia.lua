
require("abilities/spawn_mech_tower")

if spawn_tower_mech_militia == nil then
	spawn_tower_mech_militia = class(spawn_mech_tower)
end

function spawn_tower_mech_militia:GetSpawnUnit()
	return "npc_legion_mech_militia"
end






