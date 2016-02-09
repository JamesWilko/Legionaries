
require("abilities/upgrade_unit")

if upgrade_unit_fire_vanguard_upg == nil then
	upgrade_unit_fire_vanguard_upg = class(upgrade_unit)
end

function upgrade_unit_fire_vanguard_upg:GetUpgradeClass()
	return "npc_legion_fire_vanguard_upg"
end



