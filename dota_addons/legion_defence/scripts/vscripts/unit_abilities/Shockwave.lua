
function ShockwaveOnSpellStart( keys )

	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local projectileName = keys["Projectile"]
	local projectileDirection = caster:GetForwardVector()
	local projectileSpeed = ability:GetLevelSpecialValueFor( "Speed", ability_level )
	local projectileDistance = ability:GetLevelSpecialValueFor( "Range", ability_level )
	local projectileRadius = ability:GetLevelSpecialValueFor( "Radius", ability_level )

	local projectileDamage = ability:GetLevelSpecialValueFor( "Damage", ability_level )
	caster._shockwave_damage = projectileDamage

	local projectileTable = {
		EffectName = projectileName,
		Ability = ability,
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = projectileDirection * projectileSpeed,
		fDistance = projectileDistance,
		fStartRadius = projectileRadius,
		fEndRadius = projectileRadius,
		Source = caster,
		bHasFrontalCone = false,
		bReplaceExisting = true,
		iUnitTargetTeam = ability:GetAbilityTargetTeam(),
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = ability:GetAbilityTargetType()
	}
	ProjectileManager:CreateLinearProjectile( projectileTable )

end

function ShockwaveOnProjectileHitUnit( keys )

	local caster = keys.caster
	local ability = keys.ability
	local data = {
		attacker = caster,
		victim = keys.target,
		ability = ability,
		damage_type = ability:GetAbilityDamageType(),
		damage = caster._shockwave_damage or 0,
	}
	ApplyDamage(data)

end
