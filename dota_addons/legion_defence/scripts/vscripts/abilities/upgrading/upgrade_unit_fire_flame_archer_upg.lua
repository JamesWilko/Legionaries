
require("abilities/upgrade_unit")

if upgrade_unit_fire_flame_archer_upg == nil then
	upgrade_unit_fire_flame_archer_upg = class(upgrade_unit)
end

function upgrade_unit_fire_flame_archer_upg:GetUpgradeClass()
	return "npc_legion_fire_flame_archer_upg"
end

