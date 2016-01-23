
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

-- Given to the first person to clear a wave
CStatsController.FIRST_CLEAR_BONUS = 10
CStatsController.FIRST_CLEAR_BONUS_CURRENCY = CURRENCY_GOLD

function CStatsController:Setup()

	self._first_cleared_player = nil

	ListenToGameEvent("legion_wave_complete", Dynamic_Wrap(CStatsController, "HandleOnWaveComplete"), self)
	ListenToGameEvent("legion_lane_complete", Dynamic_Wrap(CStatsController, "HandleOnLaneComplete"), self)
	ListenToGameEvent("legion_lane_leaked", Dynamic_Wrap(CStatsController, "HandleOnLaneLeaked"), self)

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

		if player == self._first_cleared_player then
			GameRules.LegionDefence:GetCurrencyController():ModifyCurrency( CStatsController.FIRST_CLEAR_BONUS_CURRENCY, player, CStatsController.FIRST_CLEAR_BONUS )
			SendCustomChatMessage( "legion_first_clear_income", { arg_number = CStatsController.FIRST_CLEAR_BONUS } )
		end

	end

	SendCustomChatMessage( "legion_basic_income", { arg_number = CStatsController.BASIC_INCOME } )

	-- Reset first cleared player
	self._first_cleared_player = nil

end

function CStatsController:HandleOnLaneComplete( event )

	local lane = event["lLane"]
	local player = event["lPlayer"]

	local wave_controller = GameRules.LegionDefence:GetWaveController()
	if not wave_controller:DidPlayerLeakWave( player ) then

		if self._first_cleared_player == nil then
			self._first_cleared_player = player
			SendCustomChatMessage( "legion_player_cleared_wave_first", { player = player } )
		else
			SendCustomChatMessage( "legion_player_cleared_wave", { player = player } )
		end

	end

end

function CStatsController:HandleOnLaneLeaked( event )

	local lane = event["lLane"]
	local player = event["lPlayer"]
	SendCustomChatMessage( "legion_player_leaked_wave", { player = player } )

end
