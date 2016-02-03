
require("abilities/spawn_unit_tower")

if spawn_water_tower == nil then
	spawn_water_tower = class(spawn_unit_tower)
end

LinkLuaModifier( "modifier_spawn_water_tower", "abilities/modifier_spawn_water_tower", LUA_MODIFIER_MOTION_NONE )

function spawn_water_tower:OnSpellStart()

	local vTargetPosition = self:GetCursorPosition()
	vTargetPosition = BuildGrid:RoundPositionToGrid( vTargetPosition )

	self:SpendSpawnCost()

	local kv = {}
	CreateModifierThinker( self:GetCaster(), self, "modifier_spawn_water_tower", kv, vTargetPosition, self:GetCaster():GetTeamNumber(), false )

end
