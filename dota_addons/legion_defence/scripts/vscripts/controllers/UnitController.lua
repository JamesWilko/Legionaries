
if CUnitController == nil then
	CUnitController = class({})
end

CUnitController.LEGION_UNITS_FILE 			= "scripts/npc/npc_units_custom.txt"
CUnitController.LEGION_ABILITIES_FILE 		= "scripts/npc/npc_abilities_custom.txt"
CUnitController.LEGION_NPC_UNIT 			= "npc_legion_"
CUnitController.LEGION_SPAWN_ABILITY 		= "spawn_"
CUnitController.LEGION_UPGRADE_ABILITY		= "upgrade_unit"
CUnitController.DEFAULT_GOLD_COST 			= 100

CUnitController.SELL_MULTIPLIER_SAME_WAVE 	= 1
CUnitController.SELL_MULTIPLIER_DIFF_WAVE 	= 0.5

CUnitController.CLEARED_WAVE_TELEPORT_INITIAL_DELAY = 2.0
CUnitController.CLEARED_WAVE_TELEPORT_DELAY = 0.1
CUnitController.CLEARED_WAVE_TELEPORT_MAX_TIME = 1.0

function CLegionDefence:SetupUnitController()
	self.unit_controller = CUnitController()
	self.unit_controller:Setup()
end

function CLegionDefence:GetUnitController()
	return self.unit_controller
end

function CUnitController:Setup()

	self._unit_types = self._unit_types or {}
	self._ability_costs = self._ability_costs or {}
	self._player_units = self._player_units or {}

	self:LoadUnitTypes()

	self._think_ent = IsValidEntity(self._think_ent) and self._think_ent or Entities:CreateByClassname("info_target")

	ListenToGameEvent("legion_wave_start", Dynamic_Wrap(CUnitController, "HandleOnWaveStart"), self)
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CUnitController, "HandleOnWaveComplete"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CUnitController, "HandleOnEntityKilled"), self)

end

