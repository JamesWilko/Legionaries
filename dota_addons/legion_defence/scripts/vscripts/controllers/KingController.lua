
if CKingController == nil then
	CKingController = class({})
end

function CLegionDefence:SetupKingController()
	self.king_controller = CKingController()
	self.king_controller:Setup()
end

function CLegionDefence:GetKingController()
	return self.king_controller
end

---------------------------------------
-- King Controller
---------------------------------------
CKingController.KING_CLASSES = {
	[1] = "npc_legion_fire_heat_knight_upg",
	[DOTA_TEAM_GOODGUYS] = "npc_legion_king_radiant",
	[DOTA_TEAM_BADGUYS] = "npc_legion_king_dire",
}

CKingController.NET_TABLE = "KingUpgradeData"
CKingController.KEY_HEALTH = "health"
CKingController.KEY_REGEN = "regen"
CKingController.KEY_ARMOUR = "armour"
CKingController.KEY_ATTACK = "attack"
CKingController.KEY_HEAL = "heal"

CKingController.UPGRADES = {
	[CKingController.KEY_HEALTH] = {
		per_level = 500,
		cost = 80,
		max_level = 50,
		currency = CURRENCY_GEMS,
		icon = "item_vitality_booster",
		func = function(controller, hPlayer, hKing) controller:UpgradeHealth(hPlayer, hKing) end
	},
	[CKingController.KEY_REGEN] = {
		per_level = 2,
		cost = 80,
		max_level = 50,
		currency = CURRENCY_GEMS,
		icon = "item_ring_of_regen",
		func = function(controller, hPlayer, hKing) controller:UpgradeRegen(hPlayer, hKing) end
	},
	[CKingController.KEY_ARMOUR] = {
		per_level = 1,
		cost = 80,
		max_level = 25,
		currency = CURRENCY_GEMS,
		icon = "item_platemail",
		func = function(controller, hPlayer, hKing) controller:UpgradeArmour(hPlayer, hKing) end
	},
	[CKingController.KEY_ATTACK] = {
		per_level = 25,
		cost = 80,
		max_level = 25,
		currency = CURRENCY_GEMS,
		icon = "item_claymore",
		func = function(controller, hPlayer, hKing) controller:UpgradeAttack(hPlayer, hKing) end
	},
	[CKingController.KEY_HEAL] = {
		per_level = 100,
		cost = { default = 0 },
		max_level = 2,
		display_cost = "x1",
		currency = CURRENCY_GEMS,
		icon = "item_cheese",
		func = function(controller, hPlayer, hKing) controller:InstaHealKing(hPlayer, hKing) end
	}
}
CKingController.MAXIMUM_HEALS_PER_PLAYER = 1

function CKingController:Setup()

	self._kings = {}
	self._team_upgrades = {}
	self._used_heals = {}

	-- Spawn kings
	local spawns = GameRules.LegionDefence:GetMapController():KingSpawns()
	for k, v in pairs( spawns ) do

		local king_class = CKingController.KING_CLASSES[v.team] or CKingController.KING_CLASSES[1]
		local hUnit = CreateUnitByName( king_class, v.entity:GetOrigin(), true, nil, nil, v.team )
		if hUnit then
			hUnit:SetAngles( 0, 90, 0 )
			self._kings[v.team] = hUnit
		end

	end

	-- Send upgrade information to the players
	CustomNetTables:SetTableValue( CKingController.NET_TABLE, "data", CKingController.UPGRADES )

	-- Setup default upgrade levels
	self._team_upgrades[DOTA_TEAM_GOODGUYS] = {}
	self._team_upgrades[DOTA_TEAM_BADGUYS] = {}

	for k, v in pairs( CKingController.UPGRADES ) do
		if v.max_level ~= nil then
			self._team_upgrades[DOTA_TEAM_GOODGUYS][k] = 1
			self._team_upgrades[DOTA_TEAM_BADGUYS][k] = 1
		end
	end

	CustomNetTables:SetTableValue( CKingController.NET_TABLE, "levels", self._team_upgrades )

	-- Setup events
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CKingController, "HandleOnEntityKilled"), self)
	CustomGameEventManager:RegisterListener( "legion_purchase_king_upgrade", Dynamic_Wrap(CKingController, "HandleOnUpgradePurchased") )

end

function CKingController:GetKings()
	return self._kings
end

function CKingController:GetKingForTeam( iTeam )
	return self._kings[iTeam]
end

function CKingController:GetUpgradeLevel( sUpgradeId, iTeam )
	self._team_upgrades = self._team_upgrades or {}
	self._team_upgrades[iTeam] = self._team_upgrades[iTeam] or {}
	self._team_upgrades[iTeam][sUpgradeId] = self._team_upgrades[iTeam][sUpgradeId] or 1
	return self._team_upgrades[iTeam][sUpgradeId]
end

function CKingController:IsUpgradeAtMaxLevel( sUpgradeId, iTeam )
	local currentLevel = self:GetUpgradeLevel(sUpgradeId, iTeam)
	return (CKingController.UPGRADES[sUpgradeId].max_level or 1) == currentLevel
end

function CKingController:IncreaseUpgradeLevel( sUpgradeId, iTeam )
	local currentLevel = self:GetUpgradeLevel(sUpgradeId, iTeam)
	self._team_upgrades[iTeam][sUpgradeId] = currentLevel + 1
	CustomNetTables:SetTableValue( CKingController.NET_TABLE, "levels", self._team_upgrades )
end

