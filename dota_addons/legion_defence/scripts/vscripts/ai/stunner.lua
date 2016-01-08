
local THINK_DELAY = 1
local STUN_KV = "stun_duration"

local abilities = {}

function Spawn( entityKeyValues )

	-- Get unit abilities
	abilities = GetUnitUniqueAbilities(thisEntity)

	-- Start thinking
	thisEntity:SetContextThink( "UnitThink", UnitThink , THINK_DELAY )
	print(string.format("Starting stunner unit AI for %s (%i) ", thisEntity:GetUnitName(), thisEntity:GetEntityIndex()))

end

function UnitThink()

	if thisEntity:IsAlive() then

		-- Iterate through abilities to find a stun ability
		for k, ability in pairs(abilities) do

			-- Can ability be cast
			if ability:IsCooldownReady() then

				-- Check if ability can stun
				local stun_duration = ability:GetSpecialValueFor(STUN_KV)
				if stun_duration then

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
					local unit = GetHighestDPSUnit( units )
					thisEntity:CastAbilityOnTarget( unit, ability, -1 )

				end

			end

		end

	end

	return THINK_DELAY

end

function GetUnitAverageDamagePerSecond( unit )
	if unit then
		if unit:IsStunned() or unit:IsDisarmed() then
			return 0
		else
			return unit:GetAverageTrueAttackDamage() * unit:GetAttacksPerSecond()
		end
	end
	return -1
end

function GetHighestDPSUnit( units )
	
	if units then

		local highestDPS = -1
		local highestDPSUnit = nil

		for index, unit in pairs(units) do
			local dps = GetUnitAverageDamagePerSecond(unit)
			if dps > highestDPS then
				highestDPSUnit = unit
				highestDPS = dps
			end
		end

		return highestDPSUnit

	end
	
	return nil

end
