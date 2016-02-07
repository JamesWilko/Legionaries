
local BONUS_KV = "SpeedPercentFriendly"

function Spawn( entityKeyValues )

	thisEntity.__ai = require("ai/UnitAI")
	ai = thisEntity.__ai
	ai:Spawn( "Buffer (Speed Bonus)", thisEntity )
	ai:SetThinkFunction( PerformAIThink )

end

function PerformAIThink( self )

	local ability, key_value = self:FindAbilityWithKey( BONUS_KV )
	if ability and thisEntity:IsAlive() then

		-- Get all friendly units in the cast range
		local cast_range = ability:GetCastRange( thisEntity:GetOrigin(), thisEntity )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(),
										thisEntity:GetAbsOrigin(),
										nil,
										cast_range,
										DOTA_UNIT_TARGET_TEAM_FRIENDLY,
										DOTA_UNIT_TARGET_ALL,
										DOTA_UNIT_TARGET_FLAG_NONE,
										FIND_ANY_ORDER,
										false)

		-- Cast buff on random unit
		-- TODO: Cast buff on unit that will deal most DPS with boosted speed
		local unit = units[math.random(#units)]
		thisEntity:CastAbilityOnTarget( unit, ability, -1 )

	end

end
