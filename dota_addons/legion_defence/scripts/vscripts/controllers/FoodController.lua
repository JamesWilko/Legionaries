
if CFoodController == nil then
	CFoodController = class({})
end

function CLegionDefence:SetupFoodController()
	self.food_controller = CFoodController()
	self.food_controller:Setup()
end

function CLegionDefence:GetFoodController()
	return self.food_controller
end

---------------------------------------
-- Food Controller
---------------------------------------
CFoodController.DEFAULT_FOOD = 20
CFoodController.FOOD_PER_LEVEL = 5
CFoodController.MAXIMUM_FOOD = 100
CFoodController.CURRENCY = CURRENCY_FOOD

function CFoodController:Setup()

	-- Game events
	ListenToGameEvent("legion_player_assigned_lane", Dynamic_Wrap(CFoodController, "OnPlayerAssignedLane"), self)

end

function CFoodController:OnPlayerAssignedLane( data )

	local playerId = data["lPlayer"]
	local currencyController = GameRules.LegionDefence:GetCurrencyController()
	currencyController:SetCurrencyLimit( CFoodController.CURRENCY, playerId, CFoodController.DEFAULT_FOOD )
	currencyController:ModifyCurrency( CFoodController.CURRENCY, playerId, CFoodController.DEFAULT_FOOD, true )

end

function CFoodController:OnPurchasedFoodUpgrade( iPlayerId, iUpgradeLevel, iLevelsAdded )

	local currencyController = GameRules.LegionDefence:GetCurrencyController()

	-- Set food limit to correct limit for level
	local food_limit = CFoodController.DEFAULT_FOOD + CFoodController.FOOD_PER_LEVEL * (iUpgradeLevel - 1)
	currencyController:SetCurrencyLimit( CFoodController.CURRENCY, iPlayerId, food_limit )

	-- Add extra food as required per level
	local food_added = CFoodController.FOOD_PER_LEVEL * iLevelsAdded
	currencyController:ModifyCurrency( CFoodController.CURRENCY, iPlayerId, food_added, true )

end
