
require("abilities/spawn_mech_tower")

if spawn_tower_mech_cyborg == nil then
	spawn_tower_mech_cyborg = class(spawn_mech_tower)
end

function spawn_tower_mech_cyborg:GetSpawnUnit()
	return "npc_legion_mech_cyborg"
end





