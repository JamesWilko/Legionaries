
require("abilities/spawn_mech_tower")

if spawn_tower_mech_sniper == nil then
	spawn_tower_mech_sniper = class(spawn_mech_tower)
end

function spawn_tower_mech_sniper:GetSpawnUnit()
	return "npc_legion_mech_sniper"
end




