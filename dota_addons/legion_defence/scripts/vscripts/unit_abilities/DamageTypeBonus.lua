
DamageTypes = {
	["default"] = "DOTA_COMBAT_CLASS_ATTACK_BASIC"
}

function FindUnitDamageType(class_name)

	if DamageTypes[class_name] ~= nil then
		return DamageTypes[class_name]
	end

	local kv_units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	local kv_unit = kv_units[class_name]

	if kv_unit and kv_unit["CombatClassAttack"] ~= nil and kv_unit["CombatClassAttack"] ~= "" then
		DamageTypes[class_name] = kv_unit["CombatClassAttack"]
	else
		DamageTypes[class_name] = DamageTypes["default"]
	end

	return DamageTypes[class_name]

end


function DamageTypeBonusOnTakeDamage( keys )

	local caster = keys.caster
	local damage_type = FindProjectileInfo( caster:GetUnitName() )
	if damage_type == keys["DamageType"] then

		local target = keys.target
		local ability = keys.ability
		local ability_level = ability:GetLevel() - 1

		local damage = keys["DamageTaken"]
		local damage_multiplier = ability:GetLevelSpecialValueFor("BonusPercent", ability_level)

		local data = {
			attacker = caster,
			victim = target,
			damage = damage * damage_multiplier,
			damage_type = damage_type
		}
		ApplyDamage( data )

	end

end
