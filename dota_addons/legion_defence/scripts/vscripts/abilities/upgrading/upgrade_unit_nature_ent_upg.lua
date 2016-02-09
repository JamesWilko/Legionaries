
require("abilities/upgrade_unit")

if upgrade_unit_nature_ent_upg == nil then
	upgrade_unit_nature_ent_upg = class(upgrade_unit)
end

function upgrade_unit_nature_ent_upg:GetUpgradeClass()
	return "npc_legion_nature_ent_upg"
end





