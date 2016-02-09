
require("abilities/spawn_mech_tower")

if spawn_tower_mech_airship == nil then
	spawn_tower_mech_airship = class(spawn_mech_tower)
end

function spawn_tower_mech_airship:GetSpawnUnit()
	return "npc_legion_mech_airship"
end





