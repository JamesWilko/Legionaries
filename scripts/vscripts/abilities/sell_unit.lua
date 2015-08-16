
if sell_unit == nil then
	sell_unit = class({})
end

SELL_FAIL_REASON_WAVE_RUNNING 		= 1
SELL_FAIL_REASON_ALREADY_SELLING	= 2

-- LinkLuaModifier( "modifier_upgrade_unit_think", "abilities/upgrades/modifier_upgrade_unit_think", LUA_MODIFIER_MOTION_NONE )

function sell_unit:CastFilterResult()

	-- Can't sell during waves
	if GameRules.LegionDefence and GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		self._fail_reason = SELL_FAIL_REASON_WAVE_RUNNING
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

	-- Prevent unit from moving
	self:GetCaster():SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
	self:GetCaster():StartGesture( ACT_DOTA_TELEPORT )
	self:GetCaster()._selling = true

	-- Give gold back to player
	self:GiveGoldToPlayer()

	-- Remove unit
	UTIL_Remove( self:GetCaster() )

end

function sell_unit:GiveGoldToPlayer()

	-- Return gold to player and play particles
	if self._owner_id ~= nil then
		local gold_amount = GameRules.LegionDefence:GetUnitController():GetCurrentSellCostOfUnit( self:GetCaster() )
		PlayerResource:ModifyGold( self._owner_id, gold_amount, true, DOTA_ModifyGold_SellItem )
		PlayGoldParticlesForCost( gold_amount, self:GetCaster() )
	end

end
