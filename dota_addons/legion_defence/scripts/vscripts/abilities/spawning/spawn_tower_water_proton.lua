
require("abilities/spawn_water_tower")

if spawn_tower_water_proton == nil then
	spawn_tower_water_proton = class(spawn_water_tower)
end

function spawn_tower_water_proton:GetSpawnUnit()
	return "npc_legion_water_proton"
end






