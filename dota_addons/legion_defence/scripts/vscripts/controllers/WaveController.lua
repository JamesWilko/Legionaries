
if CWaveController == nil then
	CWaveController = class({})
end

-- Modifiers are in npc_items_custom.txt
CWaveController.ARMOUR_TIERS = {
	[1] = {
		item_name = "item_leaked_unit_armour_bonus_1",
		modifier = "modifier_armour_bonus_leaked_unit_1"
	},
	[2] = {
		item_name = "item_leaked_unit_armour_bonus_2",
		modifier = "modifier_armour_bonus_leaked_unit_2"
	}
}

CWaveController.LEAKED_WAVE_BOUNTY_MULTIPLIERS = {
	[1] = 1.0,
	[2] = 1.0,
	[3] = 1.0,
	[4] = 0.9,
	[5] = 0.8,
	[6] = 0.7,
	[7] = 0.6,
	[8] = 0.5,
	[9] = 0.4,
	[10] = 0.3,
	[11] = 0.25,
}

CWaveController.ENEMY_TEAMS = {
	[DOTA_TEAM_GOODGUYS] = DOTA_TEAM_BADGUYS,
	[DOTA_TEAM_BADGUYS] = DOTA_TEAM_GOODGUYS
}

CWaveController.WAVE_INFO_TABLE = "UpcomingWaveData"
CWaveController.NUM_WAVES_IN_SET = 10

function CLegionDefence:SetupWaveController()
	self.wave_controller = CWaveController()
	self.wave_controller:Setup()
end

function CLegionDefence:GetWaveController()
	return self.wave_controller
end

function CWaveController:Setup()

	self._waves_list = LoadKeyValues("scripts/kv/legion_waves.txt")
	self._leaks_list = {}

	self._current_wave = 0
	self._wave_in_progress = false

	self:SetNextWaveTime( 15 )
	self._time_between_waves = 60
	self._before_wave_time = 3
	self._end_of_wave_time = 3
	self._think_time = 1
	self._think_time_mid_wave = 0.2

	self:BuildWaveListData()
	self:UpdateWavesData()

	-- Think entity for this controller
	self._think_ent = IsValidEntity(self._think_ent) and self._think_ent or Entities:CreateByClassname("info_target")
	self._think_ent:SetThink("OnThink", self, "WaveControllerThink", self._think_time)

	-- Events
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CWaveController, "OnUnitKilled"), self)

end

function CWaveController:ThinkTime()
	return self:IsWaveRunning() and self._think_time_mid_wave or self._think_time
end

function CWaveController:OnThink()

	self._lane_controller = self._lane_controller or GameRules.LegionDefence:GetLaneController()
	self._map_controller = self._map_controller or GameRules.LegionDefence:GetMapController()
	self._spawned_units = self._spawned_units or {}

	local time = GameRules:GetDOTATime(false, false)

	-- Countdown to end of wave
	if self:IsWaveRunning() and self._wave_complete ~= nil then
		self._wave_complete = self._wave_complete - self:ThinkTime()
		if self._wave_complete <= 0 then
			self:WaveCompleted()
			self._wave_complete = nil
		end
	end

	-- Countdown to next wave
	if not self:IsWaveRunning() then
		if time >= self._next_wave_time then
			self:StartNextWave()
		end
	end

	-- Spawn a unit at every spawn point every think
	if self:IsWaveRunning() and self:CurrentWaveHasSpawnsRemaining() and (self._wave_start_time + self._before_wave_time) < time then

		local unit_to_spawn = self:GetAndPopNextSpawnInWave()
		for k, spawn in pairs( self._lane_controller:GetSpawnZonesForOccupiedLanes() ) do

			local ent = spawn.entity
			local vPosition = RandomVectorInTrigger( ent )
			if unit_to_spawn then

				local hUnit = CreateUnitByName( unit_to_spawn, vPosition, true, nil, nil, self:GetEnemyTeam(spawn.team) )
				local entTargetZone = self._map_controller:GetTargetZoneForTeam( spawn.team )
				local vTarget = RandomVectorInTrigger( entTargetZone )
				local hKing = GameRules.LegionDefence:GetKingController():GetKingForTeam(spawn.team)

				if hUnit ~= nil then

					-- TODO: Make units face spawn zone regardless of spawn position
					hUnit:SetAngles( 0, -90, 0 )

					local unit_data = {
						unit = hUnit,
						lane = spawn.lane,
						target_pos = vTarget,
						target_king = hKing
					}
					table.insert( self._spawned_units, unit_data )

				end

			end

		end

	end

	-- Move spawned units to the target zone
	for i, unit_data in pairs( self._spawned_units ) do
		local unit = unit_data.unit
		if unit and IsValidEntity(unit) then
			if not unit:IsAttacking() then
				unit:MoveToTargetToAttack( unit_data.target_king )
			end
		else
			self._spawned_units[i] = nil
		end
	end

	-- Think again
	return self:ThinkTime()
	
