
if modifier_sell_unit_nature_think == nil then
	modifier_sell_unit_nature_think = class({})
end

function modifier_sell_unit_nature_think:IsHidden()
	return true
end

function modifier_sell_unit_nature_think:OnCreated( kv )

	self._delay = self:GetAbility():GetSpecialValueFor( "SellDelay" )
	
	if IsServer() then

		self:StartIntervalThink( self._delay )

		self._particle_index = ParticleManager:CreateParticle( "particles/items2_fx/teleport_start.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( self._particle_index, 0, self:GetCaster():GetOrigin() )
		ParticleManager:SetParticleControl( self._particle_index, 1, self:GetCaster():GetOrigin() )

		ParticleManager:SetParticleControl( self._particle_index, 2, Vector(0, 0, 0) )

	end

end

function modifier_sell_unit_nature_think:OnIntervalThink()
	if IsServer() then

		-- Destroy leveling particles
		if self._particle_index then
			ParticleManager:DestroyParticle( self._particle_index, false )
			self._particle_index = nil
		end

		-- Remove unit
		UTIL_Remove( self:GetCaster() )

		-- Remove self
		UTIL_Remove( self:GetParent() )

	end
end
