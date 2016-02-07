
local UnitAI = {}
UnitAI.__unit = nil
UnitAI.__think_func = nil
UnitAI.__abilities = {}
UnitAI._THINK_DELAY = 1.0

function UnitAI:Spawn( aiType, thisEntity )

	UnitAI.__unit = thisEntity
	thisEntity:SetContextThink( "PerformUnitThink", PerformUnitThink , self._THINK_DELAY )
	print(string.format("Starting %s unit AI for %s (%i) ", aiType, thisEntity:GetUnitName(), thisEntity:GetEntityIndex()))

end

function UnitAI:SetThinkFunction( func )
	self.__think_func = func
end

function UnitAI:SetThinkDelay( think )
	self._THINK_DELAY = think
end

function PerformUnitThink()
	if UnitAI.__think_func then
		UnitAI.__think_func( UnitAI )
	end
	return UnitAI._THINK_DELAY
end

function UnitAI:FindAbilityWithKey( key )

	if (not self.__abilities or #self.__abilities == 0) and UnitAI.__unit then
		self.__abilities = GetUnitUniqueAbilities( UnitAI.__unit )
	end

	for k, ability in pairs( self.__abilities ) do

		if ability:IsCooldownReady() then

			local key_value = ability:GetSpecialValueFor( key )
			if key_value then
				return ability, key_value
			end

		end

	end

	return nil

end

function UnitAI:GetUnitAverageDamagePerSecond( unit )

	if unit then
		if unit:IsStunned() or unit:IsDisarmed() then
			return 0
		else
			return unit:GetAverageTrueAttackDamage() * unit:GetAttacksPerSecond()
		end
	end

	return -1

end

function UnitAI:GetHighestDPSUnit( unitsList )

	if unitsList then

		local highestDPS = -1
		local highestDPSUnit = nil

		for index, unit in pairs(unitsList) do
			local dps = self:GetUnitAverageDamagePerSecond(unit)
			if dps > highestDPS then
				highestDPSUnit = unit
				highestDPS = dps
			end
		end

		return highestDPSUnit

	end
	
	return nil

end

return UnitAI
