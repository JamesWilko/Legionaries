
require("abilities/upgrade_unit")

if upgrade_unit_fire_firestarter_upg_heal == nil then
	upgrade_unit_fire_firestarter_upg_heal = class(upgrade_unit)
end

function upgrade_unit_fire_firestarter_upg_heal:GetUpgradeClass()
	return "npc_legion_fire_firestarter_upg_heal"
end
