
if sell_unit == nil then
	sell_unit = class({})
end

SELL_FAIL_REASON_WAVE_RUNNING 		= 1
SELL_FAIL_REASON_ALREADY_SELLING	= 2
SELL_FAIL_REASON_UPGRADING			= 3

function sell_unit:CastFilterResult()

	-- Can't sell during waves
	if GameRules.LegionDefence and GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		self._fail_reason = SELL_FAIL_REASON_WAVE_RUNNING
		return UF_FAIL_CUSTOM
	end

	-- Prevent selling while upgrading
	if self:GetCaster()._upgrading then
		self._fail_reason = SELL_FAIL_REASON_UPGRADING
		return UF_FAIL_CUSTOM
	end

	-- Prevent double-selling
	if self:GetCaster()._selling then
		self._fail_reason = SELL_FAIL_REASON_ALREADY_SELLING
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS

end

function sell_unit:GetCustomCastError()
	if self._fail_reason == SELL_FAIL_REASON_WAVE_RUNNING then
		return "#legion_can_not_sell_during_round"
	end
	if self._fail_reason == SELL_FAIL_REASON_UPGRADING then
		return "#legion_can_not_sell_being_upgraded"
	end
	if self._fail_reason == SELL_FAIL_REASON_ALREADY_SELLING then
		return "#legion_can_not_sell_already_selling"
	end
end

function sell_unit:OnSpellStart()

	-- Get owning player
	local data = GameRules.LegionDefence:GetUnitController():GetUnitData( self:GetCaster() )
	self._owner_id = data.player:GetPlayerID()

	-- Prevent player from moving unit
	self:GetCaster():SetControllableByPlayer( self._owner_id, false )

	-- Unregiser unit from controller
	GameRules.LegionDefence:GetUnitController():UnregisterUnit( self:GetCaster() )

	-- Prevent unit from moving
	self:GetCaster():SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
	self:GetCaster():StartGesture( ACT_DOTA_TELEPORT )
	self:GetCaster()._selling = true

	-- Give gold and food back to player
	self:ReturnSpawnCostToPlayer()

	-- Play modifier
	if self:ModifierToRun() then
		local kv = {}
		CreateModifierThinker( self:GetCaster(), self, self:ModifierToRun(), kv, self:GetCaster():GetOrigin(), self:GetCaster():GetTeamNumber(), false )
	end

	-- Remove unit if modifier doesn't
	if not self:ModifierDestroysUnit() then
		UTIL_Remove( self:GetCaster() )
	end

end

function sell_unit:ReturnSpawnCostToPlayer()

	if self._owner_id ~= nil then

		-- Return gold to player
		local gold_amount = GameRules.LegionDefence:GetUnitController():GetCurrentSellCostOfUnit( self:GetCaster(), CURRENCY_GOLD )
		GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CURRENCY_GOLD, self._owner_id, gold_amount, true )

		-- Play gold particles from unit to player
		local ownerPlayer = self:GetCaster():GetOwner()
		if ownerPlayer then
			local ownerUnit = ownerPlayer:GetAssignedHero()
			PlayCurrencyGainedParticles( CURRENCY_GOLD, gold_amount, ownerUnit, ownerPlayer, ownerUnit:GetCenter() )
			ShowCurrencyPopup( ownerPlayer, ownerUnit, CURRENCY_GOLD, gold_amount )
		end

		-- Return food cost to player
		local food_amount = GameRules.LegionDefence:GetUnitController():GetTotalCostOfUnit( self:GetCaster(), CURRENCY_FOOD )
		GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CURRENCY_FOOD, self._owner_id, food_amount )

	end

end

function sell_unit:ModifierToRun()
	return nil
end

function sell_unit:ModifierDestroysUnit()
	return false
end
