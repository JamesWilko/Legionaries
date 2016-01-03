
require("abilities/upgrade_unit")

if upgrade_unit_fire_firestarter_upg_ranged == nil then
	upgrade_unit_fire_firestarter_upg_ranged = class(upgrade_unit)
end

function upgrade_unit_fire_firestarter_upg_ranged:GetUpgradeClass()
	return "npc_legion_fire_firestarter_upg_ranged"
end
