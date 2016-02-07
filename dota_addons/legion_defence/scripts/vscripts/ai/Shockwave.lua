
local RADIUS_KV = "Radius"
local RANGE_KV = "Range"
local ai

function Spawn( entityKeyValues )

	thisEntity.__ai = require("ai/UnitAI")
	ai = thisEntity.__ai
	ai:Spawn( "Shockwave", thisEntity )
	ai:SetThinkFunction( PerformAIThink )

end

function PerformAIThink( self )

	local ability, key_value = self:FindAbilityWithKey( RADIUS_KV )
	if ability and thisEntity:IsAlive() then

		-- Get all enemy units in the cast range
		local cast_range = ability:GetCastRange( thisEntity:GetOrigin(), thisEntity )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(),
										thisEntity:GetAbsOrigin(),
										nil,
										cast_range,
										DOTA_UNIT_TARGET_TEAM_ENEMY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE,
										FIND_ANY_ORDER,
										false)

		-- Find unit with highest DPS
		local unit = self:GetHighestDPSUnit( units )
		if unit then
			thisEntity:CastAbilityOnTarget( unit, ability, -1 )
		end

	end

end

