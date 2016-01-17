
if CStatsController == nil then
	CStatsController = class({})
end

function CLegionDefence:SetupStatsController()
	self.stats_controller = CStatsController()
	self.stats_controller:Setup()
	if GameRules:GetGameModeEntity()._developer then
		self.stats_controller:SetupDebug()
	end
end

function CLegionDefence:GetStatsController()
	return self.stats_controller
end

----------------------------
-- Stats Controller
----------------------------

-- Basic income is given to all players at the end of a wave
CStatsController.BASIC_INCOME = 20
CStatsController.BASIC_INCOME_CURRENCY = CURRENCY_GOLD

function CStatsController:Setup()

	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CStatsController, "HandleOnWaveComplete"), self)

end

function CStatsController:SetupDebug()

end

function CStatsController:HandleOnWaveComplete()

	local lane_controller = GameRules.LegionDefence:GetLaneController()
	local lanes = lane_controller:GetAllOccupiedLanes()

	-- Give all players basic income at the end of a wave
	for k, v in pairs( lanes ) do
		local player = v.player
		GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CStatsController.BASIC_INCOME_CURRENCY, player, CStatsController.BASIC_INCOME )
		print("Giving player basic income: " .. tostring(CStatsController.BASIC_INCOME))
	end

end
