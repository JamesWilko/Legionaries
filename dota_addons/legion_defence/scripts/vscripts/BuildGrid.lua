
BuildGrid = class({})

BuildGrid._grid_size = 128
BuildGrid._grid_search_radius = 64

function BuildGrid:GetGridSize()
	return self._grid_size
end

function BuildGrid:GetGridSearchRadius()
	return self._grid_search_radius
end

function BuildGrid:GetBuildZoneName()
	return self._build_zone_name
end

function BuildGrid:RoundToGrid( val, offset )
	val = math.round(val / self._grid_size)  * self._grid_size
	if offset then
		val = val + self._grid_size / 2
	end
	return val
end

function BuildGrid:FloorToGrid( val )
	return val - val % self._grid_size
end

function BuildGrid:RoundPositionToGrid( vPosition )
	local x = self:RoundToGrid(vPosition.x)
	local y = self:RoundToGrid(vPosition.y)
	local z = self:RoundToGrid(vPosition.z)
	return Vector(x, y, z)
end
