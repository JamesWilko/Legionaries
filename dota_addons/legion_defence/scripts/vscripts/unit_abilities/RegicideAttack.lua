
function ApplyRegicideDamage( keys )

	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local king_controller = GameRules.LegionDefence:GetKingController()

	if king_controller and king_controller:IsUnitAKing(target) then
		
		local damage_multiplier = ability:GetSpecialValueFor( "damage_percent" ) or 2
		local extra_damage = caster:GetAttackDamage() * (damage_multiplier - 1)

		local data = {
			attacker = caster,
			victim = target,
			damage = extra_damage,
			damage_type = ability:GetAbilityDamageType()
		}
		ApplyDamage( data )

	end

end
