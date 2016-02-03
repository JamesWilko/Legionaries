
function ManaBoostedDamageOnAttackLanded( keys )

	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local mana_per_damage = ability:GetLevelSpecialValueFor("ManaPerDamage", ability_level )
	if caster:GetMana() >= mana_per_damage then

		local bonus_damage = caster:GetMana() / mana_per_damage
		local data = {
			attacker = caster,
			victim = target,
			damage = bonus_damage,
			damage_type = ability:GetAbilityDamageType()
		}
		ApplyDamage( data )

	end

end
