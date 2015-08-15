
if upgrade_unit == nil then
	upgrade_unit = class({})
end

LinkLuaModifier( "modifier_upgrade_unit_think", "abilities/modifier_upgrade_unit_think", LUA_MODIFIER_MOTION_NONE )

function upgrade_unit:CastFilterResult()

	-- Can't upgrading during waves
	if GameRules.LegionDefence and GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		return UF_FAIL_CUSTOM
	end

	-- Prevent double-upgrading
	if self:GetCaster()._upgrading then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS

end

function upgrade_unit:GetCustomCastError()
	if GameRules.LegionDefence and GameRules.LegionDefence:GetWaveController():IsWaveRunning() then
		return "#legion_cant_upgrade_during_round"
	end
	if self:GetCaster()._upgrading then
		return "#legion_unit_already_upgrading"
	end
end

function upgrade_unit:OnSpellStart()

	local has_upgrade, upgrade_class = self:HasUpgrade()

	-- Prevent unit from moving
	self:GetCaster():SetMoveCapability( DOTA_UNIT_CAP_MOVE_NONE )
	self:GetCaster():StartGesture( ACT_DOTA_TELEPORT )

	self:GetCaster()._upgrading = true

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
