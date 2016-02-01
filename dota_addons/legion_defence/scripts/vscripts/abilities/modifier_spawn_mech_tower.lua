
if modifier_spawn_mech_tower == nil then
	modifier_spawn_mech_tower = class({})
end

function modifier_spawn_mech_tower:IsHidden()
	return true
end

function modifier_spawn_mech_tower:OnCreated( kv )

	self.effect_aoe = self:GetAbility():GetSpecialValueFor( "SpawnEffectAOE" )
	self.spawn_delay_time = 1

	if IsServer() then

		self:StartIntervalThink( self.spawn_delay_time )

		EmitSoundOnLocationForAllies( self:GetParent():GetOrigin(), "Ability.PreLightStrikeArray", self:GetCaster() )
		
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array_ray_team.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.effect_aoe, 1, 1 ) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
		
	end

end

function modifier_spawn_mech_tower:OnIntervalThink()
	if IsServer() then

		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.effect_aoe, 1, 1 ) )
		ParticleManager:ReleaseParticleIndex( nFXIndex )

		EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), "Ability.LightStrikeArray", self:GetCaster() )

		self:GetAbility():SpawnUnitAtPosition( self:GetParent():GetOrigin() )

		UTIL_Remove( self:GetParent() )

	end
end
