
function OnAttackLanded( keys )

	local chance = keys["BashChance"] or 0
	local rand = math.random()
	print("Checking bash chance: " .. rand .. " < " .. chance)

	if math.random() < chance then

		-- Bash unit
		local modifier = keys["ModifierName"]
		keys.ability:ApplyDataDrivenModifier(keys.caster, keys.target, modifier, nil)

		-- Start ability cooldown
		keys.ability:StartCooldown(keys.ability:GetCooldown(keys.ability:GetLevel()))

		-- Play sound
		keys.target:EmitSound("DOTA_Item.SkullBasher")

	end

end