end

function CWaveController:GetEnemyTeam( iTeam )
	return CWaveController.ENEMY_TEAMS[iTeam]
end

function CWaveController:GetCurrentWave()
	return self._current_wave
end

function CWaveController:IsWaveRunning()
	return self._wave_in_progress
end

function CWaveController:SetNextWaveTime( time )
	self._next_wave_time = time
	CustomNetTables:SetTableValue( CWaveController.WAVE_INFO_TABLE, "next_wave_time", { time = time } )
end

function CWaveController:BuildWaveListData()

	local kv_units = LoadKeyValues("scripts/npc/npc_units_custom.txt")

	-- Run through all waves
	for i, wave_data in pairs( self._waves_list ) do
		for k, v in pairs( wave_data ) do

			-- Find our spawned enemies
			local unit_data = kv_units[k]
			if string.find(k, "npc_legion_") and unit_data then

				-- Get data from kv file and add extra unit data
				local attack_capability = unit_data["AttackCapabilities"]
				local damage_type = unit_data["CombatClassAttack"]
				local defence_type = unit_data["CombatClassDefend"]

				wave_data.attack_capability = attack_capability
				wave_data.damage_type = damage_type
				wave_data.defence_type = defence_type

			end

		end
	end

end

function CWaveController:UpdateWavesData()

	local wave_data = {}

	-- Build list of current wave set
	local set_size = CWaveController.NUM_WAVES_IN_SET
	local start_of_set = math.floor(self:GetCurrentWave() / set_size) * set_size + 1
	local end_of_set = math.floor((self:GetCurrentWave() + set_size) / set_size) * set_size

	for i = start_of_set, end_of_set, 1 do

		local data = {
			wave = self._waves_list[tostring(i)],
			complete = i < self:GetCurrentWave()
		}

		table.insert( wave_data, data )

	end

	wave_data["next_wave"] = self:GetCurrentWave()
	wave_data["set_size"] = set_size
	wave_data["start_of_set"] = start_of_set
	wave_data["end_of_set"] = end_of_set

	-- Send data to players
	CustomNetTables:SetTableValue( CWaveController.WAVE_INFO_TABLE, "waves", wave_data )

end

function CWaveController:StartWave( iWave )

	self._current_wave = iWave
	if self:GetWave() then

		-- Start wave
		self._wave_in_progress = true
		self._wave_start_time = GameRules:GetDOTATime(false, false)

		-- Only add NPC units to the spawns instead of data
		self._wave_spawns_remaining = {}
		for k, v in pairs( self:GetWave() ) do
			if string.sub(k, 1, 4) == "npc_" then
				self._wave_spawns_remaining[k] = v
			end
		end

		-- Call start wave event
		local data = {
			["nWaveNumber"] = self._current_wave,
			["sEnemyName"] = nil,
			["nTotalEnemies"] = self:GetNumberOfSpawnsInWave(),
		}
		FireGameEvent( "legion_wave_start", data )

		-- Print wave info to console
		print(string.format("Starting Wave %i", iWave))
		self:PrintWaveEnemyList( iWave )

	end

end

function CWaveController:StartNextWave( bForceWave )
	if not self:IsWaveRunning() or (self:IsWaveRunning() and bForceWave) then
		self:StartWave( self._current_wave + 1 )
	end
end

function CWaveController:SetWave( iWave )
	self._current_wave = iWave
end

function CWaveController:GetWave( iWave )
	return self._waves_list[tostring(iWave or self._current_wave)]
end

function CWaveController:GetNumberOfSpawnsInWave( iWave )
	local n = 0
	for k, v in pairs( self:GetWave(iWave) ) do
		if string.sub(k, 1, 4) == "npc_" then
			n = n + v
		end
	end
	return n
end

