
if CMineController == nil then
	CMineController = class({})
end

function CLegionDefence:SetupMineController()
	self.mine_controller = CMineController()
	self.mine_controller:Setup()
end

function CLegionDefence:GetMineController()
	return self.mine_controller
end

---------------------------------------
-- Mine Controller
---------------------------------------
CMineController.CURRENCY = CURRENCY_GEMS
CMineController.DEFAULT = {
	miners = 1,
	income_per_miner = 20,
}

CMineController.UPGRADE_MINERS = 1
CMineController.UPGRADE_MINING_SPEED = 5

CMineController.MAXIMUM_MINERS = 10
CMineController.MAXIMUM_MINING_SPEED = 200

function CMineController:Setup()

	self.mines = {}

	-- Game events
	ListenToGameEvent("legion_player_assigned_lane", Dynamic_Wrap(CMineController, "OnPlayerAssignedLane"), self)

end

function CMineController:OnPlayerAssignedLane( data )

	local playerId = data["lPlayer"]

	-- Give player default mines
	self.mines[playerId] = table.copy( CMineController.DEFAULT )
	self:UpdatePlayerIncome( playerId )

end

function CMineController:OnPurchasedMinerUpgrade( iPlayerId, iUpgradeLevel, iLevelsAdded )
	self.mines[iPlayerId].miners = CMineController.DEFAULT.miners + ((iUpgradeLevel - 1) * CMineController.UPGRADE_MINERS)
	self:UpdatePlayerIncome( iPlayerId )
end

function CMineController:OnPurchasedMiningSpeedUpgrade( iPlayerId, iUpgradeLevel, iLevelsAdded )
	self.mines[iPlayerId].income_per_miner = CMineController.DEFAULT.income_per_miner + ((iUpgradeLevel - 1) * CMineController.UPGRADE_MINING_SPEED)
	self:UpdatePlayerIncome( iPlayerId )
end

function CMineController:UpdatePlayerIncome( iPlayerId )

	-- Calculate income
	local income = self.mines[iPlayerId].income_per_miner
	income = income * self.mines[iPlayerId].miners

	-- Set income
	local currencyController = GameRules.LegionDefence:GetCurrencyController()
	currencyController:SetCurrencyIncome( CMineController.CURRENCY, iPlayerId, income )

end
