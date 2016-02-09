
require("abilities/upgrade_unit")

if upgrade_unit_nature_life_upg_dmg == nil then
	upgrade_unit_nature_life_upg_dmg = class(upgrade_unit)
end

function upgrade_unit_nature_life_upg_dmg:GetUpgradeClass()
	return "npc_legion_nature_life_upg_dmg"
end


