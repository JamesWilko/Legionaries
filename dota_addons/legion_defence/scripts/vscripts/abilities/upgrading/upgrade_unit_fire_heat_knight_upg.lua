
require("abilities/upgrade_unit")

if upgrade_unit_fire_heat_knight_upg == nil then
	upgrade_unit_fire_heat_knight_upg = class(upgrade_unit)
end

function upgrade_unit_fire_heat_knight_upg:GetUpgradeClass()
	return "npc_legion_fire_heat_knight_upg"
end
