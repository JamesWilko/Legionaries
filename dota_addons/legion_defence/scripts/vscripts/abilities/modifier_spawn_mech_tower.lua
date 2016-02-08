
if modifier_spawn_mech_tower == nil then
	modifier_spawn_mech_tower = class({})
end

function modifier_spawn_mech_tower:IsHidden()
	return true
end

function modifier_spawn_mech_tower:OnCreated( kv )

	self.effect_aoe = self:GetAbility():GetSpecialValueFor( "SpawnEffectAOE" )
	self.spawn_delay_time = 1
	self.particle_indices = {}

	if IsServer() then

		self:StartIntervalThink( self.spawn_delay_time )

		EmitSoundOnLocationForAllies( self:GetParent():GetOrigin(), "Ability.PreLightStrikeArray", self:GetCaster() )
		
		local nFXIndex = ParticleManager:CreateParticle( "particles/spawns/mech_gear.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.effect_aoe, 1, 1 ) )
		self.particle_indices["gear"] = nFXIndex
		-- ParticleManager:ReleaseParticleIndex( nFXIndex )
		
	end

end

function modifier_spawn_mech_tower:OnIntervalThink()
	if IsServer() then

		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_rattletrap/rattletrap_cog_attack.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( nFXIndex, 0, self:GetParent():GetOrigin() )
		ParticleManager:SetParticleControl( nFXIndex, 1, self:GetParent():GetOrigin() + Vector( 0, 0, 100 + self.effect_aoe ) )
		ParticleManager:SetParticleControl( nFXIndex, 9, Vector(1.3, 1, 1) )
		ParticleManager:SetParticleControl( nFXIndex, 9, Vector(1.7, 1, 1) )

		ParticleManager:ReleaseParticleIndex( nFXIndex )
		ParticleManager:ReleaseParticleIndex( self.particle_indices["gear"] )

		-- EmitSoundOnLocationWithCaster( self:GetParent():GetOrigin(), "Ability.LightStrikeArray", self:GetCaster() )

		self:GetAbility():SpawnUnitAtPosition( self:GetParent():GetOrigin() )

		UTIL_Remove( self:GetParent() )

	end
end
