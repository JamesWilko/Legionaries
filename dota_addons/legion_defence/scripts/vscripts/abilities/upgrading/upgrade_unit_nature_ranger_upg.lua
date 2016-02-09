
require("abilities/upgrade_unit")

if upgrade_unit_nature_ranger_upg == nil then
	upgrade_unit_nature_ranger_upg = class(upgrade_unit)
end

function upgrade_unit_nature_ranger_upg:GetUpgradeClass()
	return "npc_legion_nature_ranger_upg"
end

