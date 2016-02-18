
if CWaveController == nil then
	CWaveController = class({})
end

-- Modifiers are in npc_items_custom.txt
CWaveController.ARMOUR_TIERS = {
	[1] = {
		item_name = "item_leaked_unit_armour_bonus_1",
		modifier = "modifier_armour_bonus_leaked_unit_1",
		particle = "particles/units/armour_buff_tier_1.vpcf"
	},
	[2] = {
		item_name = "item_leaked_unit_armour_bonus_2",
		modifier = "modifier_armour_bonus_leaked_unit_2",
		particle = "particles/units/armour_buff_tier_2.vpcf"
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

CWaveController.WAVE_INFO_TABLE = "UpcomingWaveData"
CWaveController.NUM_WAVES_IN_SET = 10

CWaveController.FIRST_WAVE_DELAY = 60
CWaveController.WAVE_DOWNTIME = 40
CWaveController.PRE_WAVE_DELAY = 3
CWaveController.POST_WAVE_DELAY = 3

CWaveController.THINK_TIME = 1
CWaveController.THINK_TIME_WAVE = 0.2
CWaveController.THINK_TIME_ANTISTUCK = 4
CWaveController.THINK_TIME_LEAKS = 0.5

function CLegionDefence:SetupWaveController()
	self.wave_controller = CWaveController()
	self.wave_controller:Setup()
	if GameRules:GetGameModeEntity()._developer then
		self.wave_controller:SetupDebug()
	end
end

function CLegionDefence:GetWaveController()
	return self.wave_controller
end

function CWaveController:Setup()

	self._waves_list = LoadKeyValues("scripts/kv/legion_waves.txt")
	self._leaks_list = {}

	self._current_wave = 0
	self._wave_in_progress = false

	self:BuildWaveListData()
	self:UpdateWavesData()

	-- Think entity for this controller
	self._think_ent = IsValidEntity(self._think_ent) and self._think_ent or Entities:CreateByClassname("info_target")
	self._think_ent:SetThink("OnThink", self, "WaveControllerThink", CWaveController.THINK_TIME)
	self._think_ent:SetThink("OnAntiStuckThink", self, "WaveControllerAntiStickThink", CWaveController.THINK_TIME_ANTISTUCK)
	self._think_ent:SetThink("OnLeakPointsThink", self, "WaveControllerLeakPointThink", CWaveController.THINK_TIME_LEAKS)

	-- Events
	ListenToGameEvent("legion_hero_selection_complete", Dynamic_Wrap(CWaveController, "OnHeroSelectionComplete"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CWaveController, "OnUnitKilled"), self)

end

function CWaveController:SetupDebug()

	Convars:RegisterCommand( "legion_set_wave", function(name, parameter)
		local cmdPlayer = Convars:GetCommandClient()
		local new_wave = tonumber(parameter)
		if cmdPlayer and new_wave then 
			self:SetWave( new_wave - 1 )
			self:UpdateWavesData()
		end
	end, "Go directly to the specified wave", FCVAR_CHEAT )

	Convars:RegisterCommand( "legion_end_wave", function(name, parameter)
		local cmdPlayer = Convars:GetCommandClient()
		if cmdPlayer and self:IsWaveRunning() then 
			self:DebugCompleteWave()
		end
	end, "Instantly complete the current wave", FCVAR_CHEAT )

end

function CWaveController:ThinkTime()
	return self:IsWaveRunning() and CWaveController.THINK_TIME_WAVE or CWaveController.THINK_TIME
end

CWaveController.WAVE_STATES = {
	"_NextWaveCountdown",
	"_WaveCountdown",
	"_PreWaveCountdown",
	"_WaveCountdown",
	"_WaveSpawning",
	"_PostWaveCountdown",
	"_WaveCountdown",
	"_NextWaveRestartLoop"
}

function CWaveController:OnHeroSelectionComplete( data )

	if not self._wave_state then
		self:_SetWaveCountdown( CWaveController.FIRST_WAVE_DELAY )
		self:SetNextWaveTime( CWaveController.FIRST_WAVE_DELAY )
		self._wave_state = 2
	end

end

function CWaveController:OnThink()

	self._lane_controller = self._lane_controller or GameRules.LegionDefence:GetLaneController()
	self._map_controller = self._map_controller or GameRules.LegionDefence:GetMapController()
	self._unit_controller = self._unit_controller or GameRules.LegionDefence:GetUnitController()
	self._spawned_units = self._spawned_units or {}

	local time = GameRules:GetDOTATime(false, false)

	-- Run state function for wave controller
	if self._wave_state then

		local state_function = CWaveController.WAVE_STATES[self._wave_state]
		if state_function and self[state_function] then
			self[state_function](self, time)
		end

	end

	-- Think again
	return self:ThinkTime()
	
end

function CWaveController:_AdvanceWaveState()
	self._wave_state = (self._wave_state or 0) + 1
	print("Advancing wave state to " .. tostring(CWaveController.WAVE_STATES[self._wave_state]) .. "...")
end

function CWaveController:_RestartWaveState()
	self._wave_state = 0
	self:_AdvanceWaveState()
end

function CWaveController:_SetWaveCountdown( time )
	self._wave_countdown = time
end

function CWaveController:_WaveCountdown( time )

	self._wave_countdown = self._wave_countdown or 1
	self._wave_countdown = self._wave_countdown - self:ThinkTime()

	if self._wave_countdown <= 0 then
		self:_AdvanceWaveState()
	end

end

function CWaveController:_NextWaveCountdown( time )
	self:_SetWaveCountdown( CWaveController.WAVE_DOWNTIME )
	self:SetNextWaveTime( CWaveController.WAVE_DOWNTIME )
	self:_AdvanceWaveState()
end

function CWaveController:_PreWaveCountdown( time )
	self:StartNextWave()
	self:_SetWaveCountdown( CWaveController.PRE_WAVE_DELAY )
	self:_AdvanceWaveState()
end

function CWaveController:_WaveSpawning( time )

	local think_func = self:GetWave()["wave_type"]
	if think_func and self[think_func] then
		self[think_func](self, time)
	else
		self:_AdvanceWaveState()
	end

end

function CWaveController:_PostWaveCountdown( time )
	self:_SetWaveCountdown( CWaveController.POST_WAVE_DELAY )
	self:_AdvanceWaveState()
end

function CWaveController:_NextWaveRestartLoop( time )
	self:WaveCompleted()
	self:_RestartWaveState()
end

---------------------------
-- Think Behaviours
---------------------------
-- Spawning to make a wave spawn its units and then attack the king
function CWaveController:StandardWaveThink( time )

	-- Spawn a unit at every spawn point every think
	local waveIsReady = self:IsWaveRunning()
	local unitsRemaining = self:CurrentWaveHasSpawnsRemaining()
	local gameIsReady = not GameRules:IsGamePaused()
	if waveIsReady and gameIsReady then

		-- Spawn wave units
		if unitsRemaining then

			local waveUnitToSpawn = self:GetAndPopNextSpawnInWave()
			for k, spawn in pairs( self._lane_controller:GetSpawnZonesForOccupiedLanes() ) do

				local ent = spawn.entity

				if waveUnitToSpawn then
					
					-- Spawn wave unit
					local vPosition = RandomVectorInTrigger( ent )
					local hUnit = CreateUnitByName( waveUnitToSpawn, vPosition, true, nil, nil, GetEnemyTeam(spawn.team) )
					local entTargetZone = self._map_controller:GetTargetZoneForTeam( spawn.team ).entity
					local hKing = GameRules.LegionDefence:GetKingController():GetKingForTeam(spawn.team)

					if hUnit then

						local angles = ent:GetAnglesAsVector()
						hUnit:SetAngles( angles.x, angles.y, angles.z )

						self:AddSpawnedUnit( hUnit, spawn.lane, entTargetZone, hKing )
						self:PlaySpawnParticle( hUnit )

					end

				end

			end

		end

		-- Allow other controllers to spawn units
		FireGameEvent( "legion_perform_wave_spawn", {} )

	end

	self:OrderSpawnedUnitsToAttackKing()

end

-- Spawning for the final wave of the game, to eliminate a king
function CWaveController:EndlessWaveThink( time )

	local MAX_UNITS_TO_SPAWN = 30

	-- Spawn up to a maximum amount of units and then maintain that number
	local waveIsReady = self:IsWaveRunning()
	local gameIsReady = not GameRules:IsGamePaused()
	if waveIsReady and gameIsReady then

		local waveUnitToSpawn = self:GetNextWaveSpawn()
		for k, spawn in pairs( self._lane_controller:GetSpawnZonesForOccupiedLanes() ) do

			local spawned_units = self:GetSpawnedUnitsInLane( spawn.lane )
			if spawned_units < MAX_UNITS_TO_SPAWN and waveUnitToSpawn then
				
				-- Spawn wave unit
				local ent = spawn.entity
				local vPosition = RandomVectorInTrigger( spawn.entity )
				local hUnit = CreateUnitByName( waveUnitToSpawn, vPosition, true, nil, nil, GetEnemyTeam(spawn.team) )
				local entTargetZone = self._map_controller:GetTargetZoneForTeam( spawn.team ).entity
				local hKing = GameRules.LegionDefence:GetKingController():GetKingForTeam(spawn.team)

				if hUnit then

					local angles = ent:GetAnglesAsVector()
					hUnit:SetAngles( angles.x, angles.y, angles.z )

					self:AddSpawnedUnit( hUnit, spawn.lane, entTargetZone, hKing )
					self:PlaySpawnParticle( hUnit )

				end

			end

		end

		-- Allow other controllers to spawn units
		FireGameEvent( "legion_perform_wave_spawn", {} )

	end

	self:OrderSpawnedUnitsToAttackKing()

end

function CWaveController:OrderSpawnedUnitsToAttackKing()

	-- Move spawned units to the target zone
	for i, unit_data in pairs( self._spawned_units ) do
		local unit = unit_data.unit
		if unit and IsValidEntity(unit) then
			if not unit:IsAttacking() and unit_data.target_king and IsValidEntity(unit_data.target_king) and unit_data.target_king:IsAlive() then

				-- Units won't attack king if using attack move, so when we're within a reasonable distance,
				-- exclusively attempt to attack the king unit
				local dist = CalcDistanceBetweenEntityOBB( unit, unit_data.target_king )
				if dist < 1000 then

					local data = {
						UnitIndex = unit:entindex(), 
						OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
						TargetIndex = unit_data.target_king:entindex(),
						Queue = 0
					}
					ExecuteOrderFromTable(data)

				else

					local data = {
						UnitIndex = unit:entindex(), 
						OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
						Position = unit_data.target_king:GetCenter(),
						Queue = 0
					}
					ExecuteOrderFromTable(data)

				end

			end
		else
			self._spawned_units[i] = nil
		end
	end

end

---------------------------
-- Arena
---------------------------
CWaveController.ARENA_STATES = {
	"_TeleportAllUnitsToArena",
	"_UnlockUnitMovement",
	"_ArenaCountdown",
	"_ArenaFight",
	"_ShowVictoryGestures",
}
CWaveController.PRE_FIGHT_COUNTDOWN = 3
CWaveController.POST_FIGHT_COUNTDOWN = 3

CWaveController.ARENA_WIN_AMOUNT = 100
CWaveController.ARENA_WIN_CURRENCY = CURRENCY_GOLD

-- Spawning to make all lanes from both teams fight each other
function CWaveController:ArenaWaveThink( time )

	self._arena_state = self._arena_state or 1
	if not self._arena_units then
		self._arena_units = {}
	end

	local waveIsReady = self:IsWaveRunning()
	local gameIsReady = not GameRules:IsGamePaused()
	if waveIsReady and gameIsReady then

		local state_function = CWaveController.ARENA_STATES[self._arena_state]
		if state_function and self[state_function] then
			self[state_function](self, time)
		else
			print("Arena finished...")
			self:_AdvanceWaveState()
		end

	end

end

function CWaveController:_AdvanceArenaState()
	self._arena_state = self._arena_state or 1
	self._arena_state = self._arena_state + 1
	print("Advancing arena state to " .. tostring(CWaveController.ARENA_STATES[self._arena_state]) .. "...")
end

function CWaveController:_SpawnExtraArenaUnit( spawnZone, unitType, iAmount )

	for i = 1, unit_amount do
				
		local hUnit = CreateUnitByName( unitType, RandomVectorInTrigger(spawnZone.entity), false, nil, nil, spawnZone.team )
		local data = {
			unit = hUnit,
			team = spawnZone.team
		}
		table.insert( self._arena_units, data )

	end

end

function CWaveController:_TeleportAllUnitsToArena( time )

	local mercenary_controller = GameRules.LegionDefence:GetMercenaryController()

	-- Teleport all units on teams into the arena spawns
	for k, arena_spawn in pairs( self._map_controller:ArenaZones() ) do

		local team_lanes = self._lane_controller:GetOccupiedLanesForTeam(arena_spawn.team)

		-- Spawn units from team lanes
		for i, lane in pairs( team_lanes ) do

			local player_id = self._lane_controller:GetPlayerForLane( lane )
			local units = self._unit_controller:GetAllUnitsForPlayer( player_id ) or {}

			-- Spawn all units in arena
			for x, unit_data in pairs( units ) do
				self:_SpawnUnitInArena( unit_data.unit, arena_spawn )
			end

		end

		-- Spawn mercenary units with the team spawns
		local merc_units = mercenary_controller:GetMercenariesSpawnedByTeam( arena_spawn.team )
		for k, v in pairs( merc_units ) do
			self:_SpawnUnitInArena( v.unit, arena_spawn )
		end

		-- Team has less players than the other team
		local enemy_team_lanes = self._lane_controller:GetOccupiedLanesForTeam( GetEnemyTeam(arena_spawn.team) )
		if #team_lanes > 0 and #team_lanes < #enemy_team_lanes then

			local wave_data = self:GetWave()
			local unit = wave_data["arena_boss_unit"]
			local team_difference = #enemy_team_lanes - #team_lanes
			self:_SpawnExtraArenaUnit( arena_spawn, unit, team_difference )

		-- No units on this team, spawn the backup unit instead
		elseif #team_lanes == 0 then

			local wave_data = self:GetWave()
			local unit = wave_data["arena_boss_unit"]
			local unit_amount = wave_data["arena_boss_amount"] and tonumber(wave_data["arena_boss_amount"]) or 0
			self:_SpawnExtraArenaUnit( arena_spawn, unit, unit_amount )

		end

	end

	-- Clear mercenaries
	mercenary_controller:ClearSpawnedMercenariesUnits()

	-- Advance arena state
	self:_SetArenaCountdownTime( CWaveController.PRE_FIGHT_COUNTDOWN )
	self:_AdvanceArenaState()

end

function CWaveController:_SpawnUnitInArena( hUnit, tSpawnZone )

	-- Show particles at unit position
	nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_relocate_teleport_c.vpcf", PATTACH_WORLDORIGIN, hUnit )
	ParticleManager:SetParticleControl( nFXIndex, 0, hUnit:GetOrigin() )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

	-- Teleport unit to destination
	local teleport_pos = RandomVectorInTrigger( tSpawnZone.entity )
	FindClearSpaceForUnit( hUnit, teleport_pos, true )

	-- Show particles at destination
	nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf", PATTACH_WORLDORIGIN, hUnit )
	ParticleManager:SetParticleControl( nFXIndex, 0, teleport_pos )
	ParticleManager:SetParticleControl( nFXIndex, 1, RandomVector(360) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

	-- Add unit to arena units
	local data = {
		unit = hUnit,
		team = hUnit:GetOwner() and hUnit:GetOwner():GetTeamNumber() or tSpawnZone.team
	}
	table.insert( self._arena_units, data )

end

function CWaveController:_UnlockUnitMovement()
	self._unit_controller:SetUnitsFrozen(false)
	self:_AdvanceArenaState()
end

function CWaveController:_ArenaFight( time )

	local arena_centre = self._map_controller:ArenaCentre()
	local team_counts = {}

	if arena_centre then

		arena_centre = arena_centre.entity:GetOrigin()

		-- Run through all units
		for k, v in pairs( self._arena_units ) do

			if IsValidEntity(v.unit) and v.unit:IsAlive() then

				-- Move all units to the centre of the area
				if not v.unit:IsAttacking() then
					local data = {
						UnitIndex = v.unit:entindex(), 
						OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
						Position = arena_centre,
						Queue = 0
					}
					ExecuteOrderFromTable(data)
				end

				-- Count number of living units on each team
				team_counts[v.team] = (team_counts[v.team] or 0) + 1

			else

				-- Ensure team is recorded
				team_counts[v.team] = (team_counts[v.team] or 0)

			end

		end

		-- Find all teams with no more units
		local winning_team
		local losing_teams = {}
		for k, v in pairs( team_counts ) do
			if v == 0 then
				table.insert( losing_teams, k )
			end
		end

		-- Check if there is a single team that still has units
		if #losing_teams > 0 then
			for k, v in pairs( team_counts ) do
				if v > 0 then
					if winning_team == nil then
						winning_team = k
					else
						winning_team = nil
					end
				end
			end
		end

		-- Show winning team
		if winning_team ~= nil then

			-- Declare winning team
			print(string.format("Arena winner, team %i!", winning_team))
			if winning_team == DOTA_TEAM_GOODGUYS then
				SendCustomChatMessage( "legion_arena_winner_radiant", { arg_number = CWaveController.ARENA_WIN_AMOUNT, arg_string = "#legion_team_goodguys" } )
			end
			if winning_team == DOTA_TEAM_BADGUYS then
				SendCustomChatMessage( "legion_arena_winner_dire", { arg_number = CWaveController.ARENA_WIN_AMOUNT, arg_string = "#legion_team_badguys" } )
			end

			-- Give income to winning teams plaeyrs
			local currency_controller = GameRules.LegionDefence:GetCurrencyController()
			local team_lanes = self._lane_controller:GetOccupiedLanesForTeam( winning_team )
			for i, lane in pairs( team_lanes ) do
				local player_id = self._lane_controller:GetPlayerForLane( lane )
				currency_controller:ModifyCurrency( CWaveController.ARENA_WIN_CURRENCY, player_id, CWaveController.ARENA_WIN_AMOUNT )
			end

			self:_AdvanceArenaState()

		end

		-- All teams have lost all their units, or there are no units in the arena
		if #losing_teams == #team_counts or #team_counts == 0 then
			print("Arena draw!")
			SendCustomChatMessage( "legion_arena_winner_draw" )
			self:_AdvanceArenaState()
		end

	end

end

function CWaveController:_SetArenaCountdownTime( time )
	self._arena_countdown = time
end

function CWaveController:_ArenaCountdown( time )

	self._arena_countdown = self._arena_countdown or 1
	self._arena_countdown = self._arena_countdown - self:ThinkTime()

	if self._arena_countdown <= 0 then
		self:_AdvanceArenaState()
	end

end

function CWaveController:_ShowVictoryGestures( time )

	-- Lock units
	self._unit_controller:SetUnitsFrozen(true)

	-- All units on the victory side should play gestures
	for k, v in pairs( self._arena_units ) do

	end
	self._arena_units = nil

	-- Countdown to ending the wave
	self:_AdvanceArenaState()

end

---------------------------
-- Anti-Stuck
---------------------------
function CWaveController:OnAntiStuckThink()

	-- Only run antistick when we've spawned everything
	local waveIsReady = self:IsWaveRunning()
	local unitsRemaining = self:CurrentWaveHasSpawnsRemaining()
	local gameIsReady = not GameRules:IsGamePaused()
	if waveIsReady and gameIsReady and not unitsRemaining then

		self._map_controller = self._map_controller or GameRules.LegionDefence:GetMapController()

		for i, unit_data in pairs( self._spawned_units ) do
			local unit = unit_data.unit
			if unit and IsValidEntity(unit) and unit:IsAlive() then

				local spawn_zone = self._map_controller:GetSpawnZoneForLane(unit_data.lane).entity
				if spawn_zone and IsPositionInTrigger( spawn_zone, unit:GetCenter() ) then
					local vPosition = RandomVectorInTrigger( spawn_zone )
					FindClearSpaceForUnit( unit, vPosition, true )
				end

			end
		end

	end

	return CWaveController.THINK_TIME_ANTISTUCK

end

---------------------------
-- Waves Utilities
---------------------------
function CWaveController:AddSpawnedUnit( hUnit, laneId, hTargetZone, hTargetKing )
	if hUnit and not hUnit:IsNull() then
		local unit_data = {
			unit = hUnit,
			lane = laneId,
			target_zone = hTargetZone,
			target_king = hTargetKing
		}
		table.insert( self._spawned_units, unit_data )
	else
		error("Can not add a nil spawned unit to the wave data")
	end
end

function CWaveController:PlaySpawnParticle( hUnit )
	if hUnit then
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_relocate_teleport_c.vpcf", PATTACH_WORLDORIGIN, hUnit )
		ParticleManager:SetParticleControl( nFXIndex, 0, hUnit:GetCenter() )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
	end
end

function CWaveController:GetCurrentWave()
	return self._current_wave
end

function CWaveController:IsWaveRunning()
	return self._wave_in_progress
end

function CWaveController:SetNextWaveTime( time )
	local game_time = GameRules:GetDOTATime(false, false) + time
	CustomNetTables:SetTableValue( CWaveController.WAVE_INFO_TABLE, "next_wave_time", { time = game_time } )
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

	local i = 1
	while i <= end_of_set do

		local data = {
			wave = self._waves_list[tostring(i)],
			complete = i < self:GetCurrentWave()
		}

		table.insert( wave_data, data )

		-- Arena waves don't count towards the size of the set
		if data.wave and data.wave.arena then
			set_size = set_size + 1
			end_of_set = end_of_set + 1
		end

		-- Increment
		i = i + 1

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

function CWaveController:GetSpawnedUnitsInLane( iLane )

	local count = 0
	for k, v in pairs( self._spawned_units ) do
		if v.lane == iLane then
			count = count + 1
		end
	end
	return count

end

function CWaveController:GetNextWaveSpawn()
	for k, v in pairs( self._wave_spawns_remaining ) do
		return k
	end
	return nil
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

		if self._waves_list[tostring(iWave)].arena then

			print(string.format("Wave %i\n\tArena Fight", iWave))

		else

			print(string.format("Wave %i Enemies", iWave))
			for k, v in pairs( self._waves_list[tostring(iWave)] ) do
				if string.sub(k, 1, 4) == "npc_" then
					print(string.format("\t%s x%i", k, v))
				end
			end

		end

		print("-----")

	else
		print(string.format("Wave %i not found.", iWave))
	end

end

function CWaveController:OnUnitKilled( event )

	local lane_controller = GameRules.LegionDefence:GetLaneController()
	local unit_controller = GameRules.LegionDefence:GetUnitController()

	local killedUnit = EntIndexToHScript(event.entindex_killed)
	local attackerUnit = EntIndexToHScript(event.entindex_attacker)

	for i, unit_data in pairs( self._spawned_units ) do
		if unit_data.unit and IsValidEntity(unit_data.unit) and unit_data.unit:GetEntityIndex() == killedUnit:GetEntityIndex() then
			
			-- Remaining units in this lane
			local laneId = unit_data.lane
			local remainInLane = self:GetRemainingUnitsInLane(laneId)
			print(string.format("Remaining units in lane %i: %i", laneId, remainInLane))
			if remainInLane <= 0 then
				local playerId = lane_controller:GetPlayerForLane( laneId )
				if playerId ~= nil then

					local data = {
						["lPlayer"] = playerId,
						["lLane"] = laneId,
					}
					FireGameEvent( "legion_lane_complete", data )

				end
			end

			-- Remaining units in wave
			local remainInWave = self:GetRemainingUnitsInCurrentWave()
			if remainInWave <= 0 then
				print(string.format("All units in wave %i killed!", self._current_wave))
				self:_AdvanceWaveState()
			end

			-- Give bounty
			if attackerUnit then

				local attackerUnitData = unit_controller:GetUnitData( attackerUnit )

				local owner_id = attackerUnitData and lane_controller:GetPlayerForLane(attackerUnitData.lane)
				local owner = owner_id ~= nil and PlayerResource:GetPlayer(owner_id)
				if not owner and attackerUnitData then
					print("No player in lane " .. attackerUnitData.lane .. ", returning gold to unit owner")
					owner = attackerUnit:GetOwner()
				end

				local hasOwnerPlayer = owner and true or false
				local ownerUnit = owner and owner:GetAssignedHero() or attackerUnit
				local bounty = killedUnit:GetGoldBounty()
				local bounty_currency = CURRENCY_GOLD

				if hasOwnerPlayer then
					
					-- Give bounty gold
					GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( bounty_currency, ownerUnit, bounty, true )

					-- Show currency popup to owner
					ShowCurrencyPopup( owner, killedUnit, bounty_currency, bounty )

				end

				-- Show particles
				PlayCurrencyGainedParticles( bounty_currency, bounty, ownerUnit, owner, killedUnit:GetCenter(), true )

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

function CWaveController:WaveCompleted()

	print(string.format("Completed Wave %i", self._current_wave))

	-- Send wave data to all players
	local data = {
		["nWaveNumber"] = self._current_wave,
	}
	FireGameEvent( "legion_wave_complete", data )

	-- Wave no longer in progress
	self._wave_in_progress = false

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

function CWaveController:DebugCompleteWave()

	for i, unit_data in pairs( self._spawned_units ) do
		if unit_data.unit and IsValidEntity(unit_data.unit) then
			UTIL_Remove( unit_data.unit )
		end
	end

	self._spawned_units = {}
	self:_AdvanceWaveState()

end

----------------------------------
-- Leaked Waves
----------------------------------
function CWaveController:RecordWaveAsLeakedByPlayer( iPlayerId, iWave )

	if iPlayerId ~= nil then
		iWave = iWave or self:GetCurrentWave()
		self._leaks_list[iPlayerId] = self._leaks_list[iPlayerId] or {}
		if not self._leaks_list[iPlayerId][iWave] then
			self._leaks_list[iPlayerId][iWave] = true
			return true
		end
	end
	return false

end

function CWaveController:RecordWaveAsLeakedFromUnit( hUnit, iWave )

	iWave = iWave or self:GetCurrentWave()
	local laneId = self:GetUnitLane( hUnit )
	local playerId = GameRules.LegionDefence:GetLaneController():GetPlayerForLane( laneId )
	if playerId ~= nil then

		local recorded = self:RecordWaveAsLeakedByPlayer( playerId, iWave )
		if recorded then
			
			local data = {
				["lPlayer"] = playerId,
				["lLane"] = laneId,
			}
			FireGameEvent( "legion_lane_leaked", data )

		end

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

function CWaveController:DidPlayerLeakWave( iPlayerId, iWave )
	if iPlayerId ~= nil then
		iWave = iWave or self:GetCurrentWave()
		self._leaks_list[iPlayerId] = self._leaks_list[iPlayerId] or {}
		return self._leaks_list[iPlayerId][iWave]
	end
	return false
end

----------------------------------
-- Leaked Units
----------------------------------
function CWaveController:OnLeakPointsThink()

	self._map_controller = self._map_controller or GameRules.LegionDefence:GetMapController()

	self:ProcessArmourPoints( self._map_controller:SmallArmourPoints(), 1 )
	self:ProcessArmourPoints( self._map_controller:LargeArmourPoints(), 2 )

	return CWaveController.THINK_TIME_LEAKS

end

function CWaveController:ProcessArmourPoints( tArmourPoints, iArmourTier )

	local RADIUS = 256

	if tArmourPoints then

		for k, v in pairs( tArmourPoints ) do

			local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS,
											v.entity:GetOrigin(),
											nil,
											RADIUS,
											DOTA_UNIT_TARGET_TEAM_BOTH,
											DOTA_UNIT_TARGET_ALL,
											DOTA_UNIT_TARGET_FLAG_NONE,
											FIND_ANY_ORDER,
											false)

			for i, unit in pairs( units ) do
				self:AttemptIncreaseArmourOnUnit( unit, iArmourTier )
			end

		end

	end

end

function CWaveController:GetArmourModifierItem( item_name )

	self.__armour_items = self.__armour_items or {}

	-- Cache the armour item so we don't continuously destroy and recreate it for no reason
	if not self.__armour_items[item_name] then
		self.__armour_items[item_name] = CreateItem(item_name, nil, nil)
	end
	return self.__armour_items[item_name]

end

function CWaveController:IsUnitAWaveUnit( hUnit )
	for i, unit_data in pairs( self._spawned_units or {} ) do
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
			if bountyMultiplier == nil then
				print("Bounty multiplier was nil!")
				print(string.format("Leaked waves: %i", leakedWaves))
				bountyMultiplier = 1.0
			end
			hUnit:SetMinimumGoldBounty( math.floor(hUnit:GetMinimumGoldBounty() * bountyMultiplier) )
			hUnit:SetMaximumGoldBounty( math.floor(hUnit:GetMaximumGoldBounty() * bountyMultiplier) )
		end

		-- Get item for this armour buff
		local buff_data = CWaveController.ARMOUR_TIERS[iArmourTier]
		if buff_data.item == nil then
			buff_data.item = self:GetArmourModifierItem( buff_data.item_name )
		end

		-- Check unit doesn't already have this armour buff
		if not hUnit:FindModifierByName(buff_data.modifier) then

			-- Apply modifier from armour item to the leaked unit
			if buff_data.item then
				buff_data.item:ApplyDataDrivenModifier(hUnit, hUnit, buff_data.modifier, nil)
			end

			-- Show particles on unit
			if buff_data.particle then
				local nFXIndex = ParticleManager:CreateParticle( buff_data.particle, PATTACH_POINT_FOLLOW, hUnit )
				ParticleManager:SetParticleControlEnt( nFXIndex, 0, hUnit, PATTACH_POINT_FOLLOW, "attach_hitloc", hUnit:GetCenter(), true )
				ParticleManager:ReleaseParticleIndex( nFXIndex )
			end

		end

	end

end
