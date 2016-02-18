
local ai

local king_abilities = {
	["ability_king_shockwave"] = "PerformShockwave",
	["ability_king_aoe_bash"] = "PerformBash",
	["ability_king_immolation"] = false,
	["ability_king_corruption_attack"] = false,
	["ability_king_bouncing_attack"] = false
}
local abilityFunctions = {}

function Spawn( entityKeyValues )

	thisEntity.__ai = require("ai/UnitAI")
	ai = thisEntity.__ai
	ai:Spawn( "Stunner", thisEntity )
	ai:SetThinkFunction( PerformAIThink )

end

function PerformAIThink( self )

	local abilities = GetUnitUniqueAbilities( thisEntity )
	for k, ability in pairs( abilities ) do
		local ability_func = king_abilities[ability:GetName()]
		if ability_func then
			if ability:IsCooldownReady() then

				abilityFunctions[ability_func]( abilityFunctions, self, ability )

			end
		end
	end

end

function abilityFunctions:PerformShockwave( self, ability )

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

function abilityFunctions:PerformBash( self, ability )
	thisEntity:CastAbilityNoTarget( ability, -1 )	
end
