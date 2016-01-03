
require("abilities/upgrade_unit")

if upgrade_unit_fire_flame_drake_upg == nil then
	upgrade_unit_fire_flame_drake_upg = class(upgrade_unit)
end

function upgrade_unit_fire_flame_drake_upg:GetUpgradeClass()
	return "npc_legion_fire_flame_drake_upg"
end
