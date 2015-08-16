
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

	ListenToGameEvent("legion_wave_start", Dynamic_Wrap(CUnitController, "HandleOnWaveStart"), self)
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CUnitController, "HandleOnWaveComplete"), self)

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

function CUnitController:GetUnitTypeTotalGoldCost( sUnitType )
	if self._unit_types[sUnitType].total_cost == nil then



	end
	return self._unit_types[sUnitType].total_cost
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

function CUnitController:SwapUnit( old_unit, new_unit )

	for i, player in pairs( self._player_units ) do
		for k, v in pairs( player ) do

			if v.unit == old_unit then
				print(string.format("Swapping unit class from '%s' to '%s' for: %s", v.class, new_unit:GetUnitName(), v.id))
				v.unit = new_unit
				v.class = new_unit:GetUnitName()
				return v.id
			end

		end
	end

	Warning(string.format("Attempted to swap a unit which was not registered: %s", unit_id))
	return nil

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
-- Unit Gold Costs
---------------------------------------
function CUnitController:AddCostToUnit( hUnit, lCost, hParentUnit )

	if self._wave_controller == nil then
		self._wave_controller = GameRules.LegionDefence:GetWaveController()
	end

	-- Add cost and current wave to unit
	hUnit._total_gold_cost = hUnit._total_gold_cost or {}
	local cost = {
		wave = self._wave_controller:GetCurrentWave(),
		cost = lCost
	}
	table.insert( hUnit._total_gold_cost, cost )

	-- Transfer previous costs to new unit
	if hParentUnit ~= nil and hParentUnit._total_gold_cost then
		for k, v in pairs( hParentUnit._total_gold_cost ) do
			table.insert( hUnit._total_gold_cost, v )
		end
	end

end

function CUnitController:GetTotalCostOfUnit( hUnit )
	local cost = 0
	for k, v in pairs( hUnit._total_gold_cost ) do
		cost = cost + v.cost
	end
	return cost
end

function CUnitController:GetCurrentSellCostOfUnit( hUnit )

	if self._wave_controller == nil then
		self._wave_controller = GameRules.LegionDefence:GetWaveController()
	end

	local cost = 0
	for k, v in pairs( hUnit._total_gold_cost ) do
		local multi = self._wave_controller:GetCurrentWave() == v.wave and CUnitController.SELL_MULTIPLIER_SAME_WAVE or CUnitController.SELL_MULTIPLIER_DIFF_WAVE
		cost = cost + v.cost * multi
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
			for k, v in pairs( player ) do

				if IsValidEntity(v.unit) and v.unit:IsAlive() then

					-- Unit is alive, so freeze it, and reset position and rotation
					v.unit:SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
					v.unit:SetHealth( v.unit:GetMaxHealth() )
					v.unit:SetOrigin( v.position )
					v.unit:SetAngles( 0, 90, 0 )

				else

					-- Unit is dead, so spawn a new unit and update references
					local unit = self:SpawnUnit( v.player, v.team, v.class, v.position, true )
					if not unit then
						Warning(string.format("Attempted to respawn unit, but failed! (%s)", v.id))
					end
					self._player_units[i][k].unit = unit

				end

			end
		end

	end

end