function CWaveController:CurrentWaveHasSpawnsRemaining()
	if self._wave_spawns_remaining then
		for k, v in pairs( self._wave_spawns_remaining ) do
			if v > 0 then
				return true
			end
		end
		return false
	else
		return false
	end
end

function CWaveController:GetAndPopNextSpawnInWave()
	for k, v in pairs( self._wave_spawns_remaining ) do
		if v > 0 then
			self._wave_spawns_remaining[k] = v - 1
			return k
		end
	end
	return nil
end

function CWaveController:PrintWaveEnemyList( iWave )

	if self._waves_list[tostring(iWave)] then

		print(string.format("Wave %i Enemies", iWave))
		for k, v in pairs( self._waves_list[tostring(iWave)] ) do
			if string.sub(k, 1, 4) == "npc_" then
				print(string.format("\t%s x%i", k, v))
			end
		end
		print("-----")

	else
		print(string.format("Wave %i not found.", iWave))
	end

end

function CWaveController:OnUnitKilled( event )

	local killedUnit = EntIndexToHScript(event.entindex_killed)
	local attackerUnit = EntIndexToHScript(event.entindex_attacker)

	for i, unit_data in pairs( self._spawned_units ) do
		if unit_data.unit and IsValidEntity(unit_data.unit) and unit_data.unit:GetEntityIndex() == killedUnit:GetEntityIndex() then
			
			-- Remaining units in this lane
			local laneId = unit_data.lane
			local remainInLane = self:GetRemainingUnitsInLane(laneId)
			print(string.format("Remaining units in lane %i: %i", laneId, remainInLane))
			if remainInLane <= 0 then
				local playerId = GameRules.LegionDefence:GetLaneController():GetPlayerForLane( laneId )
				if playerId ~= nil then
					GameRules.LegionDefence:GetUnitController():OnLaneCleared( laneId, playerId )
				end
			end

			-- Remaining units in wave
			local remainInWave = self:GetRemainingUnitsInCurrentWave()
			if remainInWave <= 0 then
				self:WavePreCompleted()
			end

			-- Give bounty
			if attackerUnit then

				local hasOwnerPlayer = attackerUnit:GetOwner() and true or false
				local ownerUnit = attackerUnit:GetOwner() and attackerUnit:GetOwner():GetAssignedHero() or attackerUnit
				local bounty = killedUnit:GetGoldBounty()
				local bounty_currency = CURRENCY_GOLD

				-- Give bounty gold
				if hasOwnerPlayer then
					GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( bounty_currency, ownerUnit, bounty, true )
				end

				-- Show particles
				ShowGoldPopup( killedUnit, bounty )
				PlayCurrencyGainedParticles( bounty_currency, bounty, ownerUnit, killedUnit:GetCenter(), true )

			end

		end
	end

end

function CWaveController:GetRemainingUnitsInCurrentWave()

	if not self:IsWaveRunning() then
		return 0
	end

	local remaining = 0

	-- Count units in spawn queue
	for k, v in pairs( self._wave_spawns_remaining ) do
		remaining = remaining + v
	end

	-- Count units on field
	for i, unit_data in pairs( self._spawned_units ) do
		if IsValidEntity(unit_data.unit) and unit_data.unit:IsAlive() then
			remaining = remaining + 1
		end
	end

	return remaining

end

function CWaveController:GetRemainingUnitsInLane( laneId )

	if not self:IsWaveRunning() then
		return 0
	end

	local remaining = 0

	-- Count units in spawn queue
	for k, v in pairs( self._wave_spawns_remaining ) do
		remaining = remaining + v
	end

	-- Count units on field
	for i, unit_data in pairs( self._spawned_units ) do
		if unit_data.lane == laneId and IsValidEntity(unit_data.unit) and unit_data.unit:IsAlive() then
			remaining = remaining + 1
		end
	end

	return remaining

end

function CWaveController:WavePreCompleted()
	print(string.format("All units in wave %i killed!", self._current_wave))
	self._wave_complete = self._end_of_wave_time
end

function CWaveController:WaveCompleted()

	print(string.format("Completed Wave %i", self._current_wave))

	-- Send wave data to all players
	local data = {
		["nWaveNumber"] = self._current_wave,
		["sEnemyName"] = nil,
		["nTotalEnemies"] = self:GetNumberOfSpawnsInWave(),
		["nEnemiesKilled"] = nil,
		["nEnemiesLeaked"] = nil,
		["lFastestPlayer"] = nil,
	}
	FireGameEvent( "legion_wave_complete", data )

	-- Wave no longer in progress
	self._wave_in_progress = false

	-- Set next wave time
	self:SetNextWaveTime( GameRules:GetDOTATime(false, false) + self._time_between_waves )

	-- Update next waves data
	self:UpdateWavesData()

