
if CMapController == nil then
	CMapController = class({})
end

function CLegionDefence:SetupMapController()
	self.map_controller = CMapController()
	self.map_controller:Setup()
end

function CLegionDefence:GetMapController()
	return self.map_controller
end

function CMapController:Setup()

	self._map_entities = {
		["spawn_zone"] = {
			class = "trigger_dota",
			name = "legion_spawn_zone"
		},
		["build_zone"] = {
			class = "trigger_dota",
			name = "legion_build_zone"
		},
		["target_zone"] = {
			class = "trigger_dota",
			name = "legion_target_zone"
		},
		["king_spawns"] = {
			class = "info_target",
			name = "legion_king_spawn"
		},
		["fallback_zone"] = {
			class = "trigger_dota",
			name = "legion_fallback_zone"
		},
	}

	self._team_ids = {
		[1] = DOTA_TEAM_GOODGUYS,
		[2] = DOTA_TEAM_BADGUYS,
	}

	self:FindSpawnZones()
	self:FindBuildZones()
	self:FindTargetZones()
	self:FindKingSpawns()
	self:FindFallbackZones()

end

-------------------------
-- Utils
-------------------------
function CMapController:_StoreGamemodeEntitiesOfClass( dest_table, class_table )

	for k, ent in pairs( Entities:FindAllByClassname( class_table.class ) ) do

		local name = string.sub( ent:GetName(), 1, #class_table.name )
		if name == class_table.name then

			-- Get team and lane info from name
			local teamlane = string.split(ent:GetName(), "_")
			teamlane = teamlane[#teamlane]

			local team = nil
			local lane = nil

			-- Check if team and lane info exist
			if string.find(teamlane, "#") then
				
				-- Exists, split info and use both
				teamlane = string.split(teamlane, "#")
				team = tonumber(teamlane[1])
				lane = tonumber(teamlane[2])

			else

				-- Lane info doesn't exist, use default lane
				team = tonumber(teamlane)
				lane = 0

			end

			if team and type(team) == "number" then 
				
				-- Find team ID
				local team_index = class_table.team_ids and class_table.team_ids[team]
				if team_index == nil then
					team_index = self._team_ids[team] or DOTA_TEAM_NEUTRALS
				end

				-- Register lane
				if lane and lane > 0 then
					GameRules.LegionDefence:GetLaneController():RegisterLane( lane, team_index )
				end

				-- Add entity
				local data = {
					entity = ent,
					team = team_index,
					lane = lane or 0,
				}
				table.insert( dest_table, data )

			end

		end

	end

end

function CMapController:_GetTeamEntity( tblData, iTeam )
	for k, v in ipairs( tblData ) do
		if v.team == iTeam then
			return v.entity
		end
	end
	return nil
end

function CMapController:_GetLaneEntity( tblData, laneId, iTeam )
	for k, v in ipairs( tblData ) do
		if v.lane == laneId then
			return v.entity
		end
	end
	return self:_GetTeamEntity( tblData, iTeam )
end

-------------------------
-- Spawn Zones
-------------------------
function CMapController:FindSpawnZones()
	self._spawn_zones = {}
	self:_StoreGamemodeEntitiesOfClass( self._spawn_zones, self._map_entities.spawn_zone )
end

function CMapController:SpawnZones()
	return self._spawn_zones
end

function CMapController:GetSpawnZoneForTeam( iTeam )
	return self:_GetTeamEntity( self._spawn_zones, iTeam )
end

function CMapController:GetSpawnZoneForLane( laneId, iTeam )
	return self:_GetLaneEntity( self._spawn_zones, laneId, iTeam )
end

-------------------------
-- Build Zones
-------------------------
function CMapController:FindBuildZones()
	self._build_zones = {}
	self:_StoreGamemodeEntitiesOfClass( self._build_zones, self._map_entities.build_zone )
end

function CMapController:BuildZones()
	return self._build_zones
end

function CMapController:GetBuildZoneForTeam( iTeam )
	return self:_GetTeamEntity( self._build_zones, iTeam )
end

function CMapController:GetBuildZoneForLane( laneId, iTeam )
	return self:_GetLaneEntity( self._build_zones, laneId, iTeam )
end

-------------------------
-- Target Points
-------------------------
function CMapController:FindTargetZones()
	self._target_zones = {}
	self:_StoreGamemodeEntitiesOfClass( self._target_zones, self._map_entities.target_zone )
end

function CMapController:TargetZones()
	return self._target_zones
end

function CMapController:GetTargetZoneForTeam( iTeam )
	return self:_GetTeamEntity( self._target_zones, iTeam )
end

function CMapController:GetTargetZoneForLane( laneId, iTeam )
	return self:_GetLaneEntity( self._target_zones, laneId, iTeam )
end

-------------------------
-- King Spawn Points
-------------------------
function CMapController:FindKingSpawns()
	self._king_spawns = {}
	self:_StoreGamemodeEntitiesOfClass( self._king_spawns, self._map_entities.king_spawns )
end

function CMapController:KingSpawns()
	return self._king_spawns
end

function CMapController:GetSpawnForKing( iTeam )
	return self:_GetTeamEntity( self._king_spawns, iTeam )
end

-------------------------
-- Fallback Zones
-------------------------
function CMapController:FindFallbackZones()
	self._fallback_zones = {}
	self:_StoreGamemodeEntitiesOfClass( self._fallback_zones, self._map_entities.fallback_zone )
end

function CMapController:FallbackZones()
	return self._fallback_zones
end

function CMapController:GetFallbackZoneForTeam( iTeam )
	return self:_GetTeamEntity( self._fallback_zones, iTeam )
end

function CMapController:GetFallbackZoneForLane( laneId, iTeam )
	return self:_GetLaneEntity( self._fallback_zones, laneId, iTeam )
end
