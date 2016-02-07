
local HEALTH_HEAL_THRESHOLD = 0.5
local HEAL_KV = "Heal"
local ai

function Spawn( entityKeyValues )

	thisEntity.__ai = require("ai/UnitAI")
	ai = thisEntity.__ai
	ai:Spawn( "Healer", thisEntity )
	ai:SetThinkFunction( PerformAIThink )

end

function PerformAIThink( self )

	local ability, heal_amount = self:FindAbilityWithKey(HEAL_KV)
	if ability and thisEntity:IsAlive() then

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
			if unit and AttemptHeal(unit, ability, heal_amount) then
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

function AttemptHeal( unit, healAbility, healAmount )

	if unit and not unit:IsNull() and unit:IsAlive() then

		local healthDiff = unit:GetMaxHealth() - unit:GetHealth()
		
		-- Can heal be fully used, is health missing more than the heal amount
		local belowHealAmount = (healthDiff or -1) >= (healAmount or 0)

		-- Some healing will be wasted, but unit can be fully healed
		local belowHealThreshold = unit:GetMaxHealth() * HEALTH_HEAL_THRESHOLD >= unit:GetHealth()

		if belowHealAmount or belowHealThreshold then
			thisEntity:CastAbilityOnTarget( unit, healAbility, -1 )
			return true
		end

	end

	return false

end
