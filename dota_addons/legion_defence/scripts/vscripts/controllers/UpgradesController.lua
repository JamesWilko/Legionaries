
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
		time = 5,
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
		time = 30,
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
		time = 10,
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
	self._pending_upgrades = {}

	-- Send upgrades info
	CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, "upgrades", CUpgradeController.UPGRADES )

	-- Think entity
	self._think_time = 0.2
	self._think_ent = IsValidEntity(self._think_ent) and self._think_ent or Entities:CreateByClassname("info_target")
	self._think_ent:SetThink("OnThink", self, "UpgradeControllerThink", self._think_time)

	-- Events
	ListenToGameEvent("legion_player_assigned_lane", Dynamic_Wrap(CUpgradeController, "OnPlayerAssignedLane"), self)
	CustomGameEventManager:RegisterListener( "legion_purchase_upgrade", Dynamic_Wrap(CUpgradeController, "HandleOnAttemptUpgradePurchase") )
	CustomGameEventManager:RegisterListener( "legion_cancel_upgrade", Dynamic_Wrap(CUpgradeController, "HandleOnAttemptUpgradeCancel") )

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

		-- Verify upgrade data
		self._upgrades[upgradeId] = self._upgrades[upgradeId] or {}
		self._upgrades[upgradeId][iPlayerId] = self._upgrades[upgradeId][iPlayerId] or CUpgradeController.UPGRADES[upgradeId].default

		-- Check upgrade for player isn't at max level
		local playerUpgradeLevel = self._upgrades[upgradeId][iPlayerId]
		playerUpgradeLevel = playerUpgradeLevel + self:GetPendingUpgrades( iPlayerId, upgradeId )
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

		-- Queue upgrade
		self:QueuePendingUpgrade( iPlayerId, upgradeId )

	end

end

function CUpgradeController.HandleOnAttemptUpgradeCancel( iPlayerId_Wrong, eventArgs )

	local self = GameRules.LegionDefence:GetUpgradeController()
	local iPlayerId = eventArgs["PlayerID"]
	local upgradeId = eventArgs["sUpgradeId"]
	local upgrade = CUpgradeController.UPGRADES[upgradeId]
	if upgrade and self:IsUpgradePending( iPlayerId, upgradeId ) then
		self:DequeuePlayerUpgrade( iPlayerId, upgradeId )
	end

end

function CUpgradeController:PlayerUpgradeCompleted( iPlayerId, upgradeId )

	print(string.format("Player %i upgrade %s complete", iPlayerId, upgradeId))

	-- Get upgrade data
	local upgrade = CUpgradeController.UPGRADES[upgradeId]
	if upgrade then

		local currency_controller = GameRules.LegionDefence:GetCurrencyController()

		-- Verify upgrade data
		self._upgrades[upgradeId] = self._upgrades[upgradeId] or {}
		self._upgrades[upgradeId][iPlayerId] = self._upgrades[upgradeId][iPlayerId] or CUpgradeController.UPGRADES[upgradeId].default

		-- Check upgrade for player isn't at max level
		local playerUpgradeLevel = self._upgrades[upgradeId][iPlayerId]
		if playerUpgradeLevel >= upgrade.max_level then
			return false, "at_max_level"
		end

		-- Increase upgrade level
		local new_level = self._upgrades[upgradeId][iPlayerId] + 1
		if new_level > upgrade.max_level then
			new_level = upgrade.max_level
		end
		self._upgrades[upgradeId][iPlayerId] = new_level

		-- Update nettable for upgrade
		CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, upgradeId, self._upgrades[upgradeId] )

		-- Run upgrade function
		upgrade.func( iPlayerId, new_level, 1 )

	end

end

function CUpgradeController:QueuePendingUpgrade( iPlayerId, upgradeId )
	
	local upgrade = CUpgradeController.UPGRADES[upgradeId]
	if upgrade then

		-- Verify data
		self._pending_upgrades[upgradeId] = self._pending_upgrades[upgradeId] or {}
		self._pending_upgrades[upgradeId][iPlayerId] = self._pending_upgrades[upgradeId][iPlayerId] or {}

		-- Get upgrade data		
		local player_data = self._pending_upgrades[upgradeId][iPlayerId]
		local game_time = GameRules:GetDOTATime(false, false)
		player_data.queued = player_data.queued or 0

		-- Queue upgrade
		if player_data.queued == 0 then
			player_data.start_time = game_time
			player_data.finish_time = game_time + upgrade.time
		end
		player_data.queued = player_data.queued + 1
		player_data.is_upgrading = true

		print(string.format("Player %i queued upgrade %s", iPlayerId, upgradeId))

		-- Send pending upgrades to players
		CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, "pending_" .. upgradeId, self._pending_upgrades[upgradeId] )

	end

end 

function CUpgradeController:DequeuePlayerUpgrade( iPlayerId, upgradeId, bWasCancelled )

	if bWasCancelled == nil then
		bWasCancelled = true
	end

	local upgrade_data = CUpgradeController.UPGRADES[upgradeId]
	local upgrade = self._pending_upgrades[upgradeId]
	if upgrade_data and upgrade then
		local player_data = upgrade[iPlayerId]
		if player_data then

			-- Dequeue upgrade
			player_data.queued = player_data.queued - 1

			if player_data.queued > 0 then

				-- Start next queued upgrade
				local game_time = GameRules:GetDOTATime(false, false)
				if not bWasCancelled then
					player_data.start_time = game_time
					player_data.finish_time = game_time + upgrade_data.time
				end
				player_data.is_upgrading = true

			else

				-- No more upgrades
				player_data.start_time = 0
				player_data.finish_time = math.huge
				player_data.is_upgrading = false

			end

			-- Upgrade was cancelled, refund player
			if bWasCancelled then
				print(string.format("Player %i cancelled upgrade %s", iPlayerId, upgradeId))
				local currency_controller = GameRules.LegionDefence:GetCurrencyController()
				for k, cost_data in pairs( upgrade_data.cost ) do
					currency_controller:ModifyCurrency( cost_data.currency, iPlayerId, cost_data.amount )
				end
			end

			-- Update nettable
			CustomNetTables:SetTableValue( CUpgradeController.NET_TABLE, "pending_" .. upgradeId, self._pending_upgrades[upgradeId] )

		end
	end

end

function CUpgradeController:IsUpgradePending( iPlayerId, upgradeId )
	local upgrade = self._pending_upgrades[upgradeId]
	if upgrade then
		local player_data = upgrade[iPlayerId]
		if player_data then
			return player_data.is_upgrading
		end
	end
	return false
end

function CUpgradeController:GetPendingUpgrades( iPlayerId, upgradeId )
	local upgrade = self._pending_upgrades[upgradeId]
	if upgrade then
		local player_data = upgrade[iPlayerId]
		if player_data then
			return player_data.queued
		end
	end
	return 0
end

function CUpgradeController:OnThink()

	local game_time = GameRules:GetDOTATime(false, false)

	for upgrade_id, players in pairs(self._pending_upgrades) do
		for player_id, data in pairs(players) do

			-- Upgrade has completed, run upgrade
			if data.is_upgrading and game_time >= data.finish_time then
				self:DequeuePlayerUpgrade( player_id, upgrade_id, false )
				self:PlayerUpgradeCompleted( player_id, upgrade_id )
			end

		end
	end

	return self._think_time

end
