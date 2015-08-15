
if upgrade_unit == nil then
	upgrade_unit = class({})
end

UPGRADE_FAIL_REASON_WAVE_RUNNING 		= 1
UPGRADE_FAIL_REASON_CANT_AFFORD 		= 2
UPGRADE_FAIL_REASON_ALREADY_UPGRADING 	= 3

LinkLuaModifier( "modifier_upgrade_unit_think", "abilities/upgrades/modifier_upgrade_unit_think", LUA_MODIFIER_MOTION_NONE )

function upgrade_unit:CastFilterResult()

	-- Can't upgrading during waves
	if GameRules.LegionDefence and GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		self._fail_reason = UPGRADE_FAIL_REASON_WAVE_RUNNING
		return UF_FAIL_CUSTOM
	end

	-- Can only build if can afford
	self._gold_cost = self:GetSpecialValueFor( "GoldCost" )
	if PlayerResource and GameRules.LegionDefence then

		local data = GameRules.LegionDefence:GetUnitController():GetUnitData( self:GetCaster() )
		local gold = PlayerResource:GetGold( data.player:GetPlayerID() )
		self._owner_id = data.player:GetPlayerID()

		if gold < self._gold_cost then
			self._fail_reason = UPGRADE_FAIL_REASON_CANT_AFFORD
			return UF_FAIL_CUSTOM
		end

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
	if self._fail_reason == UPGRADE_FAIL_REASON_CANT_AFFORD then
		return "#legion_can_not_upgrade_during_round"
	end
	if self._fail_reason == UPGRADE_FAIL_REASON_ALREADY_UPGRADING then
		return "#legion_can_not_upgrade_already_upgrading"
	end
end

function upgrade_unit:OnSpellStart()

	local has_upgrade, upgrade_class = self:HasUpgrade()

	-- Prevent unit from moving
	self:GetCaster():SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
	self:GetCaster():StartGesture( ACT_DOTA_TELEPORT )

	self:GetCaster()._upgrading = true

	-- Spend gold
	self:SpendGoldCost()

	-- Start upgrade animation
	local kv = {}
	CreateModifierThinker( self:GetCaster(), self, "modifier_upgrade_unit_think", kv, self:GetCaster():GetOrigin(), self:GetCaster():GetTeamNumber(), false )

end

function upgrade_unit:HasUpgrade()

	local unit_class = self:GetCaster():GetUnitName()
	local split = string.split( unit_class, "_" )
	local level = split[#split]
	level = split[#split]:sub( 6, #level )

	unit_class = unit_class:sub( 1, #unit_class - #level )
	level = tonumber(level)
	if level then
		local next_level = level + 1
		return true, (unit_class .. tostring(next_level))
	end

	return false

end

function upgrade_unit:GetUpgradeClass()
	local upgrade, class = self:HasUpgrade()
	return upgrade and class or nil
end

function upgrade_unit:SpendGoldCost()
	if self._gold_cost == nil then
		self._gold_cost = self:GetSpecialValueFor( "GoldCost" )
	end
	if PlayerResource and GameRules.LegionDefence and self._owner_id ~= nil then
		PlayerResource:ModifyGold( self._owner_id, -self._gold_cost, true, DOTA_ModifyGold_AbilityCost )
		PlayGoldParticlesForCost( self._gold_cost, self:GetCaster() )
	end
end

