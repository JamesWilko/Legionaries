
require("abilities/upgrade_unit")

if upgrade_unit_water_spirit_upg == nil then
	upgrade_unit_water_spirit_upg = class(upgrade_unit)
end

function upgrade_unit_water_spirit_upg:GetUpgradeClass()
	return "npc_legion_water_spirit_upg"
end

