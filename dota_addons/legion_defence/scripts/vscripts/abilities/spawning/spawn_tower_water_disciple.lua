
require("abilities/spawn_water_tower")

if spawn_tower_water_disciple == nil then
	spawn_tower_water_disciple = class(spawn_water_tower)
end

function spawn_tower_water_disciple:GetSpawnUnit()
	return "npc_legion_water_disciple"
end



