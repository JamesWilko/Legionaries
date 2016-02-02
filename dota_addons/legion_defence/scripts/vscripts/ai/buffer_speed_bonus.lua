
local THINK_DELAY = 1
local BONUS_KV = "speed_bonus"

local abilities = {}

function Spawn( entityKeyValues )

	-- Get unit abilities
	abilities = GetUnitUniqueAbilities(thisEntity)

	-- Start thinking
	thisEntity:SetContextThink( "UnitThink", UnitThink , THINK_DELAY )
	print(string.format("Starting buffer (speed bonus) unit AI for %s (%i) ", thisEntity:GetUnitName(), thisEntity:GetEntityIndex()))

end

function UnitThink()

	if thisEntity:IsAlive() then

		local ability = FindAbilityThatHasSpecialValue( abilities, BONUS_KV )
		if ability then

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
			local unit = units[math.random(#units)]
			thisEntity:CastAbilityOnTarget( unit, ability, -1 )

		end

	end

	return THINK_DELAY

end
