
if CKingController == nil then
	CKingController = class({})
end

CKingController.KING_CLASSES = {
	[1] = "npc_legion_king_radiant",
	[2] = "npc_legion_king_radiant",
}
CKingController.KING_UPGRADE_ITEM = "item_legion_king_upgrade_"
CKingController.ITEM_UPGRADE_TYPE = {
	["health"] = "UpgradeHealth",
	["regen"] = "UpgradeRegen",
	["armour"] = "UpgradeArmour",
	["attack"] = "UpgradeAttack",
}
CKingController.UPGRADE_AMOUNTS = {
	["health"] = 500,
	["regen"] = 2,
	["armour"] = 2,
	["attack"] = 25,
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

	ListenToGameEvent("entity_killed", Dynamic_Wrap(CKingController, "HandleOnEntityKilled"), self)
	ListenToGameEvent("dota_item_purchased", Dynamic_Wrap(CKingController, "HandleOnItemPurchased"), self)

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
function CKingController:HandleOnItemPurchased( event )

	if string.lower(string.sub(event.itemname, 1, #CKingController.KING_UPGRADE_ITEM)) == CKingController.KING_UPGRADE_ITEM then

		-- Remove upgrade item purchased
		for k, v in pairs( Entities:FindAllByName(event.itemname) ) do
			UTIL_Remove(v)
		end

		-- Find purchasers king
		local hPlayer = PlayerResource:GetPlayer( event.PlayerID )
		local hKing = self:GetKingForTeam( hPlayer:GetTeamNumber() )
		if not hKing then
			return
		end

		-- Do upgrade
		local upgrade_purchased = string.lower(string.sub(event.itemname, #CKingController.KING_UPGRADE_ITEM + 1, #event.itemname))
		local func = CKingController.ITEM_UPGRADE_TYPE[upgrade_purchased]
		self[func]( self, hPlayer, hKing )

	end

end

function CKingController:UpgradeHealth( hPlayer, hKing )
	-- print("CKingController:UpgradeHealth")
	hKing:SetMaxHealth( hKing:GetMaxHealth() + CKingController.UPGRADE_AMOUNTS["health"] )
end

function CKingController:UpgradeRegen( hPlayer, hKing )
	-- print("CKingController:UpgradeRegen")
	hKing:SetBaseHealthRegen( hKing:GetBaseHealthRegen() + CKingController.UPGRADE_AMOUNTS["regen"] )
	hKing:SetBaseManaRegen( hKing:GetManaRegen() + CKingController.UPGRADE_AMOUNTS["regen"] )
end

function CKingController:UpgradeArmour( hPlayer, hKing )
	-- print("CKingController:UpgradeArmour")
	hKing:SetPhysicalArmorBaseValue( hKing:GetPhysicalArmorBaseValue() + CKingController.UPGRADE_AMOUNTS["armour"] )
end

function CKingController:UpgradeAttack( hPlayer, hKing )
	-- print("CKingController:UpgradeAttack")
	hKing:SetBaseDamageMax( hKing:GetBaseDamageMax() + CKingController.UPGRADE_AMOUNTS["attack"] )
	hKing:SetBaseDamageMin( hKing:GetBaseDamageMin() + CKingController.UPGRADE_AMOUNTS["attack"] )
end
