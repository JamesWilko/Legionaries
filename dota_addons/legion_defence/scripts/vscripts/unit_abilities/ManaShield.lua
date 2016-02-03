
local MANA_SHIELD_PARTICLE = "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf"
local MANA_SHIELD_PROC_PARTICLE = "particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf"

function ManaShieldOnTakeDamage( keys )

	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Check how much damage should pierce the mana shield
	local damage_per_mana = ability:GetLevelSpecialValueFor( "DamagePerMana", ability_level )
	local damage_percent = ability:GetLevelSpecialValueFor( "MaxDamagePercentFriendly", ability_level )
	damage_percent = damage_percent * 0.01

	local absorbed_damage = keys.Damage * damage_percent
	local pierce_damage = keys.Damage - absorbed_damage

	-- Check if unit won't be killed by the pierce damage
	if caster:GetHealth() + pierce_damage > 0 then

		local mana = caster:GetMana()
		local mana_required = absorbed_damage / damage_per_mana
		if mana_required < 1 then
			mana_required = 1
		end
		local pre_damage_health = caster:GetHealth() + keys.Damage

		-- Heal unit
		if mana_required <= mana then

			caster:SpendMana( mana_required, ability )
			caster:SetHealth( pre_damage_health - pierce_damage )

		else

			local new_health = pre_damage_health - keys.Damage
			caster:SpendMana( mana_required, ability )
			caster:SetHealth( new_health )

		end

		-- Play shield absorb particles
		local particle = ParticleManager:CreateParticle(MANA_SHIELD_PROC_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 0, caster:GetOrigin())
		ParticleManager:SetParticleControl(particle, 1, Vector(mana_required, 0, 0))

	end

end