---------------------------------------
-- Registering Unit Types
---------------------------------------
function CUnitController:LoadUnitTypes()

	-- Load custom units file and load data
	local units = LoadKeyValues( CUnitController.LEGION_UNITS_FILE )
	for unit_name, values in pairs( units ) do
		if string.lower(string.sub(unit_name, 1, #CUnitController.LEGION_NPC_UNIT)) == CUnitController.LEGION_NPC_UNIT then
			self:RegisterUnitType( unit_name, values )
		end
	end

end

function CUnitController:RegisterUnitType( sUnitType, tKeyValues )
	assert( sUnitType ~= nil, "Can not register a unit type, unless specifying a unit type name!" )
	local unit_data = {
		-- gold_cost = tKeyValues["GoldCost"] or CUnitController.DEFAULT_GOLD_COST,
	}
	self._unit_types[sUnitType] = unit_data
end

function CUnitController:GetUnitTypeData( sUnitType )
	return self._unit_types[sUnitType]
end

function CUnitController:GetUnitTypeGoldCost( sUnitType )
	return self._unit_types[sUnitType] and self._unit_types[sUnitType].gold_cost or CUnitController.DEFAULT_GOLD_COST
end

---------------------------------------
-- Registering Units for Players
---------------------------------------
function CUnitController:RegisterUnit( ePlayer, lTeam, eUnit )

	local lPlayer = ePlayer:GetPlayerID()
	self._player_units[lPlayer] = self._player_units[lPlayer] or {}

	local unit_id = DoUniqueString( eUnit:GetUnitName() )
	local unit_data = {
		id = unit_id,
		unit = eUnit,
		position = eUnit:GetOrigin(),
		class = eUnit:GetUnitName(),
		player = ePlayer,
		team = lTeam,
	}
	table.insert( self._player_units[lPlayer], unit_data )

	print(string.format("Regsitered unit: %s", unit_id))

	return unit_id

end

function CUnitController:UnregisterUnit( unit )

	for i, player in pairs( self._player_units ) do
		for k, v in pairs( player ) do

			if v.unit == unit then
				print(string.format("Unregistered unit: %s", v.id))
				self._player_units[i][k] = nil
				return true
			end

		end
	end

	Warning(string.format("Could not find unit to unregister: %s", unit_id))
	return false

end

function CUnitController:GetAllUnits()
	local t = {}
	for i, player in pairs( self._player_units ) do
		for k, v in pairs( player ) do
			table.insert(t, v.unit)
		end
	end
	return t
end

function CUnitController:GetAllUnitsForPlayer( iPlayerId )
	return self._player_units[iPlayerId]
end

function CUnitController:GetUnitData( tUnit )
	for i, player in pairs( self._player_units ) do
		for k, v in pairs( player ) do
			if v.unit == tUnit then
				return v
			end
		end
	end
end

---------------------------------------
-- Spawning Units
---------------------------------------
function CUnitController:SpawnUnit( ePlayer, lTeam, sUnitClass, vPosition, bRegisterUnit )

	if bRegisterUnit == nil then
		bRegisterUnit = true
	end

	local hUnit = CreateUnitByName( sUnitClass, vPosition, false, nil, ePlayer, lTeam )
	if hUnit ~= nil then

		hUnit:SetOwner( ePlayer )
		hUnit:SetControllableByPlayer( ePlayer:GetPlayerID(), true )
		hUnit:SetAngles( 0, 90, 0 )
		hUnit:SetMoveCapability( GameRules.LegionDefence:GetWaveController():IsWaveRunning() and DOTA_UNIT_CAP_MOVE_NONE or DOTA_UNIT_CAP_MOVE_GROUND )

		if bRegisterUnit then
			self:RegisterUnit( ePlayer, lTeam, hUnit )
		end

		return hUnit
		
	end

	return nil

end

---------------------------------------
-- Unit Costs
---------------------------------------
function CUnitController:AddCostToUnit( hUnit, sCurrency, lCost, hParentUnit )

	if self._wave_controller == nil then
		self._wave_controller = GameRules.LegionDefence:GetWaveController()
	end

	hUnit._total_costs = hUnit._total_costs or {}

	-- Transfer previous costs to new unit
	if hParentUnit ~= nil and hParentUnit._total_costs then
		for k, v in pairs( hParentUnit._total_costs ) do
			table.insert( hUnit._total_costs, v )
		end
		hParentUnit._total_costs = nil
	end

	-- Add cost and current wave to unit
	local cost = {
		wave = self._wave_controller:GetCurrentWave(),
		currency = sCurrency,
		cost = lCost,
	}
	table.insert( hUnit._total_costs, cost )

end

function CUnitController:GetTotalCostOfUnit( hUnit, sCurrency )

	-- Use gold as the currency if not specified
	sCurrency = sCurrency or CURRENCY_GOLD

	-- Add up costs
	local cost = 0
	for k, v in pairs( hUnit._total_costs ) do
		if v.currency == sCurrency then
			cost = cost + v.cost
		end
	end
	return cost

end

function CUnitController:GetCurrentSellCostOfUnit( hUnit, sCurrency )

	if self._wave_controller == nil then
		self._wave_controller = GameRules.LegionDefence:GetWaveController()
	end

	-- Use gold as the currency if not specified
	sCurrency = sCurrency or CURRENCY_GOLD

	-- Add up costs, use wave multiplier if not the same wave as the cost was added to the unit
	local cost = 0
	for k, v in pairs( hUnit._total_costs ) do
		if v.currency == sCurrency then
			local multi = self._wave_controller:GetCurrentWave() == v.wave and CUnitController.SELL_MULTIPLIER_SAME_WAVE or CUnitController.SELL_MULTIPLIER_DIFF_WAVE
			cost = cost + math.floor(v.cost * multi)
		end
	end
	return cost

end

---------------------------------------
-- Wave Control Handles
---------------------------------------
function CUnitController:HandleOnWaveStart( event )

	if IsServer() then

		-- Unfreeze all units and allow them to move around the play field
		for i, player in pairs( self._player_units ) do
			for k, v in pairs( player ) do

				if IsValidEntity(v.unit) and v.unit:IsAlive() then
					v.unit:SetMoveCapability( DOTA_UNIT_CAP_MOVE_GROUND )
				end

			end
		end

	end

end

function CUnitController:HandleOnWaveComplete( event )

	if IsServer() then

		-- Freeze all units again and respawn dead units
		for i, player in pairs( self._player_units ) do

			local killed_unit_index = 0

			for k, v in pairs( player ) do

				if IsValidEntity(v.unit) and v.unit:IsAlive() then

					-- Unit is alive, so freeze it, and reset position and rotation
					v.unit:SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
					v.unit:SetHealth( v.unit:GetMaxHealth() )
					v.unit:SetOrigin( v.position )
					v.unit:SetAngles( 0, 90, 0 )

				else

					-- Unit is dead, so spawn a new unit and update references
					local hUnit = self:SpawnUnit( v.player, v.team, v.class, v.position )
					if hUnit then

						hUnit._total_costs = v.cost_data
						self._player_units[i][k].unit = hUnit
						self._player_units[i][k].cost_data = nil

					else
						Warning(string.format("Attempted to respawn unit, but failed! (%s)", v.id))
					end

				end

			end
		end

		self._killed_units = {}

	end

end

function CUnitController:HandleOnEntityKilled( event )
	
	local hUnit = EntIndexToHScript( event.entindex_killed )
	if hUnit and hUnit._total_costs then

		for i, player in pairs( self._player_units ) do
			for k, v in pairs( player ) do

				if v.unit == hUnit then
					v.cost_data = hUnit._total_costs
				end

			end
		end

	end

end

---------------------------------------
-- Lane Wave Clear Handles
---------------------------------------
function CUnitController:OnLaneCleared( laneId, iPlayerId )

	local hPlayer = PlayerResource:GetPlayer( iPlayerId )
	local fallbackZone = GameRules.LegionDefence:GetMapController():GetFallbackZoneForTeam( hPlayer:GetTeam() )

	-- Give all units teleport delays and positions
	for k, v in pairs( self:GetAllUnitsForPlayer(iPlayerId) ) do
		if IsValidEntity(v.unit) and v.unit:IsAlive() then

			local teleportPos = RandomVectorInTrigger(fallbackZone)
			teleportPos = GetGroundPosition(teleportPos, v.unit)

			v.teleport_pos = teleportPos
			v.teleport_delay = math.random() * CUnitController.CLEARED_WAVE_TELEPORT_MAX_TIME

		end
	end

	-- Start teleporting units after a delay
	self._think_ent:SetThink("LaneClearedTeleportUnits", self, "WaveControllerThink", CUnitController.CLEARED_WAVE_TELEPORT_INITIAL_DELAY)

end

function CUnitController:LaneClearedTeleportUnits()

	local canStopTimer = true

	-- Iterate througha all units and check if they need teleporting
	for i, player in pairs( self._player_units ) do
		for k, v in pairs( player ) do
			if IsValidEntity(v.unit) and v.unit:IsAlive() and v.teleport_delay ~= nil then

				if v.teleport_delay <= 0 then

					local nFXIndex = nil

					-- Show particles at unit position
					nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_relocate_teleport_c.vpcf", PATTACH_WORLDORIGIN, v.unit )
					ParticleManager:SetParticleControl( nFXIndex, 0, v.unit:GetOrigin() )
					ParticleManager:ReleaseParticleIndex( nFXIndex )

					-- Show particles at destination
					nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_relocate_teleport.vpcf", PATTACH_WORLDORIGIN, v.unit )
					ParticleManager:SetParticleControl( nFXIndex, 0, v.teleport_pos )
					ParticleManager:SetParticleControl( nFXIndex, 1, RandomVector(360) )
					ParticleManager:ReleaseParticleIndex( nFXIndex )

					-- Play sounds
					EmitSoundOnLocationWithCaster( v.unit:GetOrigin(), "Hero_Wisp.Tether.Target", v.unit )
					EmitSoundOnLocationWithCaster( v.teleport_pos, "Hero_Wisp.Tether.Target", v.unit )

					-- Teleport unit
					v.unit:SetOrigin( v.teleport_pos )
					v.teleport_delay = nil
					v.teleport_pos = nil

				else
					v.teleport_delay = v.teleport_delay - CUnitController.CLEARED_WAVE_TELEPORT_DELAY
					canStopTimer = false
				end

			end
		end
	end

	-- Refresh timer if units still need to be teleported
	if not canStopTimer then
		return CUnitController.CLEARED_WAVE_TELEPORT_DELAY
	else
		return nil
	end

end
