
require("abilities/spawn_water_tower")

if spawn_tower_water_watcher == nil then
	spawn_tower_water_watcher = class(spawn_water_tower)
end

function spawn_tower_water_watcher:GetSpawnUnit()
	return "npc_legion_water_watcher"
end




