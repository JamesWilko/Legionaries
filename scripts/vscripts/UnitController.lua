
if CUnitController == nil then
	CUnitController = class({})
end

function CLegionDefence:SetupUnitController()
	self.unit_controller = CUnitController()
	self.unit_controller:Setup()
end

function CLegionDefence:GetUnitController()
	return self.unit_controller
end

function CUnitController:Setup()

	self._player_units = self._player_units or {}

	ListenToGameEvent("legion_wave_start", Dynamic_Wrap(CUnitController, "HandleOnWaveStart"), self)
	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CUnitController, "HandleOnWaveComplete"), self)

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

---------------------------------------
-- Accessors
---------------------------------------
function CUnitController:GetAllUnits()
	local t = {}
	for i, player in pairs( self._player_units ) do
		for k, v in pairs( player ) do
			table.insert(t, v.unit)
		end
	end
	return t
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
		hUnit:SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )

		if bRegisterUnit then
			self:RegisterUnit( ePlayer, lTeam, hUnit )
		end

		return hUnit
	end

	return nil

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