end

function CWaveController:GetUnitLane( hUnit )

	for i, unit_data in pairs( self._spawned_units ) do
		if IsValidEntity(unit_data.unit) and unit_data.unit == hUnit then
			return unit_data.lane
		end
	end

	return nil

end

----------------------------------
-- Leaked Waves
----------------------------------
function CWaveController:RecordWaveAsLeakedByPlayer( iPlayerId, iWave )

	if iPlayerId ~= nil then
		iWave = iWave or self:GetCurrentWave()
		self._leaks_list[iPlayerId] = self._leaks_list[iPlayerId] or {}
		self._leaks_list[iPlayerId][iWave] = true
	end

end

function CWaveController:RecordWaveAsLeakedFromUnit( hUnit, iWave )

	iWave = iWave or self:GetCurrentWave()
	local laneId = self:GetUnitLane( hUnit )
	local playerId = GameRules.LegionDefence:GetLaneController():GetPlayerForLane( laneId )
	if playerId ~= nil then
		self:RecordWaveAsLeakedByPlayer( playerId, iWave )
	end

end

function CWaveController:GetNumberOfWavesLeakedByPlayer( iPlayerId )
	if iPlayerId ~= nil and self._leaks_list[iPlayerId] then
		return #self._leaks_list[iPlayerId]
	end
	return 1
end

function CWaveController:GetNumberOfWavesLeakedFromUnit( hUnit )
	local laneId = self:GetUnitLane( hUnit )
	local playerId = GameRules.LegionDefence:GetLaneController():GetPlayerForLane( laneId )
	if playerId ~= nil then
		return self:GetNumberOfWavesLeakedByPlayer( playerId )
	end
end

----------------------------------
-- Unit Functions
----------------------------------
function CWaveController:GetArmourModifierItem( item_name )

	self.__armour_items = self.__armour_items or {}

	-- Cache the armour item so we don't continuously destroy and recreate it for no reason
	if not self.__armour_items[item_name] then
		self.__armour_items[item_name] = CreateItem(item_name, nil, nil)
	end
	return self.__armour_items[item_name]

end

function CWaveController:IsUnitAWaveUnit( hUnit )
	for i, unit_data in pairs( self._spawned_units ) do
		if IsValidEntity(unit_data.unit) and unit_data.unit == hUnit then
			return true
		end
	end
	return false
end

function CWaveController:AttemptIncreaseArmourOnUnit( hUnit, iArmourTier )

	if self:IsUnitAWaveUnit(hUnit) then

		-- Add current wave to list of waves that were leaked by this player
		self:RecordWaveAsLeakedFromUnit( hUnit )

		-- Reduce this units bounty if it doesn't have an armour buff
		local canReduceBounty = true
		for k, v in ipairs(CWaveController.ARMOUR_TIERS) do
			if hUnit:FindModifierByName(v.modifier) then
				canReduceBounty = false
				break
			end
		end
		if canReduceBounty then
			local leakedWaves = self:GetNumberOfWavesLeakedFromUnit(hUnit) or 1
			local bountyMultiplier = CWaveController.LEAKED_WAVE_BOUNTY_MULTIPLIERS[leakedWaves]
			hUnit:SetMinimumGoldBounty( math.floor(hUnit:GetMinimumGoldBounty() * bountyMultiplier) )
			hUnit:SetMaximumGoldBounty( math.floor(hUnit:GetMaximumGoldBounty() * bountyMultiplier) )
		end

		-- Get item for this armour buff
		local buff_data = CWaveController.ARMOUR_TIERS[iArmourTier]
		if buff_data.item == nil then
			buff_data.item = self:GetArmourModifierItem( buff_data.item_name )
		end

		-- Check unit doesn't already have this armour buff
		local modifier = CWaveController.ARMOUR_TIERS[iArmourTier].modifier
		if not hUnit:FindModifierByName(modifier) then

			-- Apply modifier from armour item to the leaked unit
			if buff_data.item then
				buff_data.item:ApplyDataDrivenModifier(hUnit, hUnit, modifier, nil)
			end

		end

	end

end
