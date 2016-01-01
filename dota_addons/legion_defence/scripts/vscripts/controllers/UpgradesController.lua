
if CUpgradeController == nil then
	CUpgradeController = class({})
end

function CLegionDefence:SetupUpgradeController()
	self.upgrade_controller = CUpgradeController()
	self.upgrade_controller:Setup()
end

function CLegionDefence:GetUpgradeController()
	return self.upgrade_controller
end

---------------------------------------
-- Upgrades Controller
---------------------------------------
CUpgradeController.NET_TABLE = "Upgrades"

CUpgradeController.UPGRADE_FOOD_CAP = "legion_upgrade_food_capacity"
CUpgradeController.UPGRADE_MINERS = "legion_upgrade_num_miners"
CUpgradeController.UPGRADE_MINER_SPEED = "legion_upgrade_miner_speed"

CUpgradeController.UPGRADES =
{
	[CUpgradeController.UPGRADE_FOOD_CAP] =
	{
		cost = {
			[1] = {
				currency = CURRENCY_GOLD,
				amount = 24,
			},
			[2] = {
				currency = CURRENCY_GEMS,
				amount = 80,
			}
		},
		default = 1,
		max_level = ((CFoodController.MAXIMUM_FOOD - CFoodController.DEFAULT_FOOD) / CFoodController.FOOD_PER_LEVEL) + 1,
		display_image = "item_tango",
		value = CFoodController.FOOD_PER_LEVEL,
		func = function( playerId, upgradeLevel, levelsAdded )
			GameRules.LegionDefence:GetFoodController():OnPurchasedFoodUpgrade( playerId, upgradeLevel, levelsAdded )
		end
	},
	[CUpgradeController.UPGRADE_MINERS] =
	{
		cost = {
			[1] = {
				currency = CURRENCY_GOLD,
				amount = 50,
			}
		},
		default = 1,
		max_level = ((CMineController.MAXIMUM_MINERS - CMineController.DEFAULT.miners) / CMineController.UPGRADE_MINERS) + 1,
		display_image = "item_boots",
		value = CMineController.UPGRADE_MINERS,
		func = function( playerId, upgradeLevel, levelsAdded )
			GameRules.LegionDefence:GetMineController():OnPurchasedMinerUpgrade( playerId, upgradeLevel, levelsAdded )
		end
	},
	[CUpgradeController.UPGRADE_MINER_SPEED] =
	{
		cost = {
			[1] = {
				currency = CURRENCY_GEMS,
				amount = 80,
			}
		},
		default = 1,
		max_level = ((CMineController.MAXIMUM_MINING_SPEED - CMineController.DEFAULT.income_per_miner) / CMineController.UPGRADE_MINING_SPEED) + 1,
		display_image = "item_mithril_hammer",
		value = CMineController.UPGRADE_MINING_SPEED,
		func = function( playerId, upgradeLevel, levelsAdded )
			GameRules.LegionDefence:GetMineController():OnPurchasedMiningSpeedUpgrade( playerId, upgradeLevel, levelsAdded )
		end
	}
}

function CUpgradeController:Setup()

	-- Player upgrade status
	self._upgrades = {}

	-- Send upgrades info
	CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, "upgrades", CUpgradeController.UPGRADES )

	-- Events
	ListenToGameEvent("legion_player_assigned_lane", Dynamic_Wrap(CUpgradeController, "OnPlayerAssignedLane"), self)
	CustomGameEventManager:RegisterListener( "legion_purchase_upgrade", Dynamic_Wrap(CUpgradeController, "HandleOnAttemptUpgradePurchase") )

end

function CUpgradeController:GetUpgradeLevel( sUpgradeId, iPlayerId )
	if CUpgradeController.UPGRADES[sUpgradeId] and self._upgrades[sUpgradeId] then
		return self._upgrades[sUpgradeId][iPlayerId] or 0
	end
	return -1
end

function CUpgradeController:SetUpgradeLevel( sUpgradeId, iPlayerId, iUpgradeLevel )

	-- Ensure upgrade exists
	if CUpgradeController.UPGRADES[sUpgradeId] then

		-- Set upgrade level
		self._upgrades[sUpgradeId] = self._upgrades[sUpgradeId] or {}
		self._upgrades[sUpgradeId][iPlayerId] = self._upgrades[sUpgradeId][iPlayerId] or CUpgradeController.UPGRADES[sUpgradeId].default

		local diff = iUpgradeLevel - self._upgrades[sUpgradeId][iPlayerId]
		self._upgrades[sUpgradeId][iPlayerId] = iUpgradeLevel

		-- Call update func
		CUpgradeController.UPGRADES[sUpgradeId].func( iPlayerId, iUpgradeLevel, diff )

		-- Update nettable for upgrade
		CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, sUpgradeId, self._upgrades[sUpgradeId] )

	end

end

function CUpgradeController:OnPlayerAssignedLane( data )

	-- Get data
	local iPlayerId = data["lPlayer"]

	-- Assign default values for player upgrades
	for upgradeId, upgrade_data in pairs( CUpgradeController.UPGRADES ) do

		-- Create upgrade tables
		self._upgrades[upgradeId] = self._upgrades[upgradeId] or {}
		self._upgrades[upgradeId][iPlayerId] = self._upgrades[upgradeId][iPlayerId] or CUpgradeController.UPGRADES[upgradeId].default

		-- Update net tables
		CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, upgradeId, self._upgrades[upgradeId] )

	end

end

function CUpgradeController.HandleOnAttemptUpgradePurchase( iPlayerId_Wrong, eventArgs )

	-- Get upgrade data
	local self = GameRules.LegionDefence:GetUpgradeController()
	local iPlayerId = eventArgs["PlayerID"]
	local upgradeId = eventArgs["sUpgradeId"]
	local upgrade = CUpgradeController.UPGRADES[upgradeId]
	if upgrade then

		local currency_controller = GameRules.LegionDefence:GetCurrencyController()

		-- Check upgrade for player isn't at max level
		self._upgrades[upgradeId] = self._upgrades[upgradeId] or {}
		self._upgrades[upgradeId][iPlayerId] = self._upgrades[upgradeId][iPlayerId] or CUpgradeController.UPGRADES[upgradeId].default
		local playerUpgradeLevel = self._upgrades[upgradeId][iPlayerId]
		if playerUpgradeLevel >= upgrade.max_level then
			return false, "at_max_level"
		end

		-- Check player can afford upgrade
		local canAfford = true
		for k, cost_data in pairs( upgrade.cost ) do
			if not currency_controller:CanAfford( cost_data.currency, iPlayerId, cost_data.amount, true ) then
				return false, "can_not_afford"
			end
		end

		-- Deduct purchase cost
		for k, cost_data in pairs( upgrade.cost ) do
			currency_controller:ModifyCurrency( cost_data.currency, iPlayerId, -cost_data.amount )
		end

		-- Increase upgrade level
		local new_level = self._upgrades[upgradeId][iPlayerId] + 1
		self._upgrades[upgradeId][iPlayerId] = new_level

		-- Update nettable for upgrade
		CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, upgradeId, self._upgrades[upgradeId] )

		-- Run upgrade function
		upgrade.func( iPlayerId, new_level, 1 )

	end

end
