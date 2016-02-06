
function PerformSplitShotActive( keys )

	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local mana_cost = ability:GetManaCost(ability_level)

	if caster:GetMana() >= mana_cost and ability:IsCooldownReady() then
		caster:SpendMana( mana_cost, ability )
		PerformSplitShot( keys )
	end

end

function PerformSplitShot( keys )

	-- Get variables
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local ability = keys.ability

	local maxShots = ability:GetSpecialValueFor("shots")
	local projectileSpeed = ability:GetSpecialValueFor("projectile_speed")
	local lifetime = 10

	-- Find targets around caster
	local targets = FindUnitsInRadius(
		caster:GetTeam(),
		casterPos,
		nil,
		ability:GetSpecialValueFor("range"),
		ability:GetAbilityTargetTeam(),
		ability:GetAbilityTargetType(),
		ability:GetAbilityTargetFlags(),
		FIND_CLOSEST,
		false
	)

	-- Create projectiles
	local currentShots = 0
	for k, v in pairs(targets) do

		if v ~= caster:GetAttackTarget() then

			local data = {
				EffectName = keys.projectile,
				Ability = ability,
				vSpawnOrigin = casterPos,
				Target = v,
				Source = caster,
				bHasFrontalCone = false,
				iMoveSpeed = projectileSpeed,
				bReplaceExisting = false,
				bProvidesVision = false,
				flExpireTime = GameRules:GetGameTime() + lifetime
			}
			ProjectileManager:CreateTrackingProjectile(data)

			currentShots = currentShots + 1
			if currentShots >= maxShots then
				break
			end

		end
		
	end

end

function ApplySplitShotDamage( keys )

	local data = {
		attacker = keys.caster,
		victim = keys.target,
		damage = keys.caster:GetAttackDamage() * keys.ability:GetSpecialValueFor("DamagePercent"),
		damage_type = keys.ability:GetAbilityDamageType(),
	}
	ApplyDamage(data)
	
end
