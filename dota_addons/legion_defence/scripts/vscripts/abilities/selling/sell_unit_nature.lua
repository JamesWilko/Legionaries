
require("abilities/selling/sell_unit")

if sell_unit_nature == nil then
	sell_unit_nature = class( sell_unit )
end

LinkLuaModifier( "modifier_sell_unit_nature_think", "abilities/selling/modifier_sell_unit_nature_think", LUA_MODIFIER_MOTION_NONE )

function sell_unit_nature:ModifierToRun()
	return "modifier_sell_unit_nature_think"
end

function sell_unit_nature:ModifierDestroysUnit()
	return true
end
