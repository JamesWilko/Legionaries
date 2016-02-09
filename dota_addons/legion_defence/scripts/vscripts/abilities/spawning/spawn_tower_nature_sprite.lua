
require("abilities/spawn_nature_tower")

if spawn_tower_nature_sprite == nil then
	spawn_tower_nature_sprite = class(spawn_nature_tower)
end

function spawn_tower_nature_sprite:GetSpawnUnit()
	return "npc_legion_nature_sprite"
end



