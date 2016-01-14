
if CMercenaryController == nil then
	CMercenaryController = class({})
end

function CLegionDefence:SetupMercenaryController()
	self.mercenary_controller = CMercenaryController()
	self.mercenary_controller:Setup()
end

function CLegionDefence:GetMercenaryController()
	return self.mercenary_controller
end

---------------------------------------
-- Mercenary Controller
---------------------------------------
CMercenaryController.NET_TABLE = "MercenariesData"
CMercenaryController.PURCHASE_CURRENCY = CURRENCY_GEMS
CMercenaryController.THINK_TIME = 1

-- How many times should the wave controller tick before we start spawning mercenaries in a wave
CMercenaryController.SPAWN_DELAY = 5

function CMercenaryController:Setup()

	self._mercenaries = {}
	self._availability = {}
	self._spawned = {}

	-- Build mercenaries list
	self:BuildMercenariesList()

	-- Think
	self._think_ent = IsValidEntity(self._think_ent) and self._think_ent or Entities:CreateByClassname("info_target")
	self._think_ent:SetThink("OnThink", self, "MercenaryControllerThink", CMercenaryController.THINK_TIME)

	-- Events
	ListenToGameEvent("legion_perform_wave_spawn", Dynamic_Wrap(CMercenaryController, "HandleOnPerformWaveSpawn"), self)
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CMercenaryController, "HandleOnWaveCompleted"), self)
	CustomGameEventManager:RegisterListener( "legion_purchase_mercenary", Dynamic_Wrap(CMercenaryController, "HandleOnMercenaryPurchased") )

end

function CMercenaryController:BuildMercenariesList()

	-- Find all mercenary units
	local kv_units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for k, unit_data in pairs( kv_units ) do

		if string.find(k, "npc_legion_merc_") then

			-- Add data
			local data = {
				id = k,
				cost = unit_data["GemsCost"],
				income = unit_data["GoldIncome"],
				cooldown = unit_data["SpawnCooldown"],
				attack_capability = unit_data["AttackCapabilities"],
				damage_type = unit_data["CombatClassAttack"],
				defence_type = unit_data["CombatClassDefend"],
			}
			table.insert( self._mercenaries, data )

		end
	end

	-- Sort units by cost
	table.sort(self._mercenaries, function(a, b) return a.cost < b.cost end)

	-- Update net table
	CustomNetTables:SetTableValue( CMercenaryController.NET_TABLE, "units", self._mercenaries )

end

function CMercenaryController:OnThink()

	-- Don't process while paused
	if GameRules:IsGamePaused() then
		return CMercenaryController.THINK_TIME
	end

	-- Reduce cooldowns on all mercenaries
	for merc_id, players_table in pairs( self._availability ) do
		for player_id, merc_data in pairs( players_table ) do

			merc_data.cooldown = merc_data.cooldown - CMercenaryController.THINK_TIME
			if merc_data.cooldown < 0 then

				-- Clamp cooldown
				merc_data.cooldown = -1

				-- Increase amount at end of cooldown
				merc_data.amount = merc_data.amount + 1
				if merc_data.amount > merc_data.limit then
					merc_data.amount = merc_data.limit
				end

			end

		end
	end

	return CMercenaryController.THINK_TIME

end

function CMercenaryController:GetMercenaryData( mercId )

	for k, v in pairs( self._mercenaries or {} ) do
		if v.id == mercId then
			return v
		end
	end

end

function CMercenaryController:VerifyAvailabilityData( iPlayerId, mercId )
	self._availability = self._availability or {}
	self._availability[mercId] = self._availability[mercId] or {}
	self._availability[mercId][iPlayerId] = self._availability[mercId][iPlayerId] or { amount = 1, limit = 1, cooldown = 0 }
end

function CMercenaryController:HasMercenaryAvailable( iPlayerId, mercId )
	self:VerifyAvailabilityData( iPlayerId, mercId )
	return self._availability[mercId][iPlayerId].amount > 0
end

function CMercenaryController:IsMercenaryOnCooldown( iPlayerId, mercId )
	self:VerifyAvailabilityData( iPlayerId, mercId )
	return self._availability[mercId][iPlayerId].cooldown > 0
end

function CMercenaryController:ConsumeMercenary( iPlayerId, mercId )

	self:VerifyAvailabilityData( iPlayerId, mercId )

	local merc_data = self._availability[mercId][iPlayerId]

	-- Reduce amount
	merc_data.amount = merc_data.amount - 1

	local cooldown_time = self:GetMercenaryData(mercId).cooldown
	if cooldown_time > 0 then

		-- Put on cooldown
		if merc_data.cooldown < 0 then
			merc_data.cooldown = cooldown_time
		end

	else

		-- No cooldown, increase amount immediately
		merc_data.amount = merc_data.amount + 1

	end

