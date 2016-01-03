
require("abilities/upgrade_unit")

if upgrade_unit_fire_firestarter_upg_melee == nil then
	upgrade_unit_fire_firestarter_upg_melee = class(upgrade_unit)
end

function upgrade_unit_fire_firestarter_upg_melee:GetUpgradeClass()
	return "npc_legion_fire_firestarter_upg_melee"
end
