
if spawn_unit_tower == nil then
	spawn_unit_tower = class({})
end

LinkLuaModifier( "modifier_spawn_fire_tower", "abilities/modifier_spawn_fire_tower", LUA_MODIFIER_MOTION_NONE )

function spawn_unit_tower:OnAbilityPhaseStart()
	local vTargetPosition = self:GetCursorPosition()
	return self:CanBuildInLocation( vTargetPosition ) and self:IsLocationFreeToBuildIn( vTargetPosition )
end

function spawn_unit_tower:CastFilterResultLocation( vTargetPosition )

	if Entities.FindAllInSphere then

		if not GameRules.LegionDefence:GetWaveController():IsWaveRunning() then

			local success = self:CanBuildInLocation( vTargetPosition ) and self:IsLocationFreeToBuildIn( vTargetPosition )
			if success then
				return UF_SUCCESS
			else
				return UF_FAIL_CUSTOM
			end

		else
			return UF_FAIL_CUSTOM
		end

	else
		return UF_SUCCESS
	end

end

function spawn_unit_tower:GetCustomCastErrorLocation( vLocation )
	if GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		return "#legion_can_not_build_wave_in_progress"
	end
	if self:CanBuildInLocation( vLocation ) then
		if not self:IsLocationFreeToBuildIn( vLocation ) then
			return "#legion_can_not_build_already_occupied"
		end
	else
		return "#legion_can_not_build_in_location_zone"
	end
end

function spawn_unit_tower:CanBuildInLocation( vTargetPosition )

	vTargetPosition = BuildGrid:RoundPositionToGrid( vTargetPosition )

	for k, build in pairs( GameRules.LegionDefence:GetMapController():BuildZones() ) do

		local ent = build.entity
		local bounds = ent:GetBounds()
		local mins = ent:GetCenter() + bounds.Mins
		local maxs = ent:GetCenter() + bounds.Maxs

		if mins.x <= vTargetPosition.x and vTargetPosition.x <= maxs.x and
			mins.y <= vTargetPosition.y and vTargetPosition.y <= maxs.y then
			return true
		end

	end

	return false

end

function spawn_unit_tower:IsLocationFreeToBuildIn( vTargetPosition )

	for _, ent in pairs( Entities:FindAllInSphere( vTargetPosition, BuildGrid:GetGridSearchRadius() ) ) do
		if string.sub(ent:GetClassname(), 1, 4) == "npc_" then
			return false
		end
	end

	return true

end

function spawn_unit_tower:OnSpellStart()

	local vTargetPosition = self:GetCursorPosition()
	vTargetPosition = BuildGrid:RoundPositionToGrid( vTargetPosition )

	self:SpawnUnitAtPosition( vTargetPosition )

end

function spawn_unit_tower:GetSpawnUnit()
	Warning("Attempting to spawn a tower which has no unit assigned!")
	return false
end

function spawn_unit_tower:SpawnUnitAtPosition( vPosition )
	if self:GetSpawnUnit() then
		GameRules.LegionDefence:GetUnitController():SpawnUnit( self:GetCaster():GetOwner(), self:GetCaster():GetTeamNumber(), self:GetSpawnUnit(), vPosition )
	end
end
