
if modifier_upgrade_unit_think == nil then
	modifier_upgrade_unit_think = class({})
end

function modifier_upgrade_unit_think:IsHidden()
	return true
end

function modifier_upgrade_unit_think:OnCreated( kv )

	self._delay = self:GetAbility():GetSpecialValueFor( "UpgradeDelay" )

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

		-- Stop upgrade gesture once spawned and started the gesture
		if self._hUnit then
			self._hUnit:RemoveGesture( ACT_DOTA_VICTORY )
			UTIL_Remove( self:GetParent() )
			return nil
		end

		-- Get unit position and rotation
		local vPosition = self:GetCaster():GetOrigin()
		local vAngles = self:GetCaster():GetAnglesAsVector()
		local cUnitController = GameRules.LegionDefence:GetUnitController()

		-- Spawn in new unit and show upgrade gesture
		local unitData = cUnitController:GetUnitData( self:GetCaster() )
		local hUnit = cUnitController:SpawnUnit( self:GetCaster():GetOwner(), self:GetCaster():GetTeamNumber(), self:GetAbility():GetUpgradeClass(), unitData.lane, vPosition )
		if hUnit ~= nil then

			-- Do upgrade gesture
			hUnit:StartGesture( ACT_DOTA_VICTORY )

			-- Get upgrade costs
			local gold_cost = self:GetAbility():GetSpecialValueFor( "GoldCost" ) or 0
			local gem_cost = self:GetAbility():GetSpecialValueFor( "GemsCost" ) or 0
			local food_cost = self:GetAbility():GetSpecialValueFor( "FoodCost" ) or 0
			
			-- Transfer costs to new unit
			cUnitController:TransferUnit( hUnit, self:GetCaster() )

			-- Add costs to unit
			if gold_cost > 0 then
				cUnitController:AddCostToUnit( hUnit, CURRENCY_GOLD, gold_cost, self:GetCaster() )
			end
			if gem_cost > 0 then
				cUnitController:AddCostToUnit( hUnit, CURRENCY_GEMS, gem_cost, self:GetCaster() )
			end
			if food_cost > 0 then
				cUnitController:AddCostToUnit( hUnit, CURRENCY_FOOD, food_cost, self:GetCaster() )
			end

			-- Remove and unregister old unit
			cUnitController:UnregisterUnit( self:GetCaster() )
			UTIL_Remove( self:GetCaster() )

			-- Stop upgrade gesture after it plays
			self._hUnit = hUnit
			return 0.1

		end

	end
end
