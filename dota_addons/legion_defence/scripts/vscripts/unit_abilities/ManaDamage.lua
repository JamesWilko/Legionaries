
function OnAttackLanded( keys )

	local ability = keys.ability
	local ability_level = ability:GetLevel() or 1
	local caster = keys.caster
	local damage = keys["Damage"]
	local mana_cost = ability:GetManaCost(ability_level)

	if ability:IsCooldownReady() and caster:GetMana() >= mana_cost then

		-- Deal damage
		local data = {
			attacker = caster,
			victim = keys.target,
			ability = ability,
			damage = damage,
			damage_type = ability:GetAbilityDamageType()
		}
		ApplyDamage( data )

		-- Mana cost
		caster:SpendMana( mana_cost, ability )

		-- Start ability cooldown
		local cooldown = ability:GetCooldown(ability_level)
		ability:StartCooldown(cooldown)

	end

end
