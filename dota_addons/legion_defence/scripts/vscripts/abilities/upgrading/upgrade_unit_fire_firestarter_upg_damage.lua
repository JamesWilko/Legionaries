
require("abilities/upgrade_unit")

if upgrade_unit_fire_firestarter_upg_damage == nil then
	upgrade_unit_fire_firestarter_upg_damage = class(upgrade_unit)
end

function upgrade_unit_fire_firestarter_upg_damage:GetUpgradeClass()
	return "npc_legion_fire_firestarter_upg_damage"
end
