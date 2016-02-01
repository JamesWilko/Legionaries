
require("abilities/selling/sell_unit")

if sell_unit_water == nil then
	sell_unit_water = class( sell_unit )
end

LinkLuaModifier( "modifier_sell_unit_water_think", "abilities/selling/modifier_sell_unit_water_think", LUA_MODIFIER_MOTION_NONE )

function sell_unit_water:ModifierToRun()
	return "modifier_sell_unit_water_think"
end

function sell_unit_water:ModifierDestroysUnit()
	return true
end
