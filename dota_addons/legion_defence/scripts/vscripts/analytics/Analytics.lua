
-- 
-- Dota 2 analytics library for Legionaries
-- 

require("analytics/GameAnalytics")

if CAnalytics == nil then
	CAnalytics = class({})
end

function CLegionDefence:SetupAnalytics()
	self._analytics = CAnalytics()
	self._analytics:Setup()
	_G.Analytics = self._analytics
end

function CLegionDefence:GetAnalytics()
	return self._analytics
end

function CAnalytics:Setup()

end

function CAnalytics:Initialize()
	GameAnalytics:Initialize()
end

function CAnalytics:RecordPlayerPickedHero( playerId, heroId )
	local event_id = string.format( "Gameplay:PickHero:%s", heroId )
	local data = { ["value"] = GameRules.LegionDefence:GetWaveController()._current_wave }
	GameAnalytics:SendDesignEvent( event_id, data )
end

function CAnalytics:RecordPlayerRepickedHero( playerId, heroId )
	local event_id = string.format( "Gameplay:RepickHero:%s", heroId )
	local data = { ["value"] = GameRules.LegionDefence:GetWaveController()._current_wave }
	GameAnalytics:SendDesignEvent( event_id, data )
end

function CAnalytics:RecordWaveStarted()

end

function CAnalytics:RecordWaveCompleted()

end

function CAnalytics:RecordWaveLeaked()

end
