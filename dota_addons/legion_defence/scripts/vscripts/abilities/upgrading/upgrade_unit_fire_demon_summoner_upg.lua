
require("abilities/upgrade_unit")

if upgrade_unit_fire_demon_summoner_upg == nil then
	upgrade_unit_fire_demon_summoner_upg = class(upgrade_unit)
end

function upgrade_unit_fire_demon_summoner_upg:GetUpgradeClass()
	return "npc_legion_fire_demon_summoner_upg"
end
