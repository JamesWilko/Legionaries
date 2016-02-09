
require("abilities/spawn_nature_tower")

if spawn_tower_nature_life == nil then
	spawn_tower_nature_life = class(spawn_nature_tower)
end

function spawn_tower_nature_life:GetSpawnUnit()
	return "npc_legion_nature_life"
end



