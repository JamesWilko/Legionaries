
if spawn_unit_tower == nil then
	spawn_unit_tower = class({})
end

BUILD_UNIT_FAIL_REASON_WAVE_RUNNING 	= 1
BUILD_UNIT_FAIL_REASON_CANT_AFFORD 		= 2
BUILD_UNIT_FAIL_REASON_NOT_IN_ZONE 		= 3
BUILD_UNIT_FAIL_REASON_OCCUPIED 		= 4

LinkLuaModifier( "modifier_spawn_fire_tower", "abilities/modifier_spawn_fire_tower", LUA_MODIFIER_MOTION_NONE )

function spawn_unit_tower:OnAbilityPhaseStart()
	local vTargetPosition = self:GetCursorPosition()
	return self:CanBuildInLocation( vTargetPosition ) and self:IsLocationFreeToBuildIn( vTargetPosition )
end

function spawn_unit_tower:CastFilterResultLocation( vTargetPosition )

	if not Entities.FindAllInSphere then
		return UF_SUCCESS
	end

	-- Can only build between waves
	if GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		self._fail_reason = BUILD_UNIT_FAIL_REASON_WAVE_RUNNING
		return UF_FAIL_CUSTOM
	end

	-- Can only build if can afford
	self._gold_cost = self:GetSpecialValueFor( "GoldCost" )
	if self:GetOwner():GetGold() < self._gold_cost then
		self._fail_reason = BUILD_UNIT_FAIL_REASON_CANT_AFFORD
		return UF_FAIL_CUSTOM
	end

	-- Can not build if out of a build zone, or if another unit is already there
	if self:CanBuildInLocation( vTargetPosition ) then

		if self:IsLocationFreeToBuildIn( vTargetPosition ) then

		else
			self._fail_reason = BUILD_UNIT_FAIL_REASON_OCCUPIED
			return UF_FAIL_CUSTOM
		end

	else
		self._fail_reason = BUILD_UNIT_FAIL_REASON_NOT_IN_ZONE
		return UF_FAIL_CUSTOM
	end

end

function spawn_unit_tower:GetCustomCastErrorLocation( vLocation )

	-- Check if wave is running
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_WAVE_RUNNING then
		return "#legion_can_not_build_wave_in_progress"
	end

	-- Check if can afford to build
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_CANT_AFFORD then
		return "#legion_can_not_build_cant_afford"
	end

	-- Check build locations
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_NOT_IN_ZONE then
		return "#legion_can_not_build_in_location_zone"
	end
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_OCCUPIED then
		return "#legion_can_not_build_already_occupied"
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

	self:SpendGoldCost()
	self:SpawnUnitAtPosition( vTargetPosition )

end

function spawn_unit_tower:GetSpawnUnit()
	Warning("Attempting to spawn a tower which has no unit assigned!")
	return false
end

function spawn_unit_tower:SpawnUnitAtPosition( vPosition )
	if self:GetSpawnUnit() then
		local unitController = GameRules.LegionDefence:GetUnitController()
		local hUnit = unitController:SpawnUnit( self:GetCaster():GetOwner(), self:GetCaster():GetTeamNumber(), self:GetSpawnUnit(), vPosition )
		unitController:AddCostToUnit( hUnit, self._gold_cost )
	end
end

function spawn_unit_tower:SpendGoldCost()

	-- Deduct Gold Cost
	if self._gold_cost == nil then
		self._gold_cost = self:GetSpecialValueFor( "GoldCost" )
	end
	self:GetOwner():ModifyGold( -self._gold_cost, true, DOTA_ModifyGold_AbilityCost )

	-- Play particles and sounds
	PlayGoldParticlesForCost( self._gold_cost, self:GetCaster() )

end
