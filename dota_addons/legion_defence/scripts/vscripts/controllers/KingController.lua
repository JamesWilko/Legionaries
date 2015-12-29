
if CKingController == nil then
	CKingController = class({})
end

CKingController.KING_CLASSES = {
	[1] = "npc_legion_king_radiant",
	[2] = "npc_legion_king_radiant",
}

CKingController.NET_TABLE = "KingUpgradeData"
CKingController.KEY_HEALTH = "health"
CKingController.KEY_REGEN = "regen"
CKingController.KEY_ARMOUR = "armour"
CKingController.KEY_ATTACK = "attack"

CKingController.UPGRADES = {
	[CKingController.KEY_HEALTH] = {
		per_level = 500,
		cost = 80,
		currency = CURRENCY_GEMS,
		func = function(controller, hPlayer, hKing) controller:UpgradeHealth(hPlayer, hKing) end
	},
	[CKingController.KEY_REGEN] = {
		per_level = 2,
		cost = 80,
		currency = CURRENCY_GEMS,
		func = function(controller, hPlayer, hKing) controller:UpgradeRegen(hPlayer, hKing) end
	},
	[CKingController.KEY_ARMOUR] = {
		per_level = 2,
		cost = 80,
		currency = CURRENCY_GEMS,
		func = function(controller, hPlayer, hKing) controller:UpgradeArmour(hPlayer, hKing) end
	},
	[CKingController.KEY_ATTACK] = {
		per_level = 25,
		cost = 80,
		currency = CURRENCY_GEMS,
		func = function(controller, hPlayer, hKing) controller:UpgradeAttack(hPlayer, hKing) end
	}
}

function CLegionDefence:SetupKingController()
	self.king_controller = CKingController()
	self.king_controller:Setup()
end

function CLegionDefence:GetKingController()
	return self.king_controller
end

function CKingController:Setup()

	self._kings = {}

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

	-- Setup events
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CKingController, "HandleOnEntityKilled"), self)
	CustomGameEventManager:RegisterListener( "legion_purchase_king_upgrade", Dynamic_Wrap(CKingController, "HandleOnUpgradePurchased") )

end

function CKingController:GetKingForTeam( iTeam )
	return self._kings[iTeam]
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
function CKingController.HandleOnUpgradePurchased( iPlayerId, eventArgs )

	local self = GameRules.LegionDefence:GetKingController()
	local upgradeTable = CKingController.UPGRADES[eventArgs.sUpgradeId]

	iPlayerId = iPlayerId - 1

	-- Check if can afford upgrade
	local currency_controller = GameRules.LegionDefence:GetCurrencyController()
	if not currency_controller:CanAfford( upgradeTable.currency, iPlayerId, upgradeTable.cost ) then
		return false, "could_not_affort"
	end

	-- Deduct purchase
	currency_controller:ModifyCurrency( upgradeTable.currency, iPlayerId, -upgradeTable.cost )

	-- Find purchasers king
	local hPlayer = PlayerResource:GetPlayer( iPlayerId )
	local hKing = self:GetKingForTeam( hPlayer:GetTeamNumber() )
	if not hKing then
		return false, "no_king_unit"
	end

	-- Run upgrade function
	if upgradeTable.func then
		upgradeTable.func( self, hPlayer, hKing )
	end
	return true

end

function CKingController:UpgradeHealth( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_HEALTH].per_level
	hKing:SetMaxHealth( hKing:GetMaxHealth() + increaseAmount )
end

function CKingController:UpgradeRegen( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_REGEN].per_level
	hKing:SetBaseHealthRegen( hKing:GetBaseHealthRegen() + increaseAmount )
	hKing:SetBaseManaRegen( hKing:GetManaRegen() + increaseAmount )
end

function CKingController:UpgradeArmour( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_ARMOUR].per_level
	hKing:SetPhysicalArmorBaseValue( hKing:GetPhysicalArmorBaseValue() + increaseAmount )
end

function CKingController:UpgradeAttack( hPlayer, hKing )
	local increaseAmount = CKingController.UPGRADES[CKingController.KEY_ATTACK].per_level
	hKing:SetBaseDamageMax( hKing:GetBaseDamageMax() + increaseAmount )
	hKing:SetBaseDamageMin( hKing:GetBaseDamageMin() + increaseAmount )
end