end

function CMercenaryController:BuildWavesMercenaryLaneSpawns()
	self:DivideMercenariesIntoLanes( DOTA_TEAM_GOODGUYS )
	self:DivideMercenariesIntoLanes( DOTA_TEAM_BADGUYS )
end

function CMercenaryController:DivideMercenariesIntoLanes( iTeamId, bDebug )

	local laneController = GameRules.LegionDefence:GetLaneController()

	-- Process team
	local lanes = laneController:GetOccupiedLanesForTeam( iTeamId )
	local enemyTeam = GetEnemyTeam( iTeamId )

	-- Advance lane to use for the short straw lane
	self._short_straw_lanes = self._short_straw_lanes or {}
	if self._short_straw_lanes[iTeamId] == nil then

		-- No lane exists, use a random lane
		self._short_straw_lanes[iTeamId] = lanes[ math.random(#lanes) ]

	else

		-- Advance lane
		self._short_straw_lanes[iTeamId] = self._short_straw_lanes[iTeamId] + 1
		if self._short_straw_lanes[iTeamId] > #lanes then
			self._short_straw_lanes[iTeamId] = 1
		end

	end

	-- Find units to spawn for this team
	local units = {}
	for k, v in pairs( self._spawned ) do
		if v.team == enemyTeam then
			table.insert( units, v )
		end
	end

	-- Sort units by value
	table.sort( units, function(a, b)
		return a.value > b.value
	end )

	-- Setup lanes
	self._lane_spawns = self._lane_spawns or {}
	local laneSpawns = self._lane_spawns
	for k, v in pairs( lanes ) do
		laneSpawns[v] = {
			units = {},
			total_value = 0
		}
	end

	-- If no lanes exist (no enemy players), then destroy the units
	if #lanes == 0 then

		if bDebug then
			print("No occupied lanes exist for team " .. tostring(iTeamId))
		end

		self._remove_units = self._remove_units or {}
		for k, v in pairs( units ) do
			table.insert( self._remove_units, v )
		end

		self._lane_spawns = self._lane_spawns or {}

		return

	end

	-- Divide units among all possible lanes
	-- Use a rotating "short straw lane" which receives the highest value units first
	local shortStrawLaneIndex = self._short_straw_lanes[iTeamId]
	local laneIndex = self._short_straw_lanes[iTeamId]
	local currentLane = lanes[laneIndex]
	local highestValue = nil
	local iterations = 0
	local max_iterations = #units * #lanes

	while (#units > 0) do

		-- Is this lane allowed to spawn more units
		if bDebug then
			print(string.format("Assigning %s (%i), %s < %s", units[1].id, units[1].value, tostring(laneSpawns[currentLane].total_value), tostring(highestValue)))
		end
		if highestValue == nil or laneSpawns[currentLane].total_value < highestValue then

			if bDebug then
				print("\tAssigned to lane " .. tostring(currentLane))
			end

			-- Increase lane value and add to spawns for that lane
			laneSpawns[currentLane].total_value = laneSpawns[currentLane].total_value + units[1].value
			table.insert( laneSpawns[currentLane].units, units[1] )

			-- Remove the unit from the spawn queue
			table.remove( units, 1 )

			-- Check highest value
			if highestValue == nil or laneSpawns[currentLane].total_value > highestValue then
				highestValue = laneSpawns[currentLane].total_value
			end

		end

		-- Advance lane and wrap if neccessary
		laneIndex = laneIndex + 1
		if laneIndex > #lanes then
			laneIndex = 1
		end
		currentLane = lanes[laneIndex]

		-- Check if all lanes have the same value, and decrease the short straw lane value if they do
		local allLanesEqual = true
		local lanesValue = nil
		for k, v in pairs( laneSpawns ) do
			if lanesValue == nil then
				lanesValue = v.total_value
			else
				if v.total_value ~= lanesValue then
					allLanesEqual = false
					break
				end
			end
		end
		if allLanesEqual then
			laneSpawns[shortStrawLaneIndex].total_value = laneSpawns[shortStrawLaneIndex].total_value - 1
		end

		-- Prevent an infinite loop by limiting the times we can attempt to assign spawns, just in case
		iterations = iterations + 1
		if iterations > max_iterations then
			print("[ERROR] Exceeded maximum iterations attempting to assign mercenaries to lanes!")
			break
		end

	end

	if bDebug then

		-- Print results
		for k, v in pairs( laneSpawns ) do
			print("Spawns for lane " .. tostring(k))
			for x, y in pairs( v.units ) do
				print(string.format("\t%s (%i)", tostring(y.id), y.value))
			end
			print("total value: " .. tostring(v.total_value))
			print("--------")
		end

	end

end

function CMercenaryController:GetMercenarySpawnsForWave( laneId )
	return self._lane_spawns[laneId]
end

function CMercenaryController.HandleOnMercenaryPurchased( iPlayerId_Wrong, eventArgs )

	local self = GameRules.LegionDefence:GetMercenaryController()
	local currency_controller = GameRules.LegionDefence:GetCurrencyController()

	local iPlayerId = eventArgs["PlayerID"]
	local sMercId = eventArgs["sMercenaryId"]
	local mercData = self:GetMercenaryData( sMercId )

	if iPlayerId ~= nil and mercData then

		-- Check if mercenary is available to spawn for this player
		if not self:HasMercenaryAvailable( iPlayerId, sMercId ) then
			return false, "none_available"
		end

		-- Check if player can afford mercenary
		if not currency_controller:CanAfford( CMercenaryController.PURCHASE_CURRENCY, iPlayerId, mercData.cost, true ) then
			return false, "could_not_afford"
		end

		-- Spawn mercenary in spawn zone for team
		local mapController = GameRules.LegionDefence:GetMapController()
		local hPlayer = PlayerResource:GetPlayer( iPlayerId )
		local teamId = hPlayer:GetTeamNumber()
		local mercSpawnZone = mapController:GetMercSpawnZoneForTeam( teamId ).entity
		local spawnPos = RandomVectorInTrigger( mercSpawnZone )
		local hUnit = CreateUnitByName( sMercId, spawnPos, true, nil, nil, teamId )

		-- Spawn effect
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf", PATTACH_WORLDORIGIN, hUnit )
		ParticleManager:SetParticleControl( nFXIndex, 0, hUnit:GetCenter() )
		ParticleManager:SetParticleControl( nFXIndex, 1, RandomVector(360) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

		-- Add mercenary to waiting list for team
		local spawn_data = {
			id = sMercId,
			player_id = iPlayerId,
			team = teamId,
			unit = hUnit,
			value = mercData.cost
		}
		table.insert( self._spawned, spawn_data )

		-- Consume mercenary
		self:ConsumeMercenary( iPlayerId, sMercId )

		-- Consume unit cost
		currency_controller:ModifyCurrency( CMercenaryController.PURCHASE_CURRENCY, iPlayerId, -mercData.cost )

		-- Give unit income to player
		currency_controller:SetCurrencyIncome( CMercenaryController.PURCHASE_CURRENCY, iPlayerId, mercData.income, true )

	end

end

function CMercenaryController:HandleOnPerformWaveSpawn()

	-- Decrease spawn delay
	if self._wave_spawn_delay == nil then
		self._wave_spawn_delay = CMercenaryController.SPAWN_DELAY
	end
	self._wave_spawn_delay = self._wave_spawn_delay - 1
	if self._wave_spawn_delay < 0 then
		self._wave_spawn_delay = -1
	end

	-- Don't spawn mercenaries yet
	if self._wave_spawn_delay > 0 then
		return
	end

	self._map_controller = self._map_controller or GameRules.LegionDefence:GetMapController()
	self._wave_controller = self._wave_controller or GameRules.LegionDefence:GetWaveController()

	-- Build spawns list
	if not self._lane_spawns then
		self:BuildWavesMercenaryLaneSpawns()
	end

	-- Spawn mercenary unit
	for k, v in pairs( self._lane_spawns ) do

		local spawnZone = self._map_controller:GetSpawnZoneForLane( k )
		local unit = v.units[1] and v.units[1].unit

		-- Moved unit to spawn zone
		if unit and spawnZone then

			local vPosition = RandomVectorInTrigger( spawnZone.entity )
			local entTargetZone = self._map_controller:GetTargetZoneForTeam( spawnZone.team ).entity
			local vTarget = RandomVectorInTrigger( entTargetZone )
			local hKing = GameRules.LegionDefence:GetKingController():GetKingForTeam( spawnZone.team )

			unit:SetOrigin( vPosition )
			self._wave_controller:AddSpawnedUnit( hUnit, k, vTarget, hKing )

		end

		-- Remove unit from queue
		if v.units[1] then
			table.remove(v.units, 1)
		end

	end

	-- Remove all units with no enemy to attack
	if self._remove_units then
		while (#self._remove_units > 0) do
			local unit_data = self._remove_units[1]
			if unit_data.unit then
				UTIL_Remove(unit_data.unit)
			end
			table.remove( self._remove_units, 1 )
		end
	end

end

function CMercenaryController:HandleOnWaveCompleted()

	-- Reset spawn delay
	self._wave_spawn_delay = CMercenaryController.SPAWN_DELAY

	-- Clear lane spawns
	self._lane_spawns = nil

end
