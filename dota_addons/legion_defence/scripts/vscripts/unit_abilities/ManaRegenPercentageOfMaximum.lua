
function ManaRegenOnIntervalThink( keys )

	local ability = keys.ability
	local ability_level = ability:GetLevel() or 1
	local caster = keys.caster

	local regen_percent = keys.ManaPercent * 0.01
	local regen_amount = caster:GetMaxMana() * regen_percent
	caster:SetMana( caster:GetMana() + regen_amount )

end
