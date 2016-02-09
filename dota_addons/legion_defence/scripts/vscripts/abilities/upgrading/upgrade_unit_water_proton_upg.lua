
require("abilities/upgrade_unit")

if upgrade_unit_water_proton_upg == nil then
	upgrade_unit_water_proton_upg = class(upgrade_unit)
end

function upgrade_unit_water_proton_upg:GetUpgradeClass()
	return "npc_legion_water_proton_upg"
end




