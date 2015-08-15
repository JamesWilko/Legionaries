
require("abilities/spawn_unit_tower")

if spawn_fire_tower == nil then
	spawn_fire_tower = class(spawn_unit_tower)
end

LinkLuaModifier( "modifier_spawn_fire_tower", "abilities/modifier_spawn_fire_tower", LUA_MODIFIER_MOTION_NONE )

function spawn_fire_tower:OnSpellStart()

	local vTargetPosition = self:GetCursorPosition()
	vTargetPosition = BuildGrid:RoundPositionToGrid( vTargetPosition )

	self:SpendGoldCost()

	local kv = {}
	CreateModifierThinker( self:GetCaster(), self, "modifier_spawn_fire_tower", kv, vTargetPosition, self:GetCaster():GetTeamNumber(), false )

end
