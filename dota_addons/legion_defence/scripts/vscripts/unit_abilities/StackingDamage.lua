
function ApplyStackingDamage( keys )

	local MODIFIER_STACKING_DAMAGE = "modifier_stacking_damage_target"

	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local damage_per_stack = ability:GetSpecialValueFor( "damage_per_stack" )
	local max_stacks = ability:GetSpecialValueFor( "duration" )
	local stack_duration = ability:GetSpecialValueFor( "duration" )
	
	if target:HasModifier( MODIFIER_STACKING_DAMAGE ) then

		local current_damage_stack = target:GetModifierStackCount( MODIFIER_STACKING_DAMAGE, ability )
		local new_stacks_num = current_damage_stack + 1
		if new_stacks_num > max_stacks then
			new_stacks_num = max_stacks
		end
		
		local data = {
			attacker = caster,
			victim = target,
			damage = damage_per_stack * current_damage_stack,
			damage_type = ability:GetAbilityDamageType()
		}
		ApplyDamage( data )
		
		local stack_data = {
			Duration = stack_duration
		}
		ability:ApplyDataDrivenModifier( caster, target, MODIFIER_STACKING_DAMAGE, stack_data )
		target:SetModifierStackCount( MODIFIER_STACKING_DAMAGE, ability, new_stacks_num )

	else

		local data = {
			Duration = stack_duration
		}
		ability:ApplyDataDrivenModifier( caster, target, MODIFIER_STACKING_DAMAGE, data )
		target:SetModifierStackCount( MODIFIER_STACKING_DAMAGE, ability, 1 )

	end

end
