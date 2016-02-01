
require("abilities/selling/sell_unit")

if sell_unit_mech == nil then
	sell_unit_mech = class( sell_unit )
end

LinkLuaModifier( "modifier_sell_unit_mech_think", "abilities/selling/modifier_sell_unit_mech_think", LUA_MODIFIER_MOTION_NONE )

function sell_unit_mech:ModifierToRun()
	return "modifier_sell_unit_mech_think"
end

function sell_unit_mech:ModifierDestroysUnit()
	return true
end
