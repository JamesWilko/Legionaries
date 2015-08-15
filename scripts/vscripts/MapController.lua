
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
	}

	self:FindSpawnZones()
	self:FindBuildZones()
	self:FindTargetZones()

end

-------------------------
-- Utils
-------------------------
function CMapController:_StoreGamemodeEntitiesOfClass( dest_table, class_type, class_name )

	for k, ent in pairs( Entities:FindAllByClassname( class_type ) ) do

		local name = string.sub( ent:GetName(), 1, #class_name )
		if name == class_name then

			local team = string.split(ent:GetName(), "_")
			team = tonumber(team[#team])
			if team and type(team) == "number" then 
				
				local data = {
					entity = ent,
					team = team
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

-------------------------
-- Spawn Zones
-------------------------
function CMapController:FindSpawnZones()
	self._spawn_zones = {}
	self:_StoreGamemodeEntitiesOfClass( self._spawn_zones, self._map_entities.spawn_zone.class, self._map_entities.spawn_zone.name )
end

function CMapController:SpawnZones()
	return self._spawn_zones
end

function CMapController:GetSpawnZoneForTeam( iTeam )
	return self:_GetTeamEntity( self._spawn_zones, iTeam )
end

-------------------------
-- Build Zones
-------------------------
function CMapController:FindBuildZones()
	self._build_zones = {}
	self:_StoreGamemodeEntitiesOfClass( self._build_zones, self._map_entities.build_zone.class, self._map_entities.build_zone.name )
end

function CMapController:BuildZones()
	return self._build_zones
end

function CMapController:GetBuildZoneForTeam( iTeam )
	return self:_GetTeamEntity( self._build_zones, iTeam )
end

-------------------------
-- Target Points
-------------------------
function CMapController:FindTargetZones()
	self._target_zones = {}
	self:_StoreGamemodeEntitiesOfClass( self._target_zones, self._map_entities.target_zone.class, self._map_entities.target_zone.name )
end

function CMapController:TargetZones()
	return self._target_zones
end

function CMapController:GetTargetZoneForTeam( iTeam )
	return self:_GetTeamEntity( self._target_zones, iTeam )
end
