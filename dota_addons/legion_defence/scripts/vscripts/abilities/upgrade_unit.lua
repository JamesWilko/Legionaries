
if upgrade_unit == nil then
	upgrade_unit = class({})
end

UPGRADE_FAIL_REASON_WAVE_RUNNING 		= 1
UPGRADE_FAIL_REASON_CANT_AFFORD_GOLD 	= 2
UPGRADE_FAIL_REASON_CANT_AFFORD_FOOD 	= 3
UPGRADE_FAIL_REASON_ALREADY_UPGRADING 	= 4
UPGRADE_FAIL_REASON_SOLD				= 5

LinkLuaModifier( "modifier_upgrade_unit_think", "abilities/modifier_upgrade_unit_think", LUA_MODIFIER_MOTION_NONE )

function upgrade_unit:CastFilterResult()

	-- Can't upgrading during waves
	if GameRules.LegionDefence and GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		self._fail_reason = UPGRADE_FAIL_REASON_WAVE_RUNNING
		return UF_FAIL_CUSTOM
	end

	-- Can only build if can afford
	self._gold_cost = self:GetSpecialValueFor( "GoldCost" )
	self._population_cost = self:GetSpecialValueFor( "PopulationCost" )
	if PlayerResource and GameRules.LegionDefence then

		local data = GameRules.LegionDefence:GetUnitController():GetUnitData( self:GetCaster() )
		self._owner_id = data.player:GetPlayerID()

		if not GameRules.LegionDefence:GetCurrencyController():CanAfford( CURRENCY_GOLD, self._owner_id, self._gold_cost ) then
			self._fail_reason = UPGRADE_FAIL_REASON_CANT_AFFORD
			return UF_FAIL_CUSTOM
		end

		if not GameRules.LegionDefence:GetCurrencyController():CanAfford( CURRENCY_FOOD, self._owner_id, self._population_cost ) then
			self._fail_reason = UPGRADE_FAIL_REASON_CANT_AFFORD_FOOD
			return UF_FAIL_CUSTOM
		end

	end

	-- Prevent upgrading while being sold
	if self:GetCaster()._selling then
		self._fail_reason = UPGRADE_FAIL_REASON_SOLD
		return UF_FAIL_CUSTOM
	end

	-- Prevent double-upgrading
	if self:GetCaster()._upgrading then
		self._fail_reason = UPGRADE_FAIL_REASON_ALREADY_UPGRADING
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS

end

function upgrade_unit:GetCustomCastError()
	if self._fail_reason == UPGRADE_FAIL_REASON_WAVE_RUNNING then
		return "#legion_can_not_upgrade_during_round"
	end
	if self._fail_reason == UPGRADE_FAIL_REASON_CANT_AFFORD_GOLD then
		return "#legion_can_not_upgrade_cant_afford_gold"
	end
	if self._fail_reason == UPGRADE_FAIL_REASON_CANT_AFFORD_FOOD then
		return "#legion_can_not_upgrade_cant_afford_population"
	end
	if self._fail_reason == UPGRADE_FAIL_REASON_SOLD then
		return "#legion_can_not_upgrade_being_sold"
	end
	if self._fail_reason == UPGRADE_FAIL_REASON_ALREADY_UPGRADING then
		return "#legion_can_not_upgrade_already_upgrading"
	end
end

function upgrade_unit:OnSpellStart()

	local has_upgrade = self:HasUpgrade()
	local upgrade_class = self:GetUpgradeClass()

	-- Prevent unit from moving
	self:GetCaster():SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
	self:GetCaster():StartGesture( ACT_DOTA_TELEPORT )
	self:GetCaster()._upgrading = true

	-- Spend costs
	self:SpendGoldCost()
	self:SpendFoodCost()

	-- Start upgrade animation
	local kv = {}
	CreateModifierThinker( self:GetCaster(), self, "modifier_upgrade_unit_think", kv, self:GetCaster():GetOrigin(), self:GetCaster():GetTeamNumber(), false )

end

function upgrade_unit:HasUpgrade()
	return self:GetUpgradeClass() ~= nil
end

function upgrade_unit:GetUpgradeClass()
	-- Override this in child classes to spawn an upgraded unit
	return nil
end

function upgrade_unit:SpendGoldCost()
	if self._gold_cost == nil then
		self._gold_cost = self:GetSpecialValueFor( "GoldCost" )
	end
	if GameRules.LegionDefence and self._owner_id ~= nil then
		GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CURRENCY_GOLD, self._owner_id, -self._gold_cost )
	end
end

function upgrade_unit:SpendFoodCost()
	if self._population_cost == nil then
		self._population_cost = self:GetSpecialValueFor( "PopulationCost" )
	end
	if GameRules.LegionDefence and self._owner_id ~= nil then
		GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CURRENCY_FOOD, self._owner_id, -self._population_cost )
	end
end
