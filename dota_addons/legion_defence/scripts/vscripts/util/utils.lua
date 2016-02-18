
local ENEMY_TEAMS = {
	[DOTA_TEAM_GOODGUYS] = DOTA_TEAM_BADGUYS,
	[DOTA_TEAM_BADGUYS] = DOTA_TEAM_GOODGUYS
}

function BroadcastCenterMessage( sMessage, fDuration )
	local centerMessage = {
		message = sMessage,
		duration = fDuration
	}
	FireGameEvent( "show_center_message", centerMessage )
end

function math.round(num, idp)
	local mult = 10 ^ (idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

function table.print( t, indent )
	print( "table.print( t, indent ): " )
	if type(t) ~= "table" then return end

	for k,v in pairs( t ) do
		if type( v ) == "table" then
			if ( v ~= t ) then
				print( indent .. tostring( k ) .. ":\n" .. indent .. "{" )
				table.print( v, indent .. "  " )
				print( indent .. "}" )
			end
		else
		print( indent .. tostring( k ) .. ":" .. tostring(v) )
		end
	end
end

function table.copy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else
		copy = orig
	end
	return copy
end

function table.deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table.deepcopy(orig_key)] = table.deepcopy(orig_value)
		end
		setmetatable(copy, table.deepcopy(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

function string.split(str, sep, limit)
	if not str then
		return false
	end
	if not sep or sep == "" then
		return false
	end

	limit = limit or math.huge
	if limit == 0 or limit == 1 then
		return {str}, 1
	end

	local r = {}
	local n, init = 0, 1

	while true do
		local s, e = string.find(str, sep, init, true)
		if not s then
			break
		end
		r[#r + 1] = string.sub(str, init, s - 1)
		init = e + 1
		n = n + 1
		if n == limit - 1 then
			break
		end
	end

	if init <= string.len(str) then
		r[#r + 1] = string.sub(str, init)
	else
		r[#r + 1] = ""
	end
	n = n + 1

	if limit < 0 then
		for i = n, n + limit + 1, -1 do
			r[i] = nil
		end
		n = n + limit
	end

	return r, n
end

function RandomVectorInTrigger( entTrigger )
	if entTrigger.GetBounds and entTrigger.GetCenter then
		local bounds = entTrigger:GetBounds()
		local x = RandomFloat(0, 2) * bounds.Maxs.x
		local y = RandomFloat(0, 2) * bounds.Maxs.y
		local z = RandomFloat(0, 2) * bounds.Maxs.z
		local vPosition = entTrigger:GetCenter() + bounds.Mins + Vector( x, y, z )
		return vPosition
	end
	return Vector(0, 0, 0)
end

function IsPositionInTrigger( entTrigger, vPosition )
	if entTrigger and entTrigger.GetBounds and entTrigger.GetCenter then
		local Mins = entTrigger:GetCenter() + entTrigger:GetBounds().Mins
		local Maxs = entTrigger:GetCenter() + entTrigger:GetBounds().Maxs
		local x = Mins.x <= vPosition.x and vPosition.x <= Maxs.x
		local y = Mins.y <= vPosition.y and vPosition.y <= Maxs.y
		local z = Mins.z <= vPosition.z and vPosition.z <= Maxs.z
		return x and y
	end
	return false
end

function GetEnemyTeam( iTeam )
	return ENEMY_TEAMS[iTeam]
end
