
if CLaneController == nil then
	CLaneController = class({})
end

function CLegionDefence:SetupLaneController()
	self.lane_controller = CLaneController()
	self.lane_controller:Setup()
end

function CLegionDefence:GetLaneController()
	return self.lane_controller
end

function CLaneController:Setup()

	self.lanes = {}

	-- Game events
	ListenToGameEvent("dota_player_pick_hero", Dynamic_Wrap(CLaneController, "OnPlayerPickedHero"), self)

end

function CLaneController:RegisterLane( laneId, iTeam )

	if not self.lanes[laneId] then

		self.lanes[laneId] = {
			team = iTeam,
			player = nil
		}

		print(string.format("Registered lane '%s' to team %i", tostring(laneId), iTeam))

	end

end

function CLaneController:GetLaneForPlayer( iPlayerId )

	for id, lane in pairs(self.lanes) do
		if lane.player == iPlayerId then
			return id
		end
	end
	return nil

end

function CLaneController:GetPlayerForLane( laneId )

	for id, lane in pairs(self.lanes) do
		if id == laneId then
			return lane.player
		end
	end
	return nil

end

function CLaneController:OnPlayerPickedHero( event )

	local hero = EntIndexToHScript( event.heroindex )
	if hero then

		-- Get info
		local playerId = hero:GetOwner():GetPlayerID()
		local playerTeamId = hero:GetOwner():GetTeam()

		-- Find first available lane and assign player
		for id, lane in pairs(self.lanes) do
			if lane.player == nil and lane.team == playerTeamId then
				lane.player = playerId
				print(string.format("%i player assigned to lane %i", playerId, id))

				local data = {
					["lPlayer"] = playerId,
					["lLane"] = id,
				}
				FireGameEvent( "legion_player_assigned_lane", data )

				break
			end
		end

	end

end

function CLaneController:GetSpawnZonesForOccupiedLanes()

	-- Get map controller
	self._map_controller = self._map_controller or GameRules.LegionDefence:GetMapController()

	-- Find all spawn zones that have a player playing in their lane
	local spawns = {}

	for k, spawn in pairs(self._map_controller:SpawnZones()) do
		if self:GetPlayerForLane(spawn.lane) then
			table.insert( spawns, spawn )
		end
	end

	return spawns

end
