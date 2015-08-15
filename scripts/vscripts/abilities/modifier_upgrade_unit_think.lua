
if modifier_upgrade_unit_think == nil then
	modifier_upgrade_unit_think = class({})
end

function modifier_upgrade_unit_think:IsHidden()
	return true
end

function modifier_upgrade_unit_think:OnCreated( kv )

	self._delay = self:GetAbility():GetSpecialValueFor( "upgrade_delay" )

	if IsServer() then

		self:StartIntervalThink( self._delay )

		self._particle_index = ParticleManager:CreateParticle( "particles/items2_fx/teleport_start.vpcf", PATTACH_WORLDORIGIN, self:GetCaster() )
		ParticleManager:SetParticleControl( self._particle_index, 0, self:GetCaster():GetOrigin() )
		ParticleManager:SetParticleControl( self._particle_index, 1, self:GetCaster():GetOrigin() )

		ParticleManager:SetParticleControl( self._particle_index, 2, Vector(0, 0, 0) )

	end

end

function modifier_upgrade_unit_think:OnIntervalThink()
	if IsServer() then

		-- Destroy leveling particles
		if self._particle_index then
			ParticleManager:DestroyParticle(self._particle_index, false )
			self._particle_index = nil
		end

		-- Make sure unit to upgrade is still alive
		if not self._hUnit and (not IsValidEntity(self:GetCaster()) or not self:GetCaster():IsAlive()) then
			return nil
		end

		-- Stop victory gesture once spawned and started the gesture
		if self._hUnit then
			self._hUnit:RemoveGesture( ACT_DOTA_VICTORY )
			UTIL_Remove( self:GetParent() )
			return nil
		end

		-- Get unit position and rotation
		local vPosition = self:GetCaster():GetOrigin()
		local vAngles = self:GetCaster():GetAnglesAsVector()

		-- Spawn in new unit and show victory gesture
		local hUnit = CreateUnitByName( self:GetAbility():GetUpgradeClass(), vPosition, false, nil, self:GetCaster(), self:GetCaster():GetTeamNumber() )
		if hUnit ~= nil then

			hUnit:SetOwner( self:GetCaster() )
			hUnit:SetControllableByPlayer( self:GetCaster():GetOwner():GetPlayerID(), true )
			hUnit:SetOrigin( vPosition )
			hUnit:SetAngles( vAngles.x, vAngles.y, vAngles.z )

			hUnit:StartGesture( ACT_DOTA_VICTORY )

			self._hUnit = hUnit
			UTIL_Remove( self:GetCaster() )

			return 0.1

		end

	end
end
