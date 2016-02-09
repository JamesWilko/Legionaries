
require("abilities/spawn_mech_tower")

if spawn_tower_mech_captain == nil then
	spawn_tower_mech_captain = class(spawn_mech_tower)
end

function spawn_tower_mech_captain:GetSpawnUnit()
	return "npc_legion_mech_captain"
end





