
require("abilities/selling/sell_unit")

if sell_unit_fire == nil then
	sell_unit_fire = class( sell_unit )
end

LinkLuaModifier( "modifier_sell_unit_fire_think", "abilities/selling/modifier_sell_unit_fire_think", LUA_MODIFIER_MOTION_NONE )

function sell_unit_fire:ModifierToRun()
	return "modifier_sell_unit_fire_think"
end

function sell_unit_fire:ModifierDestroysUnit()
	return true
end
