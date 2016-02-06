
function DamageBlockOnTakeDamage( keys )

	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local damage_taken = keys.DamageTaken
	local damage_blocked = ability:GetLevelSpecialValueFor("DamageBlocked", ability_level)
	local target_health = caster:GetHealth()

	if damage_taken < damage_blocked then
		target_health = target_health + damage_taken
	else
		target_health = target_health + damage_blocked
	end

	caster:ModifyHealth( target_health, ability, false, 0 )

end
