
require("abilities/upgrade_unit")

if upgrade_unit_mech_sniper_upg_range == nil then
	upgrade_unit_mech_sniper_upg_range = class(upgrade_unit)
end

function upgrade_unit_mech_sniper_upg_range:GetUpgradeClass()
	return "npc_legion_mech_sniper_upg_range"
end

