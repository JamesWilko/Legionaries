
if spawn_unit_tower == nil then
	spawn_unit_tower = class({})
end

BUILD_UNIT_FAIL_REASON_WAVE_RUNNING 			= 1
BUILD_UNIT_FAIL_REASON_CANT_AFFORD_GOLD 		= 2
BUILD_UNIT_FAIL_REASON_NOT_IN_ZONE 				= 3
BUILD_UNIT_FAIL_REASON_OCCUPIED 				= 4
BUILD_UNIT_FAIL_REASON_CANT_AFFORD_GEMS 		= 5
BUILD_UNIT_FAIL_REASON_CANT_AFFORD_POPULATION 	= 6
BUILD_UNIT_FAIL_REASON_WRONG_TEAM				= 7
BUILD_UNIT_FAIL_REASON_NO_BUILD_PERMISSION		= 8

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
	if not GameRules.LegionDefence:GetCurrencyController():CanAfford( CURRENCY_GOLD, self:GetOwner(), self._gold_cost ) then
		self._fail_reason = BUILD_UNIT_FAIL_REASON_CANT_AFFORD_GOLD
		return UF_FAIL_CUSTOM
	end

	self._population_cost = self:GetSpecialValueFor( "PopulationCost" )
	if not GameRules.LegionDefence:GetCurrencyController():CanAfford( CURRENCY_FOOD, self:GetOwner(), self._population_cost ) then
		self._fail_reason = BUILD_UNIT_FAIL_REASON_CANT_AFFORD_POPULATION
		return UF_FAIL_CUSTOM
	end
	
	-- Can not build if out of a build zone, or if another unit is already there
	local can_build_in_loc, cant_build_reason = self:CanBuildInLocation( vTargetPosition )
	if can_build_in_loc then

		if self:IsLocationFreeToBuildIn( vTargetPosition ) then
			return UF_SUCCESS
		else
			self._fail_reason = BUILD_UNIT_FAIL_REASON_OCCUPIED
			return UF_FAIL_CUSTOM
		end

	else
		self._fail_reason = cant_build_reason
		return UF_FAIL_CUSTOM
	end

end

function spawn_unit_tower:GetCustomCastErrorLocation( vLocation )

	-- Check if wave is running
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_WAVE_RUNNING then
		return "#legion_can_not_build_wave_in_progress"
	end

	-- Check if can afford to build
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_CANT_AFFORD_GOLD then
		return "#legion_can_not_build_cant_afford_gold"
	end

	if self._fail_reason == BUILD_UNIT_FAIL_REASON_CANT_AFFORD_POPULATION then
		return "#legion_can_not_build_cant_afford_population"
	end

	-- Check build locations
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_NOT_IN_ZONE then
		return "#legion_can_not_build_in_location_zone"
	end
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_OCCUPIED then
		return "#legion_can_not_build_already_occupied"
	end

	if self._fail_reason == BUILD_UNIT_FAIL_REASON_WRONG_TEAM then
		return "#legion_can_not_build_enemy_lane"
	end
	if self._fail_reason == BUILD_UNIT_FAIL_REASON_NO_BUILD_PERMISSION then
		return "#legion_can_not_build_no_permission"
	end

end

function spawn_unit_tower:GetBuildZone( vTargetPosition )

	vTargetPosition = BuildGrid:RoundPositionToGrid( vTargetPosition )

	local map_controller = GameRules.LegionDefence:GetMapController()

	for k, build_zone in pairs( map_controller:BuildZones() ) do

		local ent = build_zone.entity
		local bounds = ent:GetBounds()
		local mins = ent:GetCenter() + bounds.Mins
		local maxs = ent:GetCenter() + bounds.Maxs

		if mins.x <= vTargetPosition.x and vTargetPosition.x <= maxs.x then
			if mins.y <= vTargetPosition.y and vTargetPosition.y <= maxs.y then
				return build_zone
			end
		end

	end

	return nil

end

function spawn_unit_tower:CanBuildInLocation( vTargetPosition )

	vTargetPosition = BuildGrid:RoundPositionToGrid( vTargetPosition )

	local lane_controller = GameRules.LegionDefence:GetLaneController()
	local build_zone = self:GetBuildZone(vTargetPosition)

	if build_zone then

		local owner = self:GetCaster():GetOwner()
		local owner_id = SafeGetPlayerID(owner)
		local owner_team = owner:GetTeamNumber()
		local owner_lane = lane_controller:GetLaneForPlayer( SafeGetPlayerID(owner) )
		if build_zone.team == owner_team then

			if lane_controller:HasPermissionToBuildInLane( owner_id, build_zone.lane ) then
				return true, nil, build_zone.lane
			else
				return false, BUILD_UNIT_FAIL_REASON_NO_BUILD_PERMISSION
			end

		else
			return false, BUILD_UNIT_FAIL_REASON_WRONG_TEAM
		end

	end

	return false, BUILD_UNIT_FAIL_REASON_NOT_IN_ZONE

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

	self:SpendSpawnCost()
	self:SpawnUnitAtPosition( vTargetPosition )

end

function spawn_unit_tower:GetSpawnUnit()
	Warning("Attempting to spawn a tower which has no unit assigned!")
	return false
end

function spawn_unit_tower:SpawnUnitAtPosition( vPosition )
	if self:GetSpawnUnit() then

		local unitController = GameRules.LegionDefence:GetUnitController()
		local build_zone = self:GetBuildZone(vPosition)
		local hUnit = unitController:SpawnUnit( self:GetCaster():GetOwner(), self:GetCaster():GetTeamNumber(), self:GetSpawnUnit(), build_zone.lane, vPosition )
		
		if self._gold_cost == nil then
			self._gold_cost = self:GetSpecialValueFor( "GoldCost" ) or 0
		end
		if self._population_cost == nil then
			self._population_cost = self:GetSpecialValueFor( "PopulationCost" ) or 0
		end

		unitController:AddCostToUnit( hUnit, CURRENCY_GOLD , self._gold_cost )
		unitController:AddCostToUnit( hUnit, CURRENCY_FOOD , self._population_cost )

	end
end

function spawn_unit_tower:SpendSpawnCost()

	-- Deduct Gold Cost
	if self._gold_cost == nil then
		self._gold_cost = self:GetSpecialValueFor( "GoldCost" )
	end
	GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CURRENCY_GOLD, self:GetOwner(), -self._gold_cost )

	-- Deduct Population Cost
	if self._population_cost == nil then
		self._population_cost = self:GetSpecialValueFor( "PopulationCost" )
	end
	GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CURRENCY_FOOD, self:GetOwner(), -self._population_cost )

end
