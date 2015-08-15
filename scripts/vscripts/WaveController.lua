
if CWaveController == nil then
	CWaveController = class({})
end

function CLegionDefence:SetupWaveController()
	self.wave_controller = CWaveController()
	self.wave_controller:Setup()
end

function CLegionDefence:GetWaveController()
	return self.wave_controller
end

function CWaveController:Setup()

	self._waves_list = LoadKeyValues("scripts/kv/legion_waves.txt")

	self._current_wave = 0
	self._wave_in_progress = false

	self._think_time = 1
	self._think_ent = IsValidEntity(self._think_ent) and self._think_ent or Entities:CreateByClassname("info_target")
	self._think_ent:SetThink("OnThink", self, "WaveControllerThink", self._think_time)

	ListenToGameEvent("entity_killed", Dynamic_Wrap(CWaveController, "OnUnitKilled"), self)

end

function CWaveController:OnThink()
	
	-- Start spawning waves at 15s
	if not self:IsWaveRunning() then
		local time = GameRules:GetDOTATime(false, false)
		if time > 15 then
			self:StartNextWave()
		end
	end

	self._map_controller = self._map_controller or GameRules.LegionDefence:GetMapController()
	self._spawned_units = self._spawned_units or {}

	-- Spawn a unit at every spawn point every think
	if self:IsWaveRunning() and self:CurrentWaveHasSpawnsRemaining() then

		for k, spawn in pairs( self._map_controller:SpawnZones() ) do

			local ent = spawn.entity
			local vPosition = RandomVectorInTrigger( ent )
			local unit = self:GetAndPopNextSpawnInWave()
			if unit then

				local hUnit = CreateUnitByName( unit, vPosition, true, nil, nil, DOTA_TEAM_BADGUYS )
				local entTargetZone = self._map_controller:GetTargetZoneForTeam( spawn.team )
				local vTarget = RandomVectorInTrigger( entTargetZone )

				if hUnit ~= nil then
					hUnit:SetAngles( 0, -90, 0 )

					self._spawned_units[spawn.team] = self._spawned_units[spawn.team] or {}
					table.insert( self._spawned_units[spawn.team], { unit = hUnit, target = vTarget } )

				end

			end

		end

	end

	-- Move spawned units to the target zone
	for i, team in pairs( self._spawned_units ) do
		for k, v in pairs( team ) do
			if v and IsValidEntity(v.unit) then
				v.unit:MoveToPositionAggressive( v.target )
			else
				self._spawned_units[i][k] = nil
			end
		end
	end

	-- Think again
	return self._think_time
end

function CWaveController:IsWaveRunning()
	return self._wave_in_progress
end

function CWaveController:StartWave( iWave )

	self._current_wave = iWave
	if self:GetWave() then

		self._wave_in_progress = true

		self._wave_spawns_remaining = table.copy(self:GetWave())

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
			print(string.format("\t%s x%i", k, v))
		end
		print("-----")

	else
		print(string.format("Wave %i not found.", iWave))
	end

end

function CWaveController:OnUnitKilled( event )

	local unit = EntIndexToHScript(event.entindex_killed)
	for i, team in pairs( self._spawned_units ) do
		for k, v in pairs( team ) do
			if IsValidEntity(v.unit) and v.unit == unit then
				
				local remain = self:GetRemainingUnitsInCurrentWave()
				if remain <= 0 then
					self:WaveCompleted()
				end

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
	for i, team in pairs( self._spawned_units ) do
		for k, v in pairs( team ) do
			if IsValidEntity(v.unit) and v.unit:IsAlive() then
				remaining = remaining + 1
			end
		end
	end

	return remaining

end

function CWaveController:WaveCompleted()

	print(string.format("Completed Wave %i", self._current_wave))

	-- Send wave data to all players
	local data = {
		["nWaveNumber"] = self._current_wave,
		["sEnemyName"] = nil,
		["nTotalEnemies"] = nil,
		["nEnemiesKilled"] = nil,
		["nEnemiesLeaked"] = nil,
		["lFastestPlayer"] = nil,
	}
	FireGameEvent( "legion_wave_complete", data )

	-- Wave no longer in progress
	self._wave_in_progress = false

end
