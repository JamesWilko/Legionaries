
require("abilities/upgrade_unit")

if upgrade_unit_mech_sniper_upg_damage == nil then
	upgrade_unit_mech_sniper_upg_damage = class(upgrade_unit)
end

function upgrade_unit_mech_sniper_upg_damage:GetUpgradeClass()
	return "npc_legion_mech_sniper_upg_damage"
end