function CKingController:HandleOnEntityKilled( event )

	local unit = EntIndexToHScript( event.entindex_killed )
	if unit and self._kings then
		for team, king in pairs( self._kings ) do
			if unit == king then

				-- Force loss of team whose king died
				GameRules:MakeTeamLose( team )

			end
		end
	end

end

---------------------------------------
--	King Item Upgrades
---------------------------------------
function CKingController.HandleOnUpgradePurchased( iPlayerId_Wrong, eventArgs )

	local self = GameRules.LegionDefence:GetKingController()
	local iPlayerId = eventArgs["PlayerID"]
	local upgradeTable = CKingController.UPGRADES[eventArgs.sUpgradeId]

	local hPlayer = PlayerResource:GetPlayer( iPlayerId )
	local iPlayerTeam = hPlayer:GetTeamNumber()

	-- Get upgrade price
	local cost = upgradeTable.cost
	if type(cost) == "table" then
		cost = upgradeTable.cost[iPlayerId]
		if cost == nil then
			cost = upgradeTable.cost["default"]
		end
	end
	
	-- Don't allow purchasing if cost is negative
	if cost < 0 then
		return false, "unavailable"
	end

	-- Check if upgrade is at maximum level
	if self:IsUpgradeAtMaxLevel( eventArgs.sUpgradeId, iPlayerTeam ) then
		return false, "max_level"
	end

	-- Check if can afford upgrade
	local currency_controller = GameRules.LegionDefence:GetCurrencyController()
	if not currency_controller:CanAfford( upgradeTable.currency, iPlayerId, cost, true ) then
		return false, "could_not_afford"
	end

	-- Find purchasers king
	local hKing = self:GetKingForTeam( hPlayer:GetTeamNumber() )
	if not hKing then
		return false, "no_king_unit"
	end

	-- Deduct purchase
	currency_controller:ModifyCurrency( upgradeTable.currency, iPlayerId, -cost )

	-- Increase upgrade level for team
	self:IncreaseUpgradeLevel( eventArgs.sUpgradeId, iPlayerTeam )

	-- Run upgrade function
	if upgradeTable.func then
		upgradeTable.func( self, hPlayer, hKing )
	end
	return true

end

function CKingController:UpgradeHealth( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_HEALTH].per_level
	hKing:SetMaxHealth( hKing:GetMaxHealth() + increaseAmount )
	self:SpawnUpgradeParticles(hKing)
end

function CKingController:UpgradeRegen( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_REGEN].per_level
	hKing:SetBaseHealthRegen( hKing:GetBaseHealthRegen() + increaseAmount )
	hKing:SetBaseManaRegen( hKing:GetManaRegen() + increaseAmount )
	self:SpawnUpgradeParticles(hKing)
end

function CKingController:UpgradeArmour( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_ARMOUR].per_level
	hKing:SetPhysicalArmorBaseValue( hKing:GetPhysicalArmorBaseValue() + increaseAmount )
	self:SpawnUpgradeParticles(hKing)
end

function CKingController:UpgradeAttack( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_ATTACK].per_level
	hKing:SetBaseDamageMax( hKing:GetBaseDamageMax() + increaseAmount )
	hKing:SetBaseDamageMin( hKing:GetBaseDamageMin() + increaseAmount )
	self:SpawnUpgradeParticles(hKing)
end

function CKingController:SpawnUpgradeParticles( hKing )

	EmitSoundOnLocationForAllies( hKing:GetOrigin(), "Hero_Omniknight.Purification", hKing )

	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_WORLDORIGIN, hKing )
	ParticleManager:SetParticleControl( nFXIndex, 0, hKing:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 450, 1, 1 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

end

---------------------------------------
--	King Instaheal
---------------------------------------
function CKingController:InstaHealKing( hPlayer, hKing )

	local playerId = hPlayer:GetPlayerID()

	-- Setup player data if it doesn't exist
	self._used_heals[playerId] = self._used_heals[playerId] or 0

	-- Can player heal the king
	if self._used_heals[playerId] < CKingController.MAXIMUM_HEALS_PER_PLAYER then

		-- Perform the heal
		self:PerformHeal( hPlayer, hKing )

		-- Increment heals by this player
		self._used_heals[playerId] = self._used_heals[playerId] + 1

		-- Update net table with heals,
		-- use negative to count used heals yet show button as disabled
		CKingController.UPGRADES[CKingController.KEY_HEAL]["cost"][playerId] = -self._used_heals[playerId]
		CustomNetTables:SetTableValue( CKingController.NET_TABLE, "data", CKingController.UPGRADES )

		return true

	end

	return false

end

function CKingController:PerformHeal( hPlayer, hKing )

	local heal_percent = CKingController.UPGRADES[CKingController.KEY_HEAL].per_level / 100

	-- Set health
	local max_health = hKing:GetMaxHealth()
	local new_health = max_health * heal_percent
	if new_health > hKing:GetHealth() then
		hKing:SetHealth(new_health)
	end

	-- Set mana
	local max_mana = hKing:GetMaxMana()
	local new_mana = max_health * heal_percent
	if new_mana > hKing:GetMana() then
		hKing:SetMana(max_mana)
	end

	-- Show particles and sounds
	EmitSoundOnLocationForAllies( hKing:GetOrigin(), "Hero_Omniknight.GuardianAngel.Cast", hKing )

	local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf", PATTACH_WORLDORIGIN, hKing )
	ParticleManager:SetParticleControl( nFXIndex, 0, hKing:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 450, 1, 1 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )

end
