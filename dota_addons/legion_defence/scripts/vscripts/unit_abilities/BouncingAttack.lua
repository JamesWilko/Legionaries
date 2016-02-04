
-- Based off of Luna's moon glaive script by jacklarnes
-- https://github.com/Pizzalol/SpellLibrary/blob/master/game/scripts/vscripts/heroes/hero_luna/moon_glaive.lua

Particles = {
	["default"] = {
		particle = "particles/units/heroes/hero_luna/luna_base_attack.vpcf",
		speed = 900
	}
}

function FindProjectileInfo(class_name)

	if Particles[class_name] ~= nil then
		return Particles[class_name].particle, Particles[class_name].speed
	end

	local kv_units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	local kv_unit = kv_units[class_name]

	if kv_unit and kv_unit["ProjectileModel"] ~= nil and kv_unit["ProjectileModel"] ~= "" then

		Particles[class_name] = {
			particle = kv_unit["ProjectileModel"],
			speed = kv_unit["ProjectileSpeed"]
		}

	else

		Particles[class_name] = {
			particle = kv_unit["default"],
			speed = kv_unit["default"]
		}

	end

	return Particles[class_name].particle, Particles[class_name].speed

end

function BounceAttackStart( keys )

	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Create the dummy unit which keeps track of bounces
	local bounce_ability_name = ability:GetName() .. "_bounce"
	local dummy = CreateUnitByName( "npc_dummy_unit", target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber() )
	dummy:AddAbility(bounce_ability_name)

	local dummy_ability =  dummy:FindAbilityByName(bounce_ability_name)
	dummy_ability:ApplyDataDrivenModifier( caster, dummy, "modifier_bouncing_attack_dummy_unit", {} )

	-- Ability variables
	dummy_ability.damage = caster:GetAverageTrueAttackDamage()
	dummy_ability.bounceTable = {}
	dummy_ability.bounceCount = 0
	dummy_ability.maxBounces = ability:GetLevelSpecialValueFor("bounces", ability_level)
	dummy_ability.bounceRange = ability:GetLevelSpecialValueFor("range", ability_level) 
	dummy_ability.dmgMultiplier = ability:GetLevelSpecialValueFor("DamageReduction", ability_level)
	dummy_ability.original_ability = ability
	dummy_ability.particle_name, dummy_ability.projectile_speed = FindProjectileInfo(caster:GetUnitName())
	dummy_ability.projectileFrom = target
	dummy_ability.projectileTo = nil

	-- Find the closest target that fits the search criteria
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local bounce_targets = FindUnitsInRadius( caster:GetTeamNumber(), dummy:GetAbsOrigin(), nil, dummy_ability.bounceRange, iTeam, iType, iFlag, FIND_CLOSEST, false )

	-- It has to be a target different from the current one
	for _, v in pairs(bounce_targets) do
		if v ~= target then
			dummy_ability.projectileTo = v
			break
		end
	end

	if dummy_ability.projectileTo == nil then

		-- If we didnt find a new target then kill the dummy and end the function
		KillDummy(dummy, dummy)

	else

		-- Otherwise continue with creating a bounce projectile
		dummy_ability.bounceCount = dummy_ability.bounceCount + 1
		local data = {
			Target = dummy_ability.projectileTo,
			Source = dummy_ability.projectileFrom,
			EffectName = dummy_ability.particle_name,
			Ability = dummy_ability,
			bDodgeable = false,
			bProvidesVision = false,
			iMoveSpeed = dummy_ability.projectile_speed,
			iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
		}
    	ProjectileManager:CreateTrackingProjectile( data )

    end

end

function BounceAttackPerformBounce( keys )

	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	-- Initialize the damage table
	local damage_data = {
		attacker = caster:GetOwner(),
		victim = target,
		ability = ability.original_ability,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		damage = ability.damage * (1 - ability.dmgMultiplier),
	}
	ApplyDamage(damage_data)

	-- Save the new damage for future bounces
	ability.damage = damage_data.damage

	if ability.bounceCount >= ability.maxBounces then

		-- If we exceeded the bounce limit then remove the dummy
		KillDummy( caster, caster )

	else

		-- Reset target data and find new targets
		ability.projectileFrom = ability.projectileTo
		ability.projectileTo = nil

		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local bounce_targets = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, ability.bounceRange, iTeam, iType, iFlag, FIND_CLOSEST, false)

		-- Find a new target that is not the current one
		for _, v in pairs(bounce_targets) do
			if v ~= target then
				ability.projectileTo = v
				break
			end
		end

		if ability.projectileTo == nil then

			-- If we didnt find a new target then kill the dummy
			KillDummy(caster, caster)

		else

			-- Otherwise increase the bounce count and create a new bounce projectile
			ability.bounceCount = ability.bounceCount + 1
			local data = {
				Target = ability.projectileTo,
				Source = ability.projectileFrom,
				EffectName = ability.particle_name,
				Ability = ability,
				bDodgeable = false,
				bProvidesVision = false,
				iMoveSpeed = ability.projectile_speed,
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
			}
			ProjectileManager:CreateTrackingProjectile( data )

		end

	end

end

function KillDummy(caster, target)

	if caster:GetClassname() == "npc_dota_base_additive" then
		caster:RemoveSelf()
	elseif target:GetClassname() == "npc_dota_base_additive" then
		target:RemoveSelf()
	end

end
