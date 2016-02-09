
require("abilities/upgrade_unit")

if upgrade_unit_mech_cyborg_upg == nil then
	upgrade_unit_mech_cyborg_upg = class(upgrade_unit)
end

function upgrade_unit_mech_cyborg_upg:GetUpgradeClass()
	return "npc_legion_mech_cyborg_upg"
end


