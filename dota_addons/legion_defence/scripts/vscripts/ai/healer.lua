
local THINK_DELAY = 1
local HEALTH_HEAL_THRESHOLD = 0.5
local HEAL_KV = "Heal"

local abilities = {}

function Spawn( entityKeyValues )

	-- Get unit abilities
	abilities = GetUnitUniqueAbilities(thisEntity)

	-- Start thinking
	thisEntity:SetContextThink( "UnitThink", UnitThink , THINK_DELAY )
	print(string.format("Starting healer unit AI for %s (%i) ", thisEntity:GetUnitName(), thisEntity:GetEntityIndex()))

end

function UnitThink()

	if thisEntity:IsAlive() then

		-- Iterate through abilities to find a heal ability
		for k, ability in pairs(abilities) do

			-- Can ability be cast
			if ability:IsCooldownReady() then

				-- Check if ability can heal
				local heal_amount = ability:GetSpecialValueFor(HEAL_KV)
				if heal_amount then

					-- Get all friendly units in the cast range and check if they need healing
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

					-- Prioritize healing other units first
					local performed_heal = false
					for index, unit in pairs(units) do
						if AttemptHeal(unit, ability, heal_amount) then
							performed_heal = true
							break
						end
					end

					-- If no other units were healed then check ourselves
					if not performed_heal then
						AttemptHeal(thisEntity, ability, heal_amount)
					end

				end

			end

		end

	end

	return THINK_DELAY

end

function AttemptHeal( unit, healAbility, healAmount )

	if unit and unit:IsAlive() then

		local healthDiff = unit:GetMaxHealth() - unit:GetHealth()

		-- Can heal be fully used, is health missing more than the heal amount
		local belowHealAmount = healthDiff >= healAmount

		-- Some healing will be wasted, but unit can be fully healed
		local belowHealThreshold = unit:GetMaxHealth() * HEALTH_HEAL_THRESHOLD >= unit:GetHealth()

		if belowHealAmount or belowHealThreshold then
			thisEntity:CastAbilityOnTarget( unit, healAbility, -1 )
			return true
		end

	end

	return false

end
